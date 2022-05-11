const config = require('../config');

module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy, log} = deployments;
    const {deployer} = await getNamedAccounts();
    log("Deploying BTCLPToken....");
    const token = await deploy('BTCLPToken', {
      from: deployer,
      args: [],
      log: true,
    });
    log(`01 - Deployed 'BTCLPToken' at ${token.address}`);
    return true;
};
module.exports.tags = ['BTCLPToken'];
module.exports.id = 'BTCLPToken';