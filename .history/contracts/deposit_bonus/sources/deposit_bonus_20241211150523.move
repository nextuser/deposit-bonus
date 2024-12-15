
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
use sui_system::sui_system::{Self,SuiSystemState,request_withdraw_stake_non_entry,request_add_stake_non_entry};
use deposit_bonus::range::Range;
use deposit_bonus::bonus;
use sui::linked_table::{Self,LinkedTable};
use std::debug::print;

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



fun money_to_share(storage :& Storage, money : u64) : u64{
    
    let total_sui = storage.total_staked as u128;
    assert!(total_sui != 0);
    let total_share = (storage.total_shares as u128);
    if(total_share == 0) {
        return money;
    };
    let share_amount = (total_share * (money as u128)  / total_sui) as u64;
    share_amount
}

fun share_to_money(storage : & Storage , share : u64) : u64{
    let total_sui = storage.total_staked as u128;
    let total_shares = storage.total_shares as u128;
    (total_sui * (share as u128) / total_shares) as u64
}

fun update_share_after_stake(storage :&mut Storage , original_money : u64,time_ms:u64, sender : address) : u64{
    let share_amount = money_to_share(storage, original_money);
    let user_shares = &mut storage.user_shares;

    if(user_shares.contains(sender)){
        let user_share = user_shares.borrow_mut(sender);
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
        user_shares.push_back(sender, user_share);
    };

    storage.total_shares = storage.total_shares + share_amount;
    share_amount
}

entry fun deposit(clock: &Clock,storage: & mut Storage,
                  wrapper: &mut SuiSystemState,validator_address: address,
                  coin: Coin<SUI>, ctx: &mut TxContext) {
    
    let sender = ctx.sender();
    let update_time_ms = clock::timestamp_ms(clock);
    let value = coin::value(&coin);
    deposit_to_stake(storage, wrapper, coin, validator_address,ctx);
    let share = update_share_after_stake(storage, value, update_time_ms, sender);

    emit(DepositEvent{
        user : sender,
        share_amount : share,
        amount : value,
        update_time_ms : update_time_ms,        
    });
}

fun reduce_share_after_withdraw(storage : &mut Storage, withdraw_share : u64, sender : address)
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
1  take bonus first ,if meet the amount ,return
2  take the staked sui to meet amount
*/
public  fun withdraw(clock: &Clock,storage: & mut Storage,wrapper: &mut SuiSystemState,
                    amount : u64,ctx : &mut TxContext) : Balance<SUI>{
    let sender = ctx.sender();
    assert!( linked_table::contains(&storage.user_shares,sender),err_consts::account_not_exists!() );
    

    let user_share = linked_table::borrow(&storage.user_shares, sender);
    let bonus_amount = user_share.bonus;
    let share_amount = user_share.share_amount ;
    if(bonus_amount >= amount){
        let bonus = withdraw_bonus(storage, amount,ctx);
        assert!(bonus.value() >= amount);
        return bonus
    };
    
    let bonus = withdraw_bonus(storage, bonus_amount, ctx);
    let need = amount - bonus.value();    

    let user_money = share_to_money(storage, share_amount);
    assert!(user_money  >= need ,err_consts::share_not_enough!() );
    let mut balance = withdraw_from_stake(storage, wrapper, need, ctx);
    balance.join(bonus);

    let withdraw_share = money_to_share(storage, need);
    reduce_share_after_withdraw(storage,withdraw_share,sender);
    balance
}

fun deposit_to_stake(storage :&mut Storage,
        wrapper: &mut SuiSystemState,
        coin: Coin<SUI>,
        validator_address: address,
        ctx : &mut TxContext)
{
    let coin_value = coin.value();
    let s = request_add_stake_non_entry(wrapper,coin,
                                                    validator_address,ctx);
    // print(&b"staked sui".to_string());
    // print(&s);
    // print(&b"staked sui amount ".to_string());
    // print(&s.amount());
    // print(&b"coin value:".to_string());
    // print(&coin_value);
    assert!(s.amount() == coin_value);
    storage.total_staked = storage.total_staked + s.amount();
    add_staked_sui(storage, s) ;   
    
}

/**
before to call this function,  call withdraw_all_from_stake at first ,
*/
fun stake_left_balance(storage :&mut Storage,
        wrapper: &mut SuiSystemState,
        validator_address: address,
        ctx : &mut TxContext)
{
    let amount = balance::value(&storage.left_balance);
    let balance = balance::split(&mut storage.left_balance, amount );
    let coin = coin::from_balance(balance, ctx);
    let s = request_add_stake_non_entry(wrapper,coin,
                                                    validator_address,ctx);
    
    storage.total_staked =  staking_pool::staked_sui_amount(&s);   
    //old staked_sui should be withdrawed
    assert!(vector::is_empty(&storage.staked_suis));
    storage.staked_suis.push_back(s);
}

