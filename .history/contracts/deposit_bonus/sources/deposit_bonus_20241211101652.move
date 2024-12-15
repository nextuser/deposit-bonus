
/// Module: deposit_bonus
#[allow(unused_variable,unused_use)]

module deposit_bonus::deposit_bonus;
use std::hash;
use std::u256;
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
use deposit_bonus::bonus;
use sui::linked_table::{Self,LinkedTable};


public struct DepositEvent has copy,drop{
    user : address,
    share_amount : u64,
    amount : u64,
    update_time_ms : u64,
}

public struct UserShare  has store{
    id : address,
    original_money : u64,//
    share_amount : u64,//share 份额
    update_time_ms: u64,
    bonus : u64,
}

fun destroy_user_share(share : UserShare){
    let UserShare{id:_,original_money:_,share_amount :_,update_time_ms :_, bonus : _} = share;
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
    user_shares : LinkedTable<address,UserShare>,
    total_shares : u64,
    total_staked : u64,
    staked_suis : vector<StakedSui>,
    left_balance : Balance<SUI>,
    bonus_balance : Balance<SUI>,
    bonus_percent : u32,
    fee_percent : u32,
    seed : u256,
}


public struct BonusHistory has key{
    id : UID,
    history : vector<address>,
    //user address => bonus record addr
    //user_recent_bonus : Table<address, address>,
}
public struct UserInfo has copy,drop{
    id : address,
    orignal_amount : u64,
    reward : u64,
    bonus  : u64,
}



const PERCENT_MAX:u32 = 10000; //100%
const FeeLimit : u32 = 1000; // 10%
const BonusLimit : u32 = 10000; // 100%  
public struct AdminCap has key { id : UID}
public struct OperatorCap has key{id : UID}

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

fun new_storage(ctx : &mut TxContext) : Storage{
    let id = object::new(ctx);
    let seed = id.to_address().to_u256();
    Storage{
        id : id,
        user_shares : linked_table::new<address,UserShare>(ctx),
        total_shares : 0,
        total_staked : 0,
        staked_suis : vector[],
        left_balance : balance::zero<SUI>(),
        bonus_balance :  balance::zero<SUI>(),
        bonus_percent : 5000 ,//50%
        fee_percent : 500, //base point , 5%
        seed : seed,
        
    }
}
fun init(ctx : &mut TxContext){
    let storage =  new_storage(ctx);

    transfer::share_object(storage);

    let admin_cap = AdminCap{ id : object::new(ctx)};

    transfer::transfer(admin_cap,ctx.sender());

    let operator_cap = OperatorCap{id : object::new(ctx)};
    transfer::transfer(operator_cap,ctx.sender());

    let h = BonusHistory{
        id : object::new(ctx),
        history : vector[]
    };
    transfer::share_object(h);
}

entry fun assign_operator(_ :&AdminCap , operator_cap : OperatorCap, to :address){
    transfer::transfer(operator_cap, to);
}

entry fun change_bonus_percent(_ :&AdminCap,storage : &mut Storage, percent : u32){
    assert!(percent <= BonusLimit , err_consts::percent_out_of_range!());
    storage.bonus_percent = percent;
}

entry fun change_fee_percent(_ :&AdminCap,storage : &mut Storage, percent : u32){
    assert!(percent <= FeeLimit, err_consts::fee_percent_out_of_range!());
    storage.fee_percent = percent;
}

fun money_to_share(storage :& Storage, money : u64) : u64{
    
    let total_sui = storage.total_staked as u128;
    assert!(total_sui != 0);
    let total_share = (storage.total_shares as u128);
    let share_amount = (total_share * (money as u128)  / total_sui) as u64;
    share_amount
}

fun share_to_money(storage : & Storage , share : u64) : u64{
    let total_sui = storage.total_staked as u128;
    let total_shares = storage.total_shares as u128;
    (total_sui * (share as u128) / total_shares) as u64
}

