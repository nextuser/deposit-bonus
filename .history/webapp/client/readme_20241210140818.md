
# 显示数据格式， 实例文件在 data.json
type UserBonus ={
    id : string,
    gain:number,
    pay:number,
    pay_rate : number
    principal : number ,
}


type BonusPeriod = {
    id : string,
    time_ms : number,
    epoch : number,
    bonus_list : UserBonus[]
}


# 数据产生方式
```bash
sui client switch --env devnet
ts-node  client-devnet.ts
```
