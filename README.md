# BTCLP No Loss Lottery Contracts

The Bitcoin Lottery Protocol DAO Launchpad uses Chainlink VRF V2 and Chainlink Keepers to ensure a daily draw for 2 No Loss Lotteries.
The No Loss Lottery is a Random Deflationary Distribution Model that rewards BTCLP and NLL Tokens

THERE ARE 3 TOKEN TYPES:
1. BTCLP Token = Governance + Utility => you can reclaim all deposits at the end of the game + winnings hopefully
2. NLL Token = Utility => 1 NLL Token = 1 Ticket => The NLL Token is burned after it is used
3. 6K NFTs = 3 Types (3K COMMON/2K EPIC/1K LEGENDARY) with 3 different categories of features.

THERE ARE 2 LOTTERY TYPES:
1. The 6K NFTs hodlers have a daily chance to win BTCLP Governance Tokens just by hodling.
2. BTCLP Tokens and NLL Tokens are used to purchase tickets. At the end of the daily draw, a reward is given to 10 lucky winners and the exact reward amount is also burned at the same time.

TOKEN FEATURES:
BTCLP Token is prevalued and made in circulation
NLL Token is non-transferable and only works inside the No Loss Lottery, it's like 1 free ticket.

# Bscscan verification
This project demonstrates and covers tools commonly used alongside Hardhat in the ecosystem while doing all tests on a local Binance Smart Chain Mainnet Fork. In this project, copy the .env.example file to a file named .env, and then edit it to fill in the details. 
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