fun add_money_to_share(storage :&mut Storage , original_money : u64,time_ms:u64, sender : address) : u64{
    let share_amount = money_to_share(storage, original_money);
    if(linked_table::contains(&storage.user_shares, sender)){
        let user_share = linked_table::borrow_mut(&mut storage.user_shares,sender);
        user_share.share_amount = user_share.share_amount + share_amount;
        user_share.original_money = user_share.original_money + original_money;
        user_share.update_time_ms = time_ms;
    }
    else{
        let user_share =   UserShare{
            id :sender,
            original_money : original_money,
            share_amount : share_amount,            
            update_time_ms : time_ms,
            bonus : 0

        };
        linked_table::push_back(&mut storage.user_shares,sender, user_share);
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
    let user_share = linked_table::borrow_mut(&mut storage.user_shares, sender);  
    assert!(user_share.share_amount >= withdraw_share,err_consts::withdraw_share_not_enough!());
    user_share.share_amount = user_share.share_amount - withdraw_share;
    storage.total_shares = storage.total_shares - withdraw_share;
    //remove zero share
    if(user_share.share_amount == 0){
        let s = linked_table::remove(&mut storage.user_shares,sender);
        destroy_user_share(s);
    };
}

/**
one user  to withdraw his staked sui
*/
public  fun withdraw(clock: &Clock,storage: & mut Storage,wrapper: &mut SuiSystemState,
                    amount : u64,ctx : &mut TxContext) : Balance<SUI>{
    let sender = ctx.sender();
    assert!( linked_table::contains(&storage.user_shares,sender),err_consts::account_not_exists!() );
    //check share
    let user_share = linked_table::borrow(&storage.user_shares, sender);
    let user_money = share_to_money(storage, user_share.share_amount);
    assert!(user_money >= amount ,err_consts::share_not_enough!() );
    
    
    let withdraw_share = money_to_share(storage, amount);
    
    let balance = withdraw_from_stake(storage, wrapper, amount, ctx);
    
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

/**
before to call this function,  call withdraw_all_from_stake at first ,
*/
fun deposit_storage_balance(storage :&mut Storage,
        wrapper: &mut SuiSystemState,
        validator_address: address,
        ctx : &mut TxContext)
{
    let amount = balance::value(&storage.left_balance);
    let balance = balance::split(&mut storage.left_balance, amount );
    let coin = coin::from_balance(balance, ctx);
    let s = sui_system::request_add_stake_non_entry(wrapper,coin,
                                                    validator_address,ctx);
    
    storage.total_staked =  staking_pool::staked_sui_amount(&s);   
    //old staked_sui should be withdrawed
    assert!(vector::is_empty(&storage.staked_suis));
    storage.staked_suis.push_back(s);
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
when one user withdraw his share
*/
fun withdraw_from_stake(storage :&mut Storage, 
                        wrapper: &mut SuiSystemState,
                        amount : u64,
                        ctx: &mut TxContext) :Balance<SUI>{

    let count = vector::length(&storage.staked_suis);
    let mut merge_balance = balance::zero<SUI>();
    while(!vector::is_empty(&storage.staked_suis)){
        let mut staked  = vector::pop_back(&mut storage.staked_suis);

        let need = amount - merge_balance.value();
        let curr_amount = staking_pool::staked_sui_amount(&staked) ;
        if( curr_amount > need  ){
            let split = staking_pool::split(&mut staked,need, ctx);
            let balance = sui_system::request_withdraw_stake_non_entry(wrapper,split,ctx);
            assert!(balance.value() >= need, err_consts::balance_less_than_staked!());
            merge_balance.join(balance);
            vector::push_back(&mut storage.staked_suis,staked);
            assert!(merge_balance.value() >=  amount);
            storage.total_staked = storage.total_staked - need;
            return split_exact_balance(storage,merge_balance , amount)
        }
        else{
              let balance = sui_system::request_withdraw_stake_non_entry(wrapper,staked,ctx); 
              merge_balance.join(balance);
              storage.total_staked = storage.total_staked - curr_amount;
        };

    };
    assert!(merge_balance.value() >= amount, err_consts::withdraw_fail!());
    split_exact_balance(storage,merge_balance , amount)
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

fun allocate_bonus(storage : &mut Storage,
                    mut bonus : Balance<SUI>, 
                    shares : &LinkedTable<address,u256>,
                    time_ms : u64,
                    bonus_history :&mut BonusHistory,
                    ctx :&mut TxContext){
    let mut total = 0;
    let mut period = bonus::create_bonus_period(time_ms,ctx);
    let balance_value = balance::value(&bonus);
    storage.bonus_balance.join(bonus);
    
    let mut allocate_event = AllocateEvent {
           users : vector[],
           total_amount : balance_value, 
    };
    let mut node = linked_table::front(shares);
    while(! option::is_none(node)){
        let addr = * option::borrow(node);
        let amount = linked_table::borrow(shares,addr);
        total = total + *amount;
        node = linked_table::next(shares,addr);
    };

    
    
    node = linked_table::front(shares);
    while(!option::is_none(node)){
        let addr = * option::borrow(node);
        let amount = * linked_table::borrow(shares,addr);

        let gain = (balance_value as u256) * amount / total;
        //let gain_balance : Balance<SUI> = balance::split<SUI>(&mut bonus, gain as u64);
        //let coin = coin::from_balance(gain_balance, ctx);
        
        let user_share = linked_table::borrow_mut<address,UserShare>(&mut storage.user_shares,addr);
        let pay = (user_share.share_amount * balance_value )/ storage.total_shares;
        let record = bonus::create_bonus_record(addr ,  gain as u64,
                                                        pay , user_share.original_money) ;
        bonus::add_user_bonus(&mut period, record);
        user_share.bonus = gain;
        vector::push_back(&mut allocate_event.users, Share{
            id : addr,
            amount :  coin.value(),
        });
        ////transfer::public_transfer(coin, addr);
        
        node = linked_table::next(shares,addr);
    };
    bonus_history.history.push_back(object::id(&period).to_address());
    transfer::public_share_object(period);

    collect_mini(storage, bonus);

    sui::event::emit(allocate_event);
}

fun bonus_calc(storage :&mut Storage,
                random : &Random,
                time_ms : u64,
                bonus_history :&mut BonusHistory,
                ctx: &mut TxContext){
    let curr_value = storage.left_balance.value();
    let total_staked = storage.total_staked;
    assert!(curr_value > total_staked);
    let percent = storage.bonus_percent as u64;
    let bonus_amount = (curr_value - total_staked) * percent / 10000;
    let bonus = balance::split(&mut storage.left_balance, bonus_amount);
  
    let shares =  get_hit_users(storage,random, ctx);
    allocate_bonus(storage,bonus,&shares,time_ms,bonus_history,ctx);
    linked_table::drop(shares);
}

/**
dapp call this function periodically ,
the OperatorCap owner key will be deplayed in server
*/
entry fun withdraw_and_allocate_bonus(_ : &OperatorCap,
                                    clock : &Clock,
                                    storage :&mut Storage,
                                    wrapper : &mut SuiSystemState,
                                    random : &Random,
                                    validator_address:address ,  
                                    bonus_history :&mut BonusHistory,
                                    ctx : &mut TxContext){
    let time_ms = clock::timestamp_ms(clock);
    withdraw_all_from_stake(storage, wrapper, ctx);
    bonus_calc(storage, random,time_ms,bonus_history, ctx);
    deposit_storage_balance(storage, wrapper,  validator_address, ctx)
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

/**
fun get_user_range(share : &UserShare ): vector<Range>{
    let point = share.id.to_u256();
    deposit_bonus::range::get_ranges(point, share.amount as u256)
}
*/
fun get_percent_range( point : u256,_percent:u32) : vector<Range>{
    let percent = _percent as u256;
    let len_unit = u256::max_value!() / (PERCENT_MAX as u256);
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
    let user_shares = &storage.user_shares;
    let mut node = linked_table::front(&storage.user_shares);
    let mut hit_user_shares = linked_table::new<address,u256>(ctx);
    while(!option::is_none(node)){
        let addr = node.borrow();
        let user_share = linked_table::borrow(user_shares,*addr);
        let user_range = deposit_bonus::range::get_address_ranges(user_share.id, user_share.share_amount as u256 );
        let overlap_len = deposit_bonus::range::get_overlap_length(&user_range, &hit_ranges);
        if(overlap_len > 0) {
            linked_table::push_back(&mut hit_user_shares, *addr, overlap_len);
        };
        node  = linked_table::next(user_shares, *addr);
    };

    hit_user_shares 
}

entry fun entry_withdraw(clock: &Clock,storage: & mut Storage,wrapper: &mut SuiSystemState,
                        amount : u64,ctx : &mut TxContext){
    let balance = withdraw(clock, storage, wrapper,
                            amount, ctx);
    let coin = coin::from_balance<SUI>(balance,ctx);
    transfer::public_transfer(coin, ctx.sender());
}

public fun get_share_by_user(storage: & Storage,user : address) : u64{
    
    let user_share = linked_table::borrow(&storage.user_shares,user);
    user_share.share_amount
}

public fun get_share(storage: & Storage,ctx : &mut TxContext) : u64{
    get_share_by_user(storage,ctx.sender())
}

/**
ui show user info :
*/
entry fun  query_user_info(storage : &Storage, ctx : &mut TxContext) {
    let sender =  ctx.sender();
    assert!(linked_table::contains(&storage.user_shares,sender),err_consts::account_not_exists!());
    
    let share = linked_table::borrow(&storage.user_shares, sender);
    let share_money = share.share_amount * storage.total_staked / storage.total_shares;
    assert!(share_money >= share.original_money);
    let bonus = share.bonus;
    emit(UserInfo{
        id : sender,
        orignal_amount : share.original_money,
        reward : share_money - share.original_money,
        bonus : bonus,
    });
}


