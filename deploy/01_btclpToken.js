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
    await delegate(token.address, deployer);
    log(`01 - Delegated`);
    return true;
};
module.exports.tags = ['BTCLPToken'];
module.exports.id = 'BTCLPToken';

const delegate = async (governanceTokenAddress, delegatedAccount) => {
  const governanceToken = await ethers.getContractAt("BTCLPToken", governanceTokenAddress)
  const txResponse = await governanceToken.delegate(delegatedAccount);
  await txResponse.wait(1);
  console.log(`Checkpoints: ${await governanceToken.numCheckpoints(delegatedAccount)}`);
}