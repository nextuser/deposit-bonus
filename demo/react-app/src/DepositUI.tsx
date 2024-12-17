import  { useState } from 'react';
import {useEffect } from 'react';
import { Input, Button, Space, DatePicker } from 'antd';
import dayjs, { Dayjs } from "dayjs";
import { UserShare } from './contract_types';
import { BonusPeriodWrapper } from './contract_types';
import { to_date_str ,sui_show} from './util';
import { progressPropDefs } from '@radix-ui/themes/dist/esm/components/progress.props.js';
import { DownOutlined } from '@ant-design/icons';
import { useCurrentAccount, useSignAndExecuteTransaction, useSuiClient } from '@mysten/dapp-kit';
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { AddressBalance } from './AddressBalance';
import { StakeInfo } from './StakeInfo';

const DepositUI = (props : {user_info:UserShare, 
                          balance:number,
                          deposit : (str:string,max:number) => void,
                          change_period : (addr:string)=>void,
                          periods : BonusPeriodWrapper[]|undefined}) => {
  let user_info = props.user_info;
  let max = Number(props.balance);
  let address = useCurrentAccount()?.address;                        

  const handleAddDeposit = () => {
    // 假设这里是添加存款的逻辑
    ///setTotalDeposit(totalDeposit + parseFloat(depositInput));
    // 你可以根据需要更新利息和中奖金额
  };

  let [deposit_value, set_deposit_value ] = useState<string>("");

  return (
    <div style={{ marginTop: "20px" }}>
      <Space.Compact style={{ marginBottom: 20 }}>
        <Input
          style={{ width: "60%", marginRight: 10 }}
          placeholder="输入存款金额"
          value={deposit_value}
          onChange={ (e)=>{set_deposit_value(e.target.value)}}
        />

        <Button 
          onClick={(e) => props.deposit && props.deposit(deposit_value, max / 1e9)} 
          style={{ backgroundColor: '#FFD700', color: 'black' }}
        >
          增加存款
        </Button>
      </Space.Compact>
      
     
    <StakeInfo user_info={props.user_info} />
    <AddressBalance balance={props.balance} />
    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
  <Button className="flex items-center gap-2 text-[#FFD700] mb-4" style={{ backgroundColor: '#FFD700', color: 'black' }}>
    历史开奖时间
  </Button>
  
  <select 
    onChange={(e) => {
      console.log(e);  
      props.change_period(e.target.value);
    }} 
    style={{ padding: '5px', fontSize: '14px' }}
  >
    {props.periods && props.periods!.map((p, k) => {
      return <option value={p.id.id} key={p.id.id}>{to_date_str(Number(p.time_ms))}</option>
    })}
  </select>
</div>

      </div>
  );
};

export default DepositUI;
