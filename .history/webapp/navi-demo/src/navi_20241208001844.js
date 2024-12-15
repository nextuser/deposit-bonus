import dotenv from 'dotenv'
import {NAVISDKClient} from 'navi-sdk'
dotenv.config();

const private_key  = (process.env.PRIVATE_KEY ) || "AFof4r1AYwrMtfOoJ8lwU4ewYec9YHC5UQGwXn78nnuE"; 
const client = new NAVISDKClient(
    {
        networkType : "mainnet" ,
        numberOfAccounts : 1,
        privateKeyList : [private_key]
    }
)
