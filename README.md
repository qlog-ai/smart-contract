# Qlog.AI functions

Steps to do a transaction

```
npx hardhat functions-deploy-consumer --network avalancheFuji --verify true
```

```
npx hardhat functions-sub-create --network avalancheFuji --amount 0.5 --contract 0x9AAD74B441cF87984Df75E1182Fdd03cB43Dd314
```

Approve LINK for your deployed contract https://testnet.snowtrace.io/token/0x0b9d5d9136855f6fec3c0993fee6e9ce8a297846?a=0xf4e20531cd11fb8b70896aa9710fedbeb9be87c3#writeContract

```
npx hardhat functions-request --network avalancheFuji --contract 0x9AAD74B441cF87984Df75E1182Fdd03cB43Dd314 --subid 47
```