fun save_to_left_balance(storage :&mut Storage, balance : Balance<SUI> ){
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
    save_to_left_balance(storage, merge_balance);
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
        let mut staked_sui  =  storage.staked_suis.pop_back();

        let need = amount - merge_balance.value();
        let curr_amount = staking_pool::staked_sui_amount(&staked_sui) ;
        if( curr_amount >= need  ){
            let split = staked_sui.split(need, ctx);
            let balance = request_withdraw_stake_non_entry(wrapper,split,ctx);
            assert!(balance.value() >= need, err_consts::balance_less_than_staked!());
            merge_balance.join(balance);
            storage.staked_suis.push_back(staked_sui);
            storage.total_staked = storage.total_staked - need;
            assert!(merge_balance.value() >=  amount);
            
        }
        else{
              let balance = request_withdraw_stake_non_entry(wrapper,staked_sui,ctx); 
              merge_balance.join(balance);
              storage.total_staked = storage.total_staked - curr_amount;
        };
        if(merge_balance.value() >= amount){
            return split_exact_balance(storage,merge_balance , amount)
        }

    };
    assert!(merge_balance.value() >= amount, err_consts::withdraw_fail!());
    split_exact_balance(storage,merge_balance , amount)
}

/**
take the reward  after a period
*/
fun withdraw_all_from_stake(storage :&mut Storage, 
                        wrapper: &mut SuiSystemState,
                        ctx: &mut TxContext) :(u64,u64) {

    let count = vector::length(&storage.staked_suis);
    let mut merge_balance = balance::zero<SUI>();
    while(!vector::is_empty<StakedSui>(&storage.staked_suis)){
        let staked_sui  = vector::pop_back(&mut storage.staked_suis);
        let b = request_withdraw_stake_non_entry(wrapper,staked_sui,ctx); 
        merge_balance.join(b);
    };
    storage.left_balance.join(merge_balance);
    let old = storage.total_staked;
    let new = storage.left_balance.value();
    storage.total_staked = 0;
    (old,new)
    
}

fun allocate_bonus(storage : &mut Storage,
                    balance_amount : u64, 
                    shares : &LinkedTable<address,u256>,
                    time_ms : u64,
                    bonus_history :&mut BonusHistory,
                    ctx :&mut TxContext){
    let mut total = 0;
    let mut period = bonus::create_bonus_period(time_ms,ctx);



    let mut allocate_event = AllocateEvent {
           users : vector[],
           total_amount : balance_amount, 
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

        let gain = (balance_amount as u256) * amount / total;
        //let gain_balance : Balance<SUI> = balance::split<SUI>(&mut bonus, gain as u64);
        //let coin = coin::from_balance(gain_balance, ctx);
        
        let user_share = linked_table::borrow_mut<address,UserShare>(&mut storage.user_shares,addr);
        let pay = (user_share.share_amount * balance_amount )/ storage.total_shares;
        let record = bonus::create_bonus_record(addr ,  gain as u64,
                                                        pay , user_share.original_money) ;
        bonus::add_user_bonus(&mut period, record);
        user_share.bonus = gain as u64;
        vector::push_back(&mut allocate_event.users, Share{
            id : addr,
            amount :  user_share.bonus
        });
        ////transfer::public_transfer(coin, addr);
        
        node = linked_table::next(shares,addr);
    };
    bonus_history.history.push_back(object::id(&period).to_address());
    transfer::public_share_object(period);
    sui::event::emit(allocate_event);
}

