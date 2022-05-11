const config = require('../config');

module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy, log} = deployments;
    const {deployer} = await getNamedAccounts();
    log("Deploying BTCLPMetaGamePass....");
    const nft = await deploy('BTCLPMetaGamePass', {
      from: deployer,
      args: [0], // add a future date in production
      log: true,
    });
    log(`03 - Deployed 'BTCLPMetaGamePass' at ${nft.address}`);
    return true;
};
module.exports.tags = ['BTCLPMetaGamePass'];
module.exports.id = 'BTCLPMetaGamePass';