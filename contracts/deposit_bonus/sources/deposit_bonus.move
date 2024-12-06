
/// Module: deposit_bonus
#[allow(unused_variable)]
module deposit_bonus::deposit_bonus;
use sui::balance::{Self,Balance};
use sui::coin::{Self,Coin};
use sui::table::{Self,Table};
use sui::clock::{Self,Clock};
use sui::event::emit;
use sui::sui::SUI as CoinType;

public struct DepositEvent has copy,drop{
    user : address,
    amount : u64,
    update_time_ms : u64,
}

public struct UserShare  has store{
    id : address,
    amount  : u64,
    update_time_ms: u64,
}

public struct Storage has key,store{
    id : UID,
    user_shares : Table<address,UserShare>,
    total_shares : u64,
    balances : Balance<CoinType>,
}

//todo ,no use in v1.0
public struct Card has key,store{
    id : UID,
}

fun add_share(storage :&mut Storage , amount : u64,time_ms:u64, sender : address){
    if(table::contains(&storage.user_shares, sender)){
        let share = table::borrow_mut(&mut storage.user_shares,sender);
        share.amount = share.amount + amount;
    }
    else{
        let share = UserShare{
            id :sender,
            amount : amount,
            update_time_ms : time_ms,
        };
        table::add(&mut storage.user_shares,sender, share);
    };
    storage.total_shares = storage.total_shares + amount;
}

entry fun deposit(clock: &Clock,storage: & mut Storage, coin: Coin<CoinType>, ctx: & TxContext) {
    let update_time_ms = clock::timestamp_ms(clock);
    let value = coin::value(&coin);
    balance::join(&mut storage.balances, coin::into_balance(coin));
    let sender = ctx.sender();

    add_share(storage, value, update_time_ms, sender);

    emit(DepositEvent{
        user : sender,
        amount : value,
        update_time_ms : update_time_ms,        
    });
}

#[allow(unused_mut_parameter)]
entry fun take_balance_from_dex(clock: &Clock,storage: & mut Storage, amount : u64,ctx : &mut TxContext){

}

const ErrNoAccount : u64 = 0;
const ErrNoEnoughShare : u64 = 1;
const ErrTakeBalanceFailButShareEnough : u64 = 2;
public  fun withdraw(clock: &Clock,storage: & mut Storage,amount : u64,ctx : &mut TxContext) : Balance<CoinType>{
    let sender = ctx.sender();
    assert!( table::contains(&storage.user_shares,sender),ErrNoAccount );
    //check share
    let share = table::borrow(&storage.user_shares, sender);
    assert!(share.amount >= amount , ErrNoEnoughShare);
    
    // take money from dex
    if(storage.balances.value() < amount ){
        take_balance_from_dex(clock, storage, amount, ctx);
    };
    // make  balance enough
    assert!(storage.balances.value() >= amount,ErrTakeBalanceFailButShareEnough);
    let balance = storage.balances.split(amount);
    
    let mshare = table::borrow_mut(&mut storage.user_shares, sender);  
    mshare.amount = mshare.amount - amount;
    storage.total_shares = storage.total_shares - amount;
    if(mshare.amount == 0){
        let s = table::remove(&mut storage.user_shares,sender);
        let UserShare{ id : _,amount :_,update_time_ms: _  } = s;
    };
    balance
}


entry fun entry_withdraw(clock: &Clock,storage: & mut Storage,amount : u64,ctx : &mut TxContext){
    let b = withdraw(clock, storage, amount, ctx);
    transfer::public_transfer(coin::from_balance<CoinType>(b,ctx), ctx.sender());
}