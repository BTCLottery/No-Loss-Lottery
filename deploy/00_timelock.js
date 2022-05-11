const config = require('../config');

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy, log} = deployments;
    const {deployer} = await getNamedAccounts();
    log("Deploying TimeLock....");
    const timelock = await deploy('TimeLock', {
      from: deployer,
      args: [config.MIN_TIMELOCK_DELAY, [], [ZERO_ADDRESS]],
      log: true,
    });
    log(`00 - Deployed 'TimeLock' at ${timelock.address}`);
    return true;
};
module.exports.tags = ['TimeLock'];
module.exports.id = 'TimeLock';