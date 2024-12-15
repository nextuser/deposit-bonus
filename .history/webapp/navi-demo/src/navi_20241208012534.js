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
console.log("account is",account);

console.log("derivation path", account.getDerivePath());


account.getAllCoins( true).then(console.log);

// Fetches details of all coins held across different objects
///Get Specific Token Info:

console.log("coins sui:",await account.getCoins("0x2::sui::SUI"));
// Fetches objects for a specific token type (e.g., SUI)
///Get Address Merged Coin Balance:

console.log("wallet balance:",await account.getWalletBalance(true));

console.log(client.getAllAccounts());

function get_promp_print(str){
    let f = function(arg){
        console.log(`----------${str}---------------`);
        console.log(arg);
    }
    return f;
}

let new_address  = "0xafe36044ef56d22494bfe6231e78dd128f097693f2d974761ee4d649e61f5fa2"

account.getNAVIPortfolio(new_address,true).then(get_promp_print("getNAVIPortfolio"));

account.getHealthFactor(new_address).then(get_promp_print("getHealthFactor"));

client.getAvailableRewards(new_address,  1).then(get_promp_print("getAddressAvailableRewards"));

import {Sui,USDC} from 'navi-sdk/'
client.getPoolInfo()