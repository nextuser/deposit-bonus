import dotenv from 'dotenv'
import {NAVISDKClient} from 'navi-sdk'
dotenv.config();

const mnemonic  = (process.env.mnemonic ) 
const client = new NAVISDKClient(
    {
        networkType : "mainnet" ,
        numberOfAccounts : 5,
        wordLength : 12,
        mnemonic : mnemonic
    }
);
let  account = client.accounts[0];
console.log("accounts is",client.accounts);

///console.log("derivation path", account.getDerivationPath());


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

//client.getAvailableRewards(new_address,1).then(get_promp_print("getAddressAvailableRewards"));
client.getAddressAvailableRewards(new_address,  1).then(get_promp_print("getAddressAvailableRewards"));

import {Sui,nUSDC,USDT} from 'navi-sdk/dist/address.js'
///console.log(wUSDC.address,USDT.symbol,wUSDC.decimal);
client.getPoolInfo(Sui).then(get_promp_print('Sui pool info'))
client.getPoolInfo(nUSDC).then(get_promp_print('USDC pool info'))

client.getReserveDetail(Sui).then(get_promp_print('sui reserve details'));
client.getReserveDetail(nUSDC).then(get_promp_print('usdc reserve detials'))

account.depositToNavi(Sui,1000);

account.claimAllRewards(true).then(get_promp_print('claim all rewards'));