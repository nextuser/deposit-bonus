
#[allow(unused_use)]
module deposit_to_cap::deposit_to_cap;
use lending_core::lending::{create_account};
use lending_core::incentive_v2::{Self,
                            claim_reward_with_account_cap,
                            deposit_with_account_cap,
                            withdraw_with_account_cap,
                            Incentive,IncentiveFundsPool};
use lending_core::account::{AccountCap};
use lending_core::storage::Storage;
use lending_core::pool::Pool;
use lending_core::incentive::Incentive as IncentiveV1;

use sui::clock::Clock;

use sui::sui::SUI;
use sui::coin::{Self,Coin};
use sui::balance::{Self,Balance};
use sui::table::{Self,Table};
use sui::tx_context::{Self,TxContext};
use oracle::oracle::PriceOracle;
public struct Data  has key{
    id : UID,
    balances : Balance<SUI> ,
    interests : Balance<SUI>,
}

public struct AdminCap has key{ id:UID}

fun init(ctx:&mut TxContext){
    let sender = ctx.sender();
    let account_cap : AccountCap = create_account(ctx);
    transfer::public_transfer(account_cap,sender);

    let admin_cap = AdminCap{ id : object::new(ctx)};
    transfer::transfer(admin_cap, sender);

    let data = Data{
        id : object::new(ctx),
        balances : balance::zero<SUI>(),
        interests : balance::zero<SUI>()
    };
    transfer::share_object(data);
} 

public fun deposit(
        clock: &Clock, storage: &mut Storage, pool: &mut Pool<SUI>, 
        asset: u8, deposit_coin: Coin<SUI>,incentive_v1: &mut IncentiveV1, 
        incentive_v2: &mut Incentive,account_cap: &AccountCap,
        data : &mut Data,ctx : &mut TxContext)
{

  deposit_with_account_cap(clock,storage,pool,
                            asset,deposit_coin,incentive_v1,
                            incentive_v2,account_cap );
            
    
}


public fun claim_reward(
                clock: &Clock, incentive: &mut Incentive, funds_pool: &mut IncentiveFundsPool<SUI>, 
                storage: &mut Storage, asset_id: u8, option: u8, 
                account_cap: &AccountCap,data : &mut Data,ctx : &mut TxContext)
{
    let b = claim_reward_with_account_cap(clock, incentive, funds_pool,
                                                     storage, asset_id, option, 
                                                     account_cap);
    
    balance::join(&mut data.interests,b);

}
	

public fun withdraw(
    clock: &Clock, oracle: &PriceOracle, storage: &mut Storage, 
    pool: &mut Pool<SUI>, asset: u8, amount: u64, 
    incentive_v1: &mut IncentiveV1, incentive_v2: &mut Incentive, 
    account_cap: &AccountCap,data : &mut Data,ctx : &mut TxContext)
{
    let b = withdraw_with_account_cap(
                                            clock,oracle,storage,
                                            pool,asset,amount,
                                            incentive_v1,incentive_v2,
                                            account_cap);
    balance::join(&mut data.balances, b);
}


public fun withdraw_all(data : &mut Data,ctx : &mut TxContext){

}


public fun withdraw_all_interests(data : &mut Data,ctx : &mut TxContext){
    let sender = ctx.sender();
    let mut amount = balance::value(&data.interests);
    transfer::public_transfer(coin::from_balance(data.interests.split(amount),ctx),
                            sender);
    amount = balance::value(&data.balances);
    transfer::public_transfer(coin::from_balance(data.balances.split(amount), ctx),
                                sender);
}



