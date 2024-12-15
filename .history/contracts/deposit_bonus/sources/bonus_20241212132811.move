#[allow(unused_use)]
module deposit_bonus::bonus;
use sui::clock::{Self,Clock};

public struct BonusRecord has store,copy,drop{
    id : address,
    gain : u64, //抽奖收获
    pay : u64, //抽奖开销
    principal : u64, //本金
}

public struct BonusPeriod has store,copy,drop{
    time_ms : u64,
    epoch : u64,
    bonus_list : vector<BonusRecord>,
}



public fun create_bonus_record(user :address , 
                            gain : u64, 
                            pay : u64, 
                            principal : u64)
                             : BonusRecord{
    BonusRecord{
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
                          bonus : BonusRecord)
{
    period.bonus_list.push_back(bonus);
}
