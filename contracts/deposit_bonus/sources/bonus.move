#[allow(unused_use)]
module deposit_bonus::bonus;
use sui::clock::{Self,Clock};

public struct UserBonus has store{
    id : address,
    gain : u64, //抽奖收获
    pay : u64, //抽奖开销
    principal : u64, //本金
}

public struct BonusPeriod has key,store{
    id : UID,
    time_ms : u64,
    epoch : u64,
    bonus_list : vector<UserBonus>,
}

public fun create_user_bonus(user :address , 
                            gain : u64, 
                            pay : u64, 
                            principal : u64)
                             : UserBonus{
    UserBonus{
        id : user,
        gain,
        pay,
        principal
    }
}



public  fun create_bonus_period(time_ms : u64,
                                ctx : &mut TxContext) :BonusPeriod {
    BonusPeriod{
        id : object::new(ctx),
        time_ms : time_ms,
        epoch : ctx.epoch(),
        bonus_list : vector[],
    }
}

entry  fun create_period(clock : &Clock,
                         ctx : &mut TxContext)  {
    let p = create_bonus_period(clock.timestamp_ms(), ctx);
    transfer::transfer(p,ctx.sender());
}

public fun add_user_bonus(period : &mut BonusPeriod, 
                          bonus : UserBonus)
{
    period.bonus_list.push_back(bonus);
}

public struct AdminCap has key{ id : UID}

fun init(ctx : &mut TxContext){
    let cap = AdminCap {id : object::new(ctx)};
    transfer::transfer(cap, ctx.sender());
   
}