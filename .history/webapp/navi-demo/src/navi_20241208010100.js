import dotenv from 'dotenv'
import {NAVISDKClient} from 'navi-sdk-test'
dotenv.config();

const mnemonic  = (process.env.mnmonic ) 
const client = new NAVISDKClient(
    {
        networkType : "devnet" ,
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


console.log("---------portfolio--------");
account.getNAVIPortfolio(account.address,true).then(console.log);
console.log("---------health factor--------");
account.getHealthFactor(account.address).then(console.log);

let new_address  = "0xafe36044ef56d22494bfe6231e78dd128f097693f2d974761ee4d649e61f5fa2"
console.log("---------getAddressAvailableRewards--------");
client.getAddressAvailableRewards(account.address,  1).then(console.log);

console.log("---------getUserRewardHistory--------");

client.getUserRewardHistory( account.address,  1,400).then(console.log);