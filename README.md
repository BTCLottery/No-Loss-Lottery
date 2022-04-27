# BTCLP No Loss Lottery Contracts

This project demonstrates and covers tools commonly used alongside Hardhat in the ecosystem while doing all tests on a local Binance Smart Chain Mainnet Fork.

# Bscscan verification
In this project, copy the .env.example file to a file named .env, and then edit it to fill in the details. 
Enter your Bscscan API key, your archive node URL (eg from Moralis), and the private key or mnemonic of the account which will send the deployment transaction. 
With a valid .env file in place, you can now deploy your contracts
If you are not used to using Hardhat!
Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help
REPORT_GAS=true npx hardhat test
npx hardhat coverage
npx hardhat run scripts/deploy.js
node scripts/deploy.js
npx eslint '**/*.js'
npx eslint '**/*.js' --fix
npx prettier '**/*.{json,sol,md}' --check
npx prettier '**/*.{json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
```

```shell
hardhat run --network testnet scripts/deploy.js
```

Then, copy the deployment address and paste it in to replace `DEPLOYED_CONTRACT_ADDRESS` in this command:

```shell
npx hardhat verify --network testnet DEPLOYED_CONTRACT_ADDRESS "Hello, Hardhat!"
```
