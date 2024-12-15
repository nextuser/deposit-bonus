import dotenv from 'dotenv'
import {NAVISDKClient} from 'navi-sdk-test'
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

//console.log("derivation path", account.getDerivationPath());
console.log("get all coinds",account.getAllCoins());


account.getAllCoins(prettyPrint = true) 
// Fetches details of all coins held across different objects
///Get Specific Token Info:

account.getCoins(coinType = "0x2::sui::SUI")
// Fetches objects for a specific token type (e.g., SUI)
///Get Address Merged Coin Balance:

console.log(account.getWalletBalance(prettyPrint = true));

console.log(client.getAllAccounts());