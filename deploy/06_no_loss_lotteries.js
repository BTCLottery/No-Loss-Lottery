module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy, log} = deployments;
    const {deployer} = await getNamedAccounts();
    const BTCLPToken = await deployments.get('BTCLPToken');
    const NLLToken = await deployments.get('NLLToken');
    log("Deploying BTCLPDailyNoLossLotteryTokens....");
    const daoNLL = await deploy('BTCLPDailyNoLossLotteryTokens', {
      from: deployer,
      args: [
        BTCLPToken.address,
        NLLToken.address,
      ],
      log: true,
    });
    log(`06 - Deployed 'BTCLPDailyNoLossLotteryTokens' at ${daoNLL.address}`);
    return true;
};
module.exports.tags = ['BTCLPDailyNoLossLotteryTokens'];
module.exports.dependencies = ['BTCLPToken', 'NLLToken', 'TimeLock'];
module.exports.id = 'BTCLPDailyNoLossLotteryTokens';