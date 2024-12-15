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