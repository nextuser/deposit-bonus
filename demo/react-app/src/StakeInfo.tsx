import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { UserShare } from './contract_types';
import {AddressBalance} from './AddressBalance'
import { sui_show } from "./util"

export function StakeInfo(props:{ user_info : UserShare})
{
  return (
    <div style={{ display: 'flex', gap: '20px', flexWrap: 'wrap', marginBottom: '20px' }}>
      {/* 最大可取卡片 */}
      <Card style={{ flex: '1 1 250px', border: '1px solid #ccc', padding: '10px', borderRadius: '10px', backgroundColor: '#333' }}>
        <CardHeader>
          <img src="/icon.png" alt="Icon" style={{ width: '40px', height: '40px', marginRight: '15px' }} />
          <CardDescription style={{ color: '#fff', fontSize: '12px' }}>目前存款</CardDescription>
        </CardHeader>
        <CardContent style={{ color: '#fff' }}>
          <p style={{ fontSize: '24px', fontWeight: 'bold' }}>{sui_show(props.user_info.original_money)}</p>
        </CardContent>
      </Card>


      {/* 你的利息卡片 */}
      <Card style={{ flex: '1 1 250px', border: '1px solid #ccc', padding: '10px', borderRadius: '10px', backgroundColor: '#333' }}>
        <CardHeader>
        <img src={"/利息.png"} alt="Icon" style={{ width: '40px', height: '40px', marginRight: '15px' }} /> 
        <CardDescription style={{ color: '#fff', fontSize: '12px' }}>你的利息</CardDescription>
        </CardHeader>
        <CardContent style={{ color: '#fff' }}>
        <p style={{ fontSize: '24px', fontWeight: 'bold' }}>{sui_show(props.user_info.asset - props.user_info.original_money)}</p>
        </CardContent>
      </Card>

      {/* 你的奖金卡片 */}
      <Card style={{ flex: '1 1 250px', border: '1px solid #ccc', padding: '10px', borderRadius: '10px', backgroundColor: '#333' }}>
        <CardHeader>
          <img src={"/中奖.png"} alt="Icon" style={{ width: '40px', height: '40px', marginRight: '15px' }} /> 
          <CardDescription style={{ color: '#fff', fontSize: '12px' }}>你的奖金</CardDescription>
        </CardHeader>
        <CardContent style={{ color: '#fff' }}>
        <p style={{ fontSize: '24px', fontWeight: 'bold' }}>{sui_show(props.user_info.bonus)}</p>
        </CardContent>
      </Card>
    </div>)

}