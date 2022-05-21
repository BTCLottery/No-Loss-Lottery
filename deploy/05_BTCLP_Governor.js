const { ethers } = require('hardhat');
const config = require('../config');

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy, log} = deployments;
    const {deployer} = await getNamedAccounts();
    const BTCLPToken = await ethers.getContract('BTCLPToken');
    const TimeLock = await ethers.getContract('TimeLock');
    
    log("Deploying BTCLPGovernor....");
    const governor = await deploy('BTCLPGovernor', {
      from: deployer,
      args: [
        BTCLPToken.address, 
        TimeLock.address,
        config.VOTING_DELAY,
        config.VOTING_PERIOD,
        config.VOTING_MIN_POWER,
        config.VOTING_PERCENTAGE,
      ],
      log: true,
    });
    log(`05 - Deployed 'BTCLPGovernor' at ${governor.address}`);
    await (await TimeLock.grantRole(await TimeLock.PROPOSER_ROLE(), governor.address)).wait(1);
    await (await TimeLock.grantRole(await TimeLock.EXECUTOR_ROLE(), ZERO_ADDRESS)).wait(1);
    await (await TimeLock.revokeRole(await TimeLock.TIMELOCK_ADMIN_ROLE(), deployer)).wait(1);
    log(`05 - ALL DAO PROPOSALS GO THROUGH THE GOVERNOR CONTRACT. Anyone can have the EXECUTOR_ROLE. The deployer renounces ownership of the TIMELOCK_ADMIN_ROLE.`);
    return true;
};
module.exports.tags = ['BTCLPGovernor'];
module.exports.dependencies = ['BTCLPToken', 'TimeLock'];
module.exports.id = 'BTCLPGovernor';
