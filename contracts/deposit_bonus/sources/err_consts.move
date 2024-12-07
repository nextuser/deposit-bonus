module deposit_bonus::err_consts;

public macro fun share_not_enough() : u64{
    0
}
public macro fun account_not_exists() : u64{
    1
}

public macro fun balance_not_enough() : u64{
    2
}
public macro fun empty_range(): u64 {
    3
}