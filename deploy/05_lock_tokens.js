const config = require('../config');

const oneToken = ethers.BigNumber.from(10).pow(18);

module.exports = async ({getNamedAccounts, deployments}) => {
  const {deployer} = await getNamedAccounts();
  const btclpToken = await ethers.getContract('BTCLPToken');
  const timelockController = await ethers.getContract('TimeLock');
  const tokenLock = await ethers.getContract('TokenLock');

  // Transfer locked tokens to the tokenlock
  if((await tokenLock.lockedAmounts(timelockController.address)).eq(0)) {
    const lockedDAOTokens = oneToken.mul(config.LOCKED_DAO_TOKENS);
    await (await btclpToken.approve(tokenLock.address, lockedDAOTokens)).wait();
    await (await tokenLock.lock(timelockController.address, lockedDAOTokens)).wait();
  }

  // Transfer free tokens to the timelock controller
  const totalContributorTokens = oneToken.mul(config.TOTAL_CONTRIBUTOR_TOKENS);
  const balance = await btclpToken.balanceOf(deployer);
  if(balance.gt(totalContributorTokens)) {
    await (await btclpToken.transfer(timelockController.address, balance.sub(totalContributorTokens))).wait();
  }

  // Print out balances
  const daoBalance = await btclpToken.balanceOf(timelockController.address);
  console.log(`Token balances:`);
  console.log(`  DAO: ${daoBalance.div(oneToken).toString()}`);
  const contributorBalance = await btclpToken.balanceOf(deployer);
  console.log(`  Contributors: ${contributorBalance.div(oneToken).toString()}`);
  const airdropBalance = await btclpToken.balanceOf(btclpToken.address);
  console.log(`  Airdrop: ${airdropBalance.div(oneToken).toString()}`);
  const tokenlockBalance = await btclpToken.balanceOf(tokenLock.address);
  console.log(`  TokenLock: ${tokenlockBalance.div(oneToken).toString()}`);
  const lockedDaoBalance = await tokenLock.lockedAmounts(timelockController.address);
  console.log(`    DAO: ${lockedDaoBalance.div(oneToken).toString()}`);
  console.log(`    TOTAL: ${lockedDaoBalance.div(oneToken).toString()}`);
  const total = daoBalance.add(contributorBalance).add(airdropBalance).add(tokenlockBalance);
  console.log(`  TOTAL: ${total.div(oneToken).toString()}`);

  return true;
};
module.exports.tags = ['distribute'];
module.exports.dependencies = ['BTCLPToken', 'TimeLock', 'TokenLock'];
module.exports.id = 'distribute';