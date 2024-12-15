
/// Module: deposit_bonus
#[allow(unused_variable,unused_use)]

module deposit_bonus::deposit_bonus;
use sui::balance::{Self,Balance};
use sui::coin::{Self,Coin};
use sui::table::{Self,Table};
use sui::clock::{Self,Clock};
use sui::event::emit;
use sui::sui::SUI as CoinType;
use deposit_bonus::err_consts;
use sui_system::staking_pool::{StakedSui, Self};
use sui_system::sui_system::{Self,SuiSystemState};

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

public struct Storage has key,store{
    id : UID,
    user_shares : Table<address,UserShare>,
    total_shares : u64,
    staked_sui : StakedSui,
    bonus_percent : u64,
    
}

//todo ,no use in v1.0
public struct Card has key,store{
    id : UID,
}

fun init(ctx : &mut TxContext){
    let storage = Storage{
        id : object::new(ctx),
        user_shares : table::new(),
        total_shares : 0,
        StakedSui : staking_pool::
    }
}

fun money_to_share(storage :& Storage, money : u64) : u64{
    let total_sui = staking_pool::staked_sui_amount(&storage.staked_sui) as u128;
    let total_share = (storage.total_shares as u128);
    let share_amount = (total_share * (money as u128)  / total_sui) as u64;
    share_amount
}



fun share_to_money(storage : & Storage , share : u64) : u64{
    let total_sui = staking_pool::staked_sui_amount(&storage.staked_sui) as u128;
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

fun split_bonus(){

}

entry fun withraw_bonus(){

}



entry fun deposit(clock: &Clock,storage: & mut Storage,
                  wrapper: &mut SuiSystemState,validator_address: address,
                  coin: Coin<CoinType>, ctx: &mut TxContext) {
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
                    amount : u64,ctx : &mut TxContext) : Balance<CoinType>{
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
        coin: Coin<CoinType>,
        validator_address: address,
        ctx : &mut TxContext)
{
    let s = sui_system::request_add_stake_non_entry(wrapper,coin,
                                                    validator_address,ctx);
    
    staking_pool::join_staked_sui(&mut storage.staked_sui,s);
}

fun withdraw_from_stake(storage :&mut Storage, 
                        wrapper: &mut SuiSystemState,
                        amount : u64,
                        ctx: &mut TxContext) :Balance<CoinType>
{

    let staked_sui = staking_pool::split(&mut storage.staked_sui,
                                                   amount,
                                                   ctx);
    let balance = sui_system::request_withdraw_stake_non_entry(wrapper,staked_sui,ctx);
    balance
}

entry fun entry_withdraw(clock: &Clock,storage: & mut Storage,wrapper: &mut SuiSystemState,
                        amount : u64,ctx : &mut TxContext){
    let balance = withdraw(clock, storage, wrapper,
                            amount, ctx);
    let coin = coin::from_balance<CoinType>(balance,ctx);
    transfer::public_transfer(coin, ctx.sender());
}

public fun get_share(storage: & Storage,ctx : &mut TxContext) : u64{
    let sender = ctx.sender();
    let share = table::borrow(&storage.user_shares,sender);
    share.amount
}



