# CZIX Contracts

This project demonstrates and covers tools commonly used alongside Hardhat in the ecosystem while doing all tests on a local Binance Smart Chain Mainnet Fork.
This comes with all tests and deployment script config for the CZIX Smart Contracts. 

<!-- INTREABA EXACT Vesting releases pentru private si diferenta emissiei vestingului public rounds -->

# CZIX TOKEN DISTRIBUTION - TOTAL SUPPLY = 200M CZIX
1. Private Sale - 10M (5%) -> Duration(10 days) -> 0.029$ per Token in BNB -> Min 5000$ / Max 15000$ -> 10% TGE + 1 Month Cliff + 3.75% monthly for 2 years
2. Public Sale1 - 15M (7.5%) -> Duration(14 days) -> 0.040$ per Token in BNB -> Min 50$ / Max 5000$  -> 10% TGE + 10 Days Cliff + 1% daily release in 90 days
3. Public Sale2 - 25M (12.5%) -> Duration(14 days) -> 0.067$ per Token in BNB -> Min 50$ / Max 5000$ -> 10% TGE + 10 Days Cliff + 1% daily release in 90 days
4. CEX Listing - 5M (2,5%) -> Market Making and list at 0.10$ USD per Token!
5. DEX Listing - 10M (5%) -> Initial Liquidity for CZIX/BNB Pair on Pancakeswap
6. CZIX Staking - 73M (36.5%) -> 36 Months of rewards -> 2.027.778 CZIX / month -> locking staked for 30 days
7. CZIX Airdrop - 10M (5%) -> 5 years of 166,667 CZIX released monthly
8. Philantropy - 2M (1%) -> 55.556 CZIX released monthly -> Controlled by centralized voting mechanism
9. Marketing - 14M (7%) -> 311.111 CZIX released monthyl -> 20% TGE -> 2.22% released monthly for 3 years
10. Development - 20M (10%) -> 444.444 CZIX released monthly -> 20% TGE -> 2.22% released monthly for 3 years
10. Advisors - 6M (3%) -> 133.333 CZIX released monthly -> 20% TGE-> 2.22% released monthly for 3 years
11. Reserve - 10M (5%) -> Emergency Fund

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