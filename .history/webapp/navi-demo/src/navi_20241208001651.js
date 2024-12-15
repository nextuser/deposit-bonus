import dotenv from 'dotenv'
import {NAVISDKClient} from 'navi-sdk'
dotenv.config();

const private_key : string = process.env.PRIVATE_KEY || ""; 
const client = new NAVISDKClient(
    {
        networkType : "mainnet" ,
        numberOfAccounts : 1,
        privateKeyList : [private_key]
    }
)
