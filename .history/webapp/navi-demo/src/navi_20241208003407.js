import dotenv from 'dotenv'
import {NAVISDKClient} from 'navi-sdk'
dotenv.config();

const mnemonic  = (process.env.mnmonic ) 
const client = new NAVISDKClient(
    {
        networkType : "mainnet" ,
        numberOfAccounts : 1,
        mnemonic : mnemonic
    }
);
let  account = client.accounts[0];

console.log("derivation path", account.getDerivationPath());


