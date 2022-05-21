module.exports = async ({getNamedAccounts, deployments}) => {
  const {log} = deployments;
  const BTCLPMetaGamePass = await ethers.getContract('BTCLPMetaGamePass');
  const BTCLPToken = await ethers.getContract('BTCLPToken');
  const NLLToken = await ethers.getContract('NLLToken');
  const TimeLock = await ethers.getContract('TimeLock');
  const BTCLPDailyNoLossLottery = await ethers.getContract('BTCLPDailyNoLossLottery');

  await (await NLLToken.setNoLossLotteries(BTCLPDailyNoLossLottery.address, true)).wait(1); // whitelist the No Loss Lottery to mint daily rewards
  await (await BTCLPMetaGamePass.transferOwnership(TimeLock.address)).wait(1);
  await (await BTCLPToken.transferOwnership(TimeLock.address)).wait(1); // whitelist the No Loss Lottery to mint daily rewards
  await (await NLLToken.transferOwnership(TimeLock.address)).wait(1); // whitelist the No Loss Lottery to mint daily rewards
  await (await BTCLPDailyNoLossLottery.transferOwnership(TimeLock.address)).wait(1);

  log(`08 - Transfer Ownerships to Timelock`);
  return true;
};
module.exports.tags = ['ownership'];
module.exports.dependencies = ['BTCLPMetaGamePass', 'BTCLPToken', 'NLLToken', 'TimeLock', 'BTCLPDailyNoLossLottery'];
module.exports.id = 'ownership';