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
      args: [BTCLPToken.address, TimeLock.address],
      log: true,
    });
    // const governor = await ethers.getContract('ENSGovernor');
    log(`04 - Deployed 'BTCLPGovernor' at ${governor.address}`);
    await (await TimeLock.grantRole(await TimeLock.PROPOSER_ROLE(), governor.address)).wait();
    await (await TimeLock.revokeRole(await TimeLock.TIMELOCK_ADMIN_ROLE(), deployer)).wait();
    return true;
};
module.exports.tags = ['all', 'BTCLPGovernor'];
module.exports.dependencies = ['BTCLPToken', 'TimeLock'];
module.exports.id = 'BTCLPGovernor';