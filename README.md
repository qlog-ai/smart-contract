# Qlog.AI Smart contract with Chainlink Functions

Flow is basically you pay in Link for a dataset, there will be a fee subtracted for paying the Chainlink Functions subscription and it will put the dataset on IPFS.
You can access the CID yourself or access it from https://qlog.ai if you login with your wallet

## Unique features

1. Paying with Link for access to the dataset while substracting a fee for the chainlink function subscription (never need to manually add LINK to it)
2. Use the Chainlink function with advanced retry code with improved limits (9000ms timeouts, happy with that change :D)
3. Refund if we received an error, it will cost us some LINK but it is our responsibility to keep the API up (also depended on web3storage, but if they are not good enough we should implement a fallback option in the future)

Couldn't add the unique source hash check for the source yet (to prevent secret phishing by trying different sources in the transaction, it is a costy attack vector though), because there is no more time unfortunately

## Transaction flow

Steps to do a transaction

```
npx hardhat functions-deploy-consumer --network avalancheFuji --verify true
```

```
npx hardhat functions-sub-create --network avalancheFuji --amount 0.5 --contract 0x88b9BB23d84C4F5Ebbb2E257e8C7882Af60Ea281
```

Approve LINK for your deployed contract https://testnet.snowtrace.io/token/0x0b9d5d9136855f6fec3c0993fee6e9ce8a297846?a=0xf4e20531cd11fb8b70896aa9710fedbeb9be87c3#writeContract

```
npx hardhat functions-request --network avalancheFuji --contract 0x88b9BB23d84C4F5Ebbb2E257e8C7882Af60Ea281 --subid 48 --callbackgaslimit 300000
```

Awesome great success: 

https://testnet.snowtrace.io/tx/0xd47bcd5554a8b559666faa113726249ee990155051438dffeb308582abe6f370

Deployed verified contract that uses Chainlink Functions: 

https://testnet.snowtrace.io/address/0x88b9BB23d84C4F5Ebbb2E257e8C7882Af60Ea281#writeContract