import  { useState } from 'react';
import {useEffect } from 'react';
import { Input, Button, Space, DatePicker } from 'antd';
import dayjs, { Dayjs } from "dayjs";
import { UserShare } from './contract_types';
import { BonusPeriodWrapper } from './contract_types';
import { to_date_str ,sui_show} from './util';
import { progressPropDefs } from '@radix-ui/themes/dist/esm/components/progress.props.js';
import { useCurrentAccount, useSignAndExecuteTransaction, useSuiClient } from '@mysten/dapp-kit';
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"


const WithdrawUI = (props : {user_info:UserShare, 
                          balance:number,
                          withdraw : (str:string, _max:number) => void,
                          change_period : (addr:string)=>void,
                          periods : BonusPeriodWrapper[]|undefined}) => {
  let user_info = props.user_info;
  let max_value = 0;
  if(user_info){
    max_value = Number(user_info.asset) + Number(user_info.bonus);
    console.log("withdrawui max:",max_value, user_info.asset, user_info.bonus);
  }

  let [withdraw_value, set_deposit_value ] = useState<string>("");

  return (
    <div style={{ marginTop: "20px" }}>
      <Space.Compact style={{ marginBottom: 20 }}>
        <Input
          style={{ width: "60%", marginRight: 10 }}
          placeholder="输入提取金额"
          value={withdraw_value}
          onChange={ (e)=>{set_deposit_value(e.target.value)}}
        />
        <Button type="primary" onClick={(e) =>props.withdraw && props.withdraw(withdraw_value,max_value/1e9)}
           style={{ backgroundColor: '#FFD700', color: 'black' }}>
          取款
        </Button>
        
      </Space.Compact>
      
      
      <div style={{ display: 'flex', gap: '20px', flexWrap: 'wrap', marginBottom: '20px' }}>
      {/* 最大可取卡片 */}
      <Card style={{ flex: '1 1 250px', border: '1px solid #ccc', padding: '10px', borderRadius: '10px', backgroundColor: '#333' }}>
        <CardHeader>
          <img src="/icon.png" alt="Icon" style={{ width: '40px', height: '40px', marginRight: '15px' }} />
          <CardDescription style={{ color: '#fff', fontSize: '12px' }}>最大可提取金额</CardDescription>
        </CardHeader>
        <CardContent style={{ color: '#fff' }}>
          <p style={{ fontSize: '24px', fontWeight: 'bold' }}>{sui_show(max_value)}</p>
        </CardContent>
      </Card>


      {/* 你的利息卡片 */}
      <Card style={{ flex: '1 1 250px', border: '1px solid #ccc', padding: '10px', borderRadius: '10px', backgroundColor: '#333' }}>
        <CardHeader>
        <img src={"/利息.png"} alt="Icon" style={{ width: '40px', height: '40px', marginRight: '15px' }} /> 
        <CardDescription style={{ color: '#fff', fontSize: '12px' }}>你的利息</CardDescription>
        </CardHeader>
        <CardContent style={{ color: '#fff' }}>
        <p style={{ fontSize: '24px', fontWeight: 'bold' }}>{sui_show(user_info.asset - user_info.original_money)}</p>
        </CardContent>
      </Card>

      {/* 你的奖金卡片 */}
      <Card style={{ flex: '1 1 250px', border: '1px solid #ccc', padding: '10px', borderRadius: '10px', backgroundColor: '#333' }}>
        <CardHeader>
          <img src={"/中奖.png"} alt="Icon" style={{ width: '40px', height: '40px', marginRight: '15px' }} /> 
          <CardDescription style={{ color: '#fff', fontSize: '12px' }}>你的奖金</CardDescription>
        </CardHeader>
        <CardContent style={{ color: '#fff' }}>
        <p style={{ fontSize: '24px', fontWeight: 'bold' }}>{sui_show(user_info.bonus)}</p>
        </CardContent>
      </Card>

    </div>
          <div>你的钱包余额: {sui_show(props.balance)} </div>
          <div>你的地址:{useCurrentAccount()!.address}</div>

    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
      <Button className="flex items-center gap-2 text-[#FFD700] mb-4" style={{ backgroundColor: '#FFD700', color: 'black' }}>
        历史开奖时间
      </Button>
            
            <select onChange={(e) => { console.log(e); props.change_period(e.target.value) }}>
        {props.periods && props.periods.length > 0 ? (
          props.periods.map((p, k) => (
            <option value={p.id.id} key={p.id.id}>
              {to_date_str(Number(p.time_ms))}
            </option>
          ))
        ) : (
          <option disabled>没有可用的期次</option>
        )}
      </select>


      </div>
    </div>
  );
};

export default WithdrawUI;
