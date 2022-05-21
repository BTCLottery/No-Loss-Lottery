const config = require('../config');

module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy, log} = deployments;
    const {deployer} = await getNamedAccounts();
    const BTCLPMetaGamePass = await deployments.get('BTCLPMetaGamePass');
    const BTCLPToken = await deployments.get('BTCLPToken');
    const NLLToken = await deployments.get('NLLToken');
    log("Deploying BTCLPDailyNoLossLottery....");
    const BTCLPDailyNoLossLottery = await deploy('BTCLPDailyNoLossLottery', {
      from: deployer,
      args: [
        BTCLPToken.address,
        NLLToken.address,
        BTCLPMetaGamePass.address,
        config.NLL_TREASURY_GNOSIS_SAFE
      ],
      log: true,
    });
    log(`04 - Deployed 'BTCLPDailyNoLossLottery' at ${BTCLPDailyNoLossLottery.address}`);
    return true;
};
module.exports.tags = ['BTCLPDailyNoLossLottery'];
module.exports.dependencies = ['BTCLPToken', 'NLLToken', 'BTCLPMetaGamePass'];
module.exports.id = 'BTCLPDailyNoLossLottery';