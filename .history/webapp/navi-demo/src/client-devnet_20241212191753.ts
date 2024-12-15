import {devnet_consts as consts} from './consts';
import * as dotenv from 'dotenv';
import { bcs } from "@mysten/sui/bcs";
import { SuiClient, getFullnodeUrl } from '@mysten/sui/client';
import { useSignAndExecuteTransaction, useSuiClient } from "@mysten/dapp-kit";
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import { Transaction } from '@mysten/sui/transactions';
import { fromBase64 } from '@mysten/bcs';
import * as fs from 'fs';
import {get_key } from './local_key';

dotenv.config();
// 初始化SUI Client, 用于和主网(mainnet)交互
const suiClient = new SuiClient({ url: getFullnodeUrl('devnet') });
// 从环境变量读取secretKey
const secretKey = process.env.SECRET_KEY || get_key();;
/** 这里把base64编码的secretKey转换为字节数组后截掉第一个元素，是因为第一位是一个私钥类型的标记位，后续派生签名者时不需要 **/
const secretKeyBytes = fromBase64(secretKey).slice(1); // 发起方账户私钥
const signer = Ed25519Keypair.fromSecretKey(secretKeyBytes ); // 生成签名者

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


type BonusWrapper = {
    type : string,
    fields : UserBonus
}

type BonusPeriodWrapper = {
    id : string,
    time_ms : number,
    epoch : number,
    bonus_list : BonusWrapper[]
}




async function get_object(){
    let  result = await suiClient.getObject({
                id : consts.period_id,
                options:{
                        showContent:true,
                        showBcs:true,
                    }
            });
    console.log(result);
    let content  = result.data!.content! as unknown as {fields : any };
    let period = content.fields as unknown as BonusPeriodWrapper;
    console.log("----------fields---------------")

    console.log(period);
    return period
}

function show_period( period :BonusPeriodWrapper){
    let p : BonusPeriod = {
        id : period.id,
        epoch : period.epoch,
        time_ms : period.time_ms,
        bonus_list : []
    };
    let list = p.bonus_list;
    for(let i = 0; i < period.bonus_list.length; ++ i){
        let wrapper = period.bonus_list[i];
        let ub = wrapper.fields;
        ub.pay_rate = ub.gain / ub.pay;
        console.log(wrapper.fields);
        list.push(ub);
    }

    let fd = fs.openSync('bonus_period.json','w')
    fs.writeSync(fd,JSON.stringify(p));
    fs.closeSync(fd);
}

async function get_user_info(addr : string) {
    // const secretKey = process.env.SECRET_KEY || get_key();
    //  这里把base64编码的secretKey转换为字节数组后截掉第一个元素，是因为第一位是一个私钥类型的标记位，后续派生签名者时不需要 
    // const secretKeyBytes = fromBase64(secretKey).slice(1); // 发起方账户私钥
    // const signer = Ed25519Keypair.fromSecretKey(secretKeyBytes ); // 生成签名者
    const tx = new Transaction();
    tx.setGasBudget(200000000);
    let target = `${consts.package_id}::deposit_bonus::get_recent_records`;
    tx.moveCall({
        target: target,
        arguments:[ ],
        
    });
    console.log(`ready call:target `);
    const result = await suiClient.signAndExecuteTransaction({ 
                                signer: signer, 
                                transaction: tx});
    console.log("get_recent_records:",result)
    const response = await suiClient.waitForTransaction({
        digest: result.digest,
        options: {
           showEvents: true,
        },
    });
    console.log("wait result :", response);
    //let data =  response.events![0].parsedJson as {flag_result:Uint8Array};
    //console.log("flag_result" , data.flag_result);
    //return data.flag_result;
}


async function get_storage(){

    let result = suiClient.getObject(consts.storge);
}
/**
async function check_in(my_flag:Uint8Array){
    let git_id = 'nextuser'
    console.log('get flag_string');
    let flag_obj = await suiClient.getObject({id: consts.flag_object_id});
    console.log("flag:",flag_obj);   
    let tx = new Transaction();    
    tx.moveCall({
        target: `${consts.checkin_package_id}::check_in::get_flag`,
        arguments:[ tx.pure(bcs.vector(bcs.U8).serialize(my_flag)),
                    tx.pure(bcs.string().serialize(git_id).toBytes()),

                    tx.object(flag_obj.data!.objectId),
                    tx.object("0x8"),
                    //tx.object(random.data!.objectId)
                ]
    });

    console.log(`ready call:${consts.ctf_package_id}::check_in::get_flag `);
    const result = await suiClient.signAndExecuteTransaction({ 
                                signer: signer, 
                                transaction: tx});
    console.log("-----------------------\n my hash:",result)

    const response = await suiClient.waitForTransaction({
        digest: result.digest,
        options: {
            showEffects: true,
            showEvents: true,
        },
    });
    console.log("wait response:--------------\n",response);

    let event = response.events![0].parsedJson as {flag:boolean,github_id:string,sender:string,ture_num:string};
    return {transaction_digest:result.digest,event:event};
}


*/

get_user_info(consts.USER_1);