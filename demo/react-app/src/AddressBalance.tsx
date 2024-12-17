import {
    Card,
    CardContent,
    CardDescription,
    CardFooter,
    CardHeader,
    CardTitle,
  } from "@/components/ui/card"
import { sui_show } from "./util"
import { useCurrentAccount } from "@mysten/dapp-kit"
export function AddressBalance(props : {balance : number}) {
    return (
    <div style={{ display: 'flex', gap: '20px', flexWrap: 'wrap', marginBottom: '20px' }}>
    {/* 你的钱包余额 */}
   <Card style={{ flex: '1 1 250px', border: '1px solid #ccc', padding: '10px', borderRadius: '10px', backgroundColor: '#333' }}>
     <CardHeader>
      <CardDescription style={{ color: '#fff' }}>钱包余额</CardDescription>
     </CardHeader>
     <CardContent style={{ color: '#fff' }}>
       <p> {sui_show(props.balance)} </p>
     </CardContent>
   </Card>
   {/* 你的地址卡片 */}
   <Card style={{ flex: '1 1 250px', border: '1px solid #ccc', padding: '10px', borderRadius: '10px', backgroundColor: '#333' }}>
     <CardHeader>
       <CardDescription style={{ color: '#fff' }}>地址</CardDescription>
     </CardHeader>
     <CardContent style={{ color: '#fff' }}>
       <p>{useCurrentAccount()!.address}</p>
     </CardContent>
   </Card>
 </div>)
}