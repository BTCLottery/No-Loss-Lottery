const chai = require("chai");
const { network, ethers } = require("hardhat");
const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { solidity } = require("ethereum-waffle");
chai.use(solidity);
const { expect } = require("chai");
const toWei = (amount) => ethers.utils.parseEther(amount)
const fromWei = (amount) => ethers.utils.formatEther(amount)

const minter = ethers.utils.getAddress("0xd1E006022f11a1878b391b92A69Df1F0741F6a92");
const wallet = ethers.utils.getAddress("0x63625Cfd44F4a29013D30F1ba02Ca69c1976b7da");

describe("BTCLP_NLLV2", function () {
  beforeEach(async () => {
    const [deployer, player] = await ethers.getSigners();    
    const BTCLPToken = await ethers.getContractAt("BTCLPToken", "0x551b7377F547765502c323b50442e0A8581Db643");
    const NLLToken = await ethers.getContractAt("NLLToken", "0x6b70e4966e66AAafA9956Ed19B38A6c5dae4FC56");
    const NLLLotteryV2 = await ethers.getContractAt("BTCLPDailyNoLossLotteryV2.sol", "0x0161C8890eC9E71D9E9a303a3C6b726e5ca815ee");
    console.log('deployer', deployer.address);
    console.log('player', player.address);
    console.log('BTCLPToken', BTCLPToken.address);
    console.log('NLLToken', NLLToken.address);
    console.log('NLLLotteryV2', NLLLotteryV2.address);
    console.log('subscriptionId', await this.noLossLotteryV2.subscriptionId());
  });
  
  it("should check if token has correct values", async () => {
    console.log('wtf merge ?')
    expect(await this.btclp.name()).to.equal('Bitcoin Lottery Protocol', "Token name is not correct")
    expect(await this.btclp.symbol()).to.equal('BTCLP', "Token symbol is not correct")
    expect(await this.btclp.decimals()).to.equal(18, "Token decimals is not correct")
    expect(await this.btclp.balanceOf(minter)).to.equal(await this.btclp.totalSupply(), "Owner should own all 10B BTCLP Tokens")
  })

});