const config = require('../config');

module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy, log} = deployments;
    const {deployer} = await getNamedAccounts();
    log("Deploying BTCLPMetaGamePass....");
    const nft = await deploy('BTCLPMetaGamePass', {
      from: deployer,
      args: [
        "1",                                          // timestamp
        "0xe6F7C7caF678A3B7aFb93891907873E88F4FD4AC", // gnosis safe
        "750"                                         // royalties basepoints
      ], 
      log: true,
    });
    log(`04 - Deployed 'BTCLPMetaGamePass' at ${nft.address}`);
    return true;
};
module.exports.tags = ['BTCLPMetaGamePass'];
module.exports.id = 'BTCLPMetaGamePass';