fun bonus_calc(storage :&mut Storage,
                random : &Random,
                total_rewards : u64,
                time_ms : u64,
                bonus_history :&mut BonusHistory,
                ctx: &mut TxContext){

    let percent = storage.bonus_percent as u128;
    let bonus_amount = ((total_rewards as u128) * percent / (PERCENT_MAX as u128)) as u64;
    let bonus = balance::split(&mut storage.left_balance, bonus_amount);
    storage.bonus_balance.join(bonus);
    let shares =  get_hit_users(storage,random, ctx);
    allocate_bonus(storage,bonus_amount,&shares,time_ms,bonus_history,ctx);
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
    let (old,new ) = withdraw_all_from_stake(storage, wrapper, ctx);
    assert!(old <= new);
    let total_rewards = new - old;
    bonus_calc(storage, random,total_rewards,time_ms,bonus_history, ctx);
    stake_left_balance(storage, wrapper,  validator_address, ctx)
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

public fun get_share_by_user(storage: & Storage,user : address) : u64{
    
    let user_share = linked_table::borrow(&storage.user_shares,user);
    user_share.share_amount
}

public fun get_share(storage: & Storage,ctx : &mut TxContext) : u64{
    get_share_by_user(storage,ctx.sender())
}

/**
ui show user info :
sui */
entry fun  query_user_info(storage : &Storage, ctx : &TxContext) {
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

/**
withdraw less than amount
*/
public fun withdraw_bonus(storage : &mut Storage,amount : u64, ctx : &mut TxContext) :Balance<SUI> {
    let sender = ctx.sender(); 
    if(!storage.user_shares.contains(sender)){
        return balance::zero()
    };
    let user_share = storage.user_shares.borrow_mut(sender);
    assert!( user_share.bonus <= storage.bonus_balance.value());
 
    if(user_share.bonus == 0){
        return balance::zero()
    };

    if(user_share.bonus > amount ){
        let balance = storage.bonus_balance.split(amount);
        user_share.bonus = user_share.bonus - amount;
        balance
    }
    else{

        let balance = storage.bonus_balance.split(user_share.bonus);
        user_share.bonus = 0;
        balance
    }

}

public struct WithdrawEvent has copy,drop{
    sender : address,
    request_amount : u64,
    receive_amount : u64,
}


entry fun entry_withdraw_bonus(storage : &mut Storage, amount : u64 ,ctx : &mut TxContext){
    let sender = ctx.sender();
    let balance = withdraw_bonus(storage,amount,ctx);
    if(balance.value() > 0){
        let coin = coin::from_balance(balance,ctx);
        emit(WithdrawEvent{
            sender,
            request_amount  : amount,
            receive_amount : coin.value(),
        });
        transfer::public_transfer(coin, sender);
    }
    else{
        balance.destroy_zero();
    }
}
const VALIDATOR1_ADDR : address = @0x1;
const VALIDATOR2_ADDR : address = @0x2;
const ADMIN_ADDR : address = @0xa;
const OPERATOR_ADDR : address = @0xb;
const USER1_ADDR : address = @0x11;
const USER2_ADDR : address = @0x12;
#[test_only] use sui::test_utils::assert_eq;
#[test_only] use sui::test_scenario::{Self as tests, Scenario};
#[test_only] use sui::test_utils;
#[test_only] use sui_system::governance_test_utils::{add_validator_full_flow, advance_epoch, remove_validator, set_up_sui_system_state, create_sui_system_state_for_testing, stake_with, unstake};
#[test_only]
fun test_init() : (Clock,Random,Scenario,Storage)
{
    let mut sc = tests::begin(@0x0);
    sui::random::create_for_testing(sc.ctx());
    let clock = sui::clock::create_for_testing(sc.ctx());
   

    let mut effect = tests::next_tx(&mut sc,ADMIN_ADDR);
    let random = sc.take_shared<Random>();
    {
        init(sc.ctx());
    };
    tests::next_tx(&mut sc,@0xa);
    
    let admin_cap = tests::take_from_address<AdminCap>(&sc, ADMIN_ADDR);
    let operator_cap = tests::take_from_address<OperatorCap>(&sc, ADMIN_ADDR);
    assign_operator(&admin_cap,operator_cap, OPERATOR_ADDR);
    tests::return_to_address(ADMIN_ADDR,admin_cap);

    set_up_sui_system_state(vector[@0x1, @0x2]);
    {
        sc.next_tx(@0x0);
        let mut system_state = sc.take_shared<SuiSystemState>();
        let staking_pool = system_state.active_validator_by_address(@0x1);
        tests::return_shared(system_state);
       
        // .get_staking_pool_ref();
        // assert!(staking_pool.pending_stake_amount() == 0, 0);
        // assert!(staking_pool.pending_stake_withdraw_amount() == 0, 0);
        // assert!(staking_pool.sui_balance() == 100 * 1_000_000_000, 0);
        // tests::return_shared(system_state);
    };

    sc.next_tx(@0x0);
    let storage = tests::take_shared<Storage>(&sc);
    (clock,random,sc,storage)

}

#[test_only]
fun test_finish(clock : Clock,
            random: Random,
            sc :Scenario,
            storage:Storage){
    tests::return_shared(random);
    tests::return_shared(storage);
    test_utils::destroy(clock);
    tests::end(sc);
}

fun log<T>(prompt : vector<u8>,  obj: &T ){
    print(&prompt.to_string());
    print(obj);
}

#[test]
fun test_deposit(){
    let  (clock,random,mut sc,mut storage) = test_init();
    tests::next_tx(&mut sc, USER1_ADDR);
    let mut system_state = sc.take_shared<SuiSystemState>();
    let amount = 50_000_000_000;
    let coin = coin::mint_for_testing(amount, sc.ctx());
    deposit(&clock, &mut storage, &mut system_state,
             VALIDATOR1_ADDR, coin, sc.ctx());

    let share = get_share_by_user(&storage, USER1_ADDR);
    
    print(&share);
    print(&amount);
    assert_eq(share, amount);

    query_user_info(&storage,sc.ctx());
    let effect = tests::next_tx(&mut sc,USER1_ADDR);
    assert_eq(effect.num_user_events() ,1 );

    tests::return_shared(system_state);
  
    test_finish(clock, random,sc,storage);

}

#[test]
fun test_hit_range(){
    let  (clock,random,mut sc,mut storage) = test_init();
    tests::next_tx(&mut sc, @0xc);
    

    
    test_finish(clock, random,sc,storage);

}


#[test]
fun test_point(){
    let  (clock,random,mut sc,mut storage) = test_init();
    tests::next_tx(&mut sc, @0xc);
    let mut i = 0;
    while(i < 10){
        let val = create_random_point(&mut storage,&random,sc.ctx());
        std::debug::print(&val);
        i = i + 1;
    };

    test_finish(clock, random,  sc,storage);
}