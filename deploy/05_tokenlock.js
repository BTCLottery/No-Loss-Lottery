const config = require('../config');

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy, log} = deployments;
    const {deployer} = await getNamedAccounts();
    const BTCLPToken = await deployments.get('BTCLPToken');
    log("Deploying TokenLock....");
    const tokenlock = await deploy('TokenLock', {
      from: deployer,
      args: [
        BTCLPToken.address, 
        Math.floor(new Date(config.UNLOCK_BEGIN).getTime() / 1000),
        Math.floor(new Date(config.UNLOCK_CLIFF).getTime() / 1000),
        Math.floor(new Date(config.UNLOCK_END).getTime() / 1000),
      ],
      log: true,
    });
    log(`05 - Deployed 'TokenLock' at ${tokenlock.address}`);
    return true;
};
module.exports.tags = ['TokenLock'];
module.exports.dependencies = ['BTCLPToken', 'TimeLock'];
module.exports.id = 'TokenLock';