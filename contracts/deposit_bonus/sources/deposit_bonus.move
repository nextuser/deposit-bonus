
/// Module: deposit_bonus
#[allow(unused_variable,unused_use)]

module deposit_bonus::deposit_bonus;
use std::hash;
use sui::random::Random;
use sui::bcs;
use sui::address;
use sui::balance::{Self,Balance};
use sui::coin::{Self,Coin};
use sui::table::{Self,Table};
use sui::clock::{Self,Clock};
use sui::event::emit;
use sui::sui::SUI  ;
use deposit_bonus::err_consts;
use sui_system::staking_pool::{StakedSui, Self};
use sui_system::sui_system::{Self,SuiSystemState};
use deposit_bonus::range::Range;
use sui::linked_table::{Self,LinkedTable};


public struct DepositEvent has copy,drop{
    user : address,
    share_amount : u64,
    amount : u64,
    update_time_ms : u64,
}

public struct UserShare  has store{
    id : address,
    amount : u64,
    update_time_ms: u64,
}

public struct Share has copy,drop{
    id : address,
    amount : u64,
}

public struct AllocateEvent has copy,drop{
    users : vector<Share>,
    total_amount : u64,
}

public struct Storage has key,store{
    id : UID,
    user_shares : Table<address,UserShare>,
    total_shares : u64,
    total_staked : u64,
    staked_suis : vector<StakedSui>,
    left_balance : Balance<SUI>,
    bonus_percent : u8,
    seed : u256,
   
}



public struct AdminCap has key { id : UID}

//todo ,no use in v1.0
public struct Card has key,store{
    id : UID,
}

fun add_staked_sui(storage : &mut Storage , new_staked : StakedSui){
    let len = storage.staked_suis.length();
    let mut i = 0;
    storage.total_staked = storage.total_staked +  new_staked.amount();
    let new_epoch = staking_pool::stake_activation_epoch(&new_staked);
    while( i < len){
        let s = vector::borrow_mut(&mut storage.staked_suis,i);
        let epoch = staking_pool::stake_activation_epoch(s);
        if(epoch == new_epoch){
            staking_pool::join_staked_sui(s,new_staked);
            return
        };
        i = i + 1;
    };
    vector::push_back(&mut storage.staked_suis, new_staked);
}
use std::u256;
fun new_storage(ctx : &mut TxContext) : Storage{
    let id = object::new(ctx);
    let seed = id.to_address().to_u256();
    Storage{
        id : id,
        user_shares : table::new<address,UserShare>(ctx),
        total_shares : 0,
        total_staked : 0,
        staked_suis : vector[],
        left_balance : balance::zero<SUI>(),
        bonus_percent : 50 ,
        seed : seed,
        
    }
}
fun init(ctx : &mut TxContext){
    let storage =  new_storage(ctx);

    transfer::share_object(storage);

    let admin_cap = AdminCap{ id : object::new(ctx)};
    transfer::transfer(admin_cap,ctx.sender());
}

fun change_bonus_percent(_ :&AdminCap,storage : &mut Storage, percent : u8){
    assert!(percent <= 100 , err_consts::percent_out_of_range!());
    storage.bonus_percent = percent;
}

fun money_to_share(storage :& Storage, money : u64) : u64{
    let total_sui = storage.total_staked as u128;
    let total_share = (storage.total_shares as u128);
    let share_amount = (total_share * (money as u128)  / total_sui) as u64;
    share_amount
}



fun share_to_money(storage : & Storage , share : u64) : u64{
    let total_sui = storage.total_staked as u128;
    let total_shares = storage.total_shares as u128;
    (total_sui * (share as u128) / total_shares) as u64
}

fun add_money_to_share(storage :&mut Storage , amount : u64,time_ms:u64, sender : address) : u64{
    let share_amount = money_to_share(storage, amount);
    if(table::contains(&storage.user_shares, sender)){
        let share = table::borrow_mut(&mut storage.user_shares,sender);
        share.amount = share.amount + share_amount;
        share.update_time_ms = time_ms;
    }
    else{
        let share = UserShare{
            id :sender,
            amount : share_amount,            
            update_time_ms : time_ms,
        };
        table::add(&mut storage.user_shares,sender, share);
    };
    storage.total_shares = storage.total_shares + share_amount;
    share_amount
}

