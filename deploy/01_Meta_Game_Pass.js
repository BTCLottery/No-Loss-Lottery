const config = require('../config');

module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy, log} = deployments;
    const {deployer} = await getNamedAccounts();
    log("Deploying BTCLPMetaGamePass....");
    const BTCLPMetaGamePass = await deploy('BTCLPMetaGamePass', {
      from: deployer,
      args: [
        "1",                              // Timestamp starts now
        config.NLL_TREASURY_GNOSIS_SAFE,  // Gnosis Safe that holds in circulation 2.5B Tokens in a MultiSig Wallet
        "1000"                            // Opensea Royalties Basepoints
      ], 
      log: true,
    });
    log(`01 - Deployed 'BTCLPMetaGamePass' at ${BTCLPMetaGamePass.address}`);
    return true;
};
module.exports.tags = ['BTCLPMetaGamePass'];
module.exports.id = 'BTCLPMetaGamePass';