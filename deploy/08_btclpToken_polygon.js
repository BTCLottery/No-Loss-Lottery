module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy, log} = deployments;
    const {deployer} = await getNamedAccounts();
    const BTCLPToken = await deployments.get('BTCLPToken');
    const NLLToken = await deployments.get('NLLToken');
    log("Deploying BTCLPTokenPolygon....");
    const daoNLL = await deploy('BTCLPTokenPolygon', {
      from: deployer,
      args: [
        "Bitcoin Lottery Protocol",
        "BTCLP",
        "18",
        "0xb5505a6d998549090530911180f38aC5130101c6"
      ],
      log: true,
    });
    log(`08 - Deployed 'BTCLPTokenPolygon' at ${daoNLL.address}`);
    return true;
};
module.exports.tags = ['BTCLPTokenPolygon'];
module.exports.dependencies = ['BTCLPToken', 'NLLToken', 'TimeLock'];
module.exports.id = 'BTCLPTokenPolygon';