entry fun deposit(clock: &Clock,storage: & mut Storage,
                  wrapper: &mut SuiSystemState,validator_address: address,
                  coin: Coin<SUI>, ctx: &mut TxContext) {
    let update_time_ms = clock::timestamp_ms(clock);
    let value = coin::value(&coin);
   // balance::join(&mut storage.balances, coin::into_balance(coin));
    deposit_to_stake(storage, wrapper, coin, validator_address,ctx);
   
    let sender = ctx.sender();
    let share = add_money_to_share(storage, value, update_time_ms, sender);

    emit(DepositEvent{
        user : sender,
        share_amount : share,
        amount : value,
        update_time_ms : update_time_ms,        
    });
}


fun reduce_share(storage : &mut Storage, withdraw_share : u64, sender : address)
{
    let share = table::borrow_mut(&mut storage.user_shares, sender);  
    share.amount = share.amount - withdraw_share;
    storage.total_shares = storage.total_shares - withdraw_share;
    if(share.amount == 0){
        let s = table::remove(&mut storage.user_shares,sender);
        let UserShare{ id : _,amount :_,update_time_ms: _  } = s;
    };
}

public  fun withdraw(clock: &Clock,storage: & mut Storage,wrapper: &mut SuiSystemState,
                    amount : u64,ctx : &mut TxContext) : Balance<SUI>{
    let sender = ctx.sender();
    assert!( table::contains(&storage.user_shares,sender),err_consts::account_not_exists!() );
    //check share
    let share = table::borrow(&storage.user_shares, sender);
    let user_money = share_to_money(storage, share.amount);
    assert!(user_money >= amount ,err_consts::share_not_enough!() );
    
    // take money from dex

    let balance = withdraw_from_stake(storage, wrapper, amount, ctx);

    let withdraw_share = money_to_share(storage, amount);
    reduce_share(storage,withdraw_share,sender);
    balance
}

fun deposit_to_stake(storage :&mut Storage,
        wrapper: &mut SuiSystemState,
        coin: Coin<SUI>,
        validator_address: address,
        ctx : &mut TxContext)
{
    let s = sui_system::request_add_stake_non_entry(wrapper,coin,
                                                    validator_address,ctx);
    add_staked_sui(storage, s) ;   

}

fun collect_mini(storage :&mut Storage, balance : Balance<SUI> ){
    if(balance.value() == 0){
        balance::destroy_zero(balance);
        return
    };
    balance::join(&mut storage.left_balance,balance);
}

fun split_exact_balance(storage :&mut Storage, mut merge_balance :Balance<SUI>,amount : u64) : Balance<SUI>
{
        
        if(amount == merge_balance.value()){
            return merge_balance
        };

        let ret = merge_balance.split(amount);
        collect_mini(storage, merge_balance);
        ret
}

/**
when one use withdraw his share
*/
fun withdraw_from_stake(storage :&mut Storage, 
                        wrapper: &mut SuiSystemState,
                        amount : u64,
                        ctx: &mut TxContext) :Balance<SUI>{

    let count = vector::length(&storage.staked_suis);
    let mut i = 0;
    let mut merge_balance = balance::zero<SUI>();
    while(i < count){
        let mut staked  = vector::pop_back(&mut storage.staked_suis);

        let need = amount - merge_balance.value();
        let curr_amount = staking_pool::staked_sui_amount(&staked) ;
        if( curr_amount > need  ){
            let mut split = staking_pool::split(&mut staked,need, ctx);
            let mut balance = sui_system::request_withdraw_stake_non_entry(wrapper,split,ctx);
            assert!(balance.value() >= need, err_consts::balance_less_than_staked!());
            merge_balance.join(balance);
            vector::push_back(&mut storage.staked_suis,staked);
            assert!(merge_balance.value() >=  amount);
            return split_exact_balance(storage,merge_balance , amount)
        }
        else{
              let mut balance = sui_system::request_withdraw_stake_non_entry(wrapper,staked,ctx); 
              merge_balance.join(balance);
        };
        

        i = i + 1;
    };
    assert!(merge_balance.value() >= amount, err_consts::withdraw_fail!());
    return  split_exact_balance(storage,merge_balance , amount)
}


