# BTCLP No Loss Lottery Contracts

The Bitcoin Lottery Protocol DAO Launchpad uses Chainlink VRF V2 and Chainlink Keepers to ensure a daily draw for 2 No Loss Lotteries.
The No Loss Lottery is a Random Deflationary Distribution Model that rewards BTCLP and NLL Tokens

THERE ARE 3 TOKEN TYPES:
1. BTCLP Token = Governance + Utility => you can reclaim all deposits at the end of the game + winnings hopefully
2. NLL Token = Utility => 1 NLL Token = 1 Ticket => The NLL Token is burned after it is used
3. 6K NFTs = 3 Types (3K COMMON/2K EPIC/1K LEGENDARY) with 3 different categories of features.

THERE ARE 2 LOTTERY TYPES:
1. The 6K NFTs hodlers have a daily chance to win BTCLP Governance Tokens just by hodling.
2. BTCLP Tokens and NLL Tokens are used to purchase tickets in the Daily No Loss Lottery. 

TOKEN FEATURES:
1. BTCLP Governance Token is prevalued and made in circulation
2. NLL Utility Token is non-transferable and only works inside the No Loss Lottery, it's basically 1 free ticket.

HOW THE NO LOSS LOTTERY WORKS:
1. At the end of the daily draw, BTCLP and NLL reward are distributed to 10 lucky winners.
2. For BTCLP Tokens the same reward amount that is given to the 10 winners is also burned at the same time thus making it deflationary. 
3. NLL Tokens are also rewarded to the 10 lucky winners. NLL Tokens are burned when purchase 1 ticket in the daily token no loss lottery.


STEPS TO-DO SMART CONTRACTS:
1. BTCLP Token
1.1. Need to create a Treasury
1.2. Need to create a Timelock
1.3. Need to create a Governor
1.4. Create tests
1.5. Create the deployment and verify contracts

2. NLL Token
1.1. We need to deploy the No Loss Lottery first
1.2. We need to whitelisting the No Loss Lottery Address
1.3. We need to transfer ownership of the NLL Token to the No Loss Lottery

<!-- 328.000 BTCLP Tokens Daily Reward -->
3. The No Loss Lottery - BTCLP & NLL Tokens only --- 100K BTCLP Tokens and 1000 NLL reward daily and burn equal amount
3.1. We need to create a Gnosis MultiSig Wallet for the Treasury of the No Loss Lottery
3.2. We need to approve the full amount to the No Loss Lottery
3.3. We need to add inside the No Loss Lottery a transferFrom function from the Treasury
3.4. We need to recheck all values and recalculate all emissions to match 10+ years
3.5. We need to add a Daily,Weekly,Monthly reward mechanism (26 days of daily rewards / 3 days of x2 Weekly Rewards / 1 day of x3 Monthly Rewards)
3.6. Create a deflationary reward mechanism
3.7. Add a mechanism to stop playing and upgrade to a newer No Loss Lottery V3 or V4 version in the future
3.8. Create a few tests
3.9. Create the deployment and verify contracts

<!-- 40% to NFT Holders and 60% to Tokens -->
4. The No Loss Lottery - NFT Tokens only
4.1. We need to create a Gnosis MultiSig Wallet for the Treasury of the No Loss Lottery
4.2. We need to approve the full amount to the No Loss Lottery
4.3. We need to add inside the No Loss Lottery a transferFrom function from the Treasury
4.4. We need to recheck all values and recalculate all emissions to match 10+ years
4.5. Create a few tests
4.6. Create the deployment and verify contracts

5. NFT Meta Game Pass
5.1. Move from IPFS to Arweave
5.2. Replace GIFs with MP4
5.3. Add more attributes to the metadata

STEPS TO-DO ON FRONTEND
1. Add Non-Custodial Wallets using Blocknative
2. Do the frontend minting part for NFTs
3. Do the No Loss Lottery for Tokens
4. Do the No Loss Lottery for NFTs
EXTRA
5. Voting Governance Mechanisms
6. Staking
7. Yield Farming

# Ethereum & Polygon & Bscscan verification
This project demonstrates and covers tools commonly used alongside Hardhat in the ecosystem while doing all tests on a local Fork. In this project, copy the .env.example file to a file named .env, and then edit it to fill in the details. 
Enter your Bscscan API key or Etherscan API key or Polygonscan API key, your archive node URL (eg from Moralis), and the private key or mnemonic of the account which will send the deployment transaction. 
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