/**
take the reward  after a period
*/
fun withdraw_all_from_stake(storage :&mut Storage, 
                        wrapper: &mut SuiSystemState,
                        ctx: &mut TxContext) {

    let count = vector::length(&storage.staked_suis);
    let mut balance = balance::zero<SUI>();
    while(!vector::is_empty<StakedSui>(&storage.staked_suis)){
        let staked  = vector::pop_back(&mut storage.staked_suis);
        let b = sui_system::request_withdraw_stake_non_entry(wrapper,staked,ctx); 
        balance.join(b);
    };
    storage.left_balance.join(balance);
}

fun allocate_bonus(storage : &mut Storage,mut b : Balance<SUI>, shares : vector<Share>,ctx :&mut TxContext){
    let mut total = 0;
    let mut i = 0;
    let balance_value = balance::value(&b);
    let len = shares.length();
    let mut allocate_event = AllocateEvent {
           users : vector[],
           total_amount : balance_value, 
    };

    while(i < len){
        let share = vector::borrow(&shares,i);
        total = total + share.amount;
        i = i + 1;
    };
    i = 0;
    while(i < len ){
        let share = vector::borrow(&shares,i);
        let share_value = balance_value * share.amount / total;
        let share_balance : Balance<SUI> = balance::split<SUI>(&mut b, share_value);
        let coin = coin::from_balance(share_balance, ctx);
        vector::push_back(&mut allocate_event.users, Share{
            id : share.id,
            amount :  coin.value(),
        });
        transfer::public_transfer(coin, share.id);
    };

    collect_mini(storage, b);

    sui::event::emit(allocate_event);
}

fun find_bonus_user(storage :& Storage) : vector<Share> {
    let v=  vector[];

    v
}

fun bonus_calc(storage :&mut Storage,ctx: &mut TxContext){
    let curr_value = storage.left_balance.value();
    let total_staked = storage.total_staked;
    assert!(curr_value > total_staked);
    let percent = storage.bonus_percent as u64;
    let bonus_amount = (curr_value - total_staked) * percent / 100;
    let bonus = balance::split(&mut storage.left_balance, bonus_amount);
    let shares = find_bonus_user(storage);
    allocate_bonus(storage,bonus,shares,ctx);
}



fun create_random_point(storage : &mut Storage,random :&Random , ctx : &mut TxContext) : u256{
    let mut g = random.new_generator(ctx);
    let mut full_proof: vector<u8> = vector::empty<u8>();
    vector::append<u8>(&mut full_proof, bcs::to_bytes(&storage.seed));
    vector::append<u8>(&mut full_proof, bcs::to_bytes(&storage.left_balance.value()));
    let chall_bytes =  bcs::to_bytes(&g.generate_u256());
    let hash: vector<u8> = hash::sha3_256(full_proof);
    assert!(hash.length() == 32);
    let seed  = address::from_bytes(hash).to_u256();
    storage.seed = seed;
    seed
}



fun get_user_range(share : &UserShare ): vector<Range>{
    let point = share.id.to_u256();
    deposit_bonus::range::get_ranges(point, share.amount as u256)
}

fun get_percent_range( point : u256,_percent:u8) : vector<Range>{
    let percent = _percent as u256;
    let len_unit = u256::max_value!() / 100;
    let len = len_unit * percent;
    deposit_bonus::range::get_ranges(point,len)
}

fun get_hit_range(storage : &mut Storage,random :&Random , ctx : &mut TxContext) : vector<Range>
{
    let random_point = create_random_point(storage, random, ctx);
    let hit_ranges = get_percent_range(random_point, storage.bonus_percent );
    hit_ranges

}


fun get_hit_users(storage : &mut Storage,random :&Random , ctx : &mut TxContext) : LinkedTable<address,u256>
{
    let hit_ranges = get_hit_range(storage, random, ctx);
    let user_shares = linked_table::new<address,u256>(ctx);
    user_shares
    
    //todo ,not finished
}

entry fun entry_withdraw(clock: &Clock,storage: & mut Storage,wrapper: &mut SuiSystemState,
                        amount : u64,ctx : &mut TxContext){
    let balance = withdraw(clock, storage, wrapper,
                            amount, ctx);
    let coin = coin::from_balance<SUI>(balance,ctx);
    transfer::public_transfer(coin, ctx.sender());
}

public fun get_share_by_user(storage: & Storage,user : address) : u64{
    
    let share = table::borrow(&storage.user_shares,user);
    share.amount
}

public fun get_share(storage: & Storage,ctx : &mut TxContext) : u64{
    return get_share_by_user(storage,ctx.sender())
}



