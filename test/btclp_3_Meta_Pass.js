const chai = require("chai");
const { network, ethers } = require("hardhat");
const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { solidity } = require("ethereum-waffle");
chai.use(solidity);
const { expect } = require("chai");
const toWei = (amount) => ethers.utils.parseEther(amount)
const fromWei = (amount) => ethers.utils.formatEther(amount)

const minter = ethers.utils.getAddress("0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266");
const wallet = ethers.utils.getAddress("0x70997970c51812dc3a010c7d01b50e0d17dc79c8");

describe("BTCLPMetaGamePass", function () {
  before(async () => {
    const NFTDAO = await ethers.getContractFactory("BTCLPMetaGamePass");
    this.dao = await NFTDAO.deploy();
    await this.dao.deployed();

    await network.provider.request({ method: "hardhat_impersonateAccount",  params: [minter] });
    await network.provider.send("hardhat_setBalance", [minter, "0x4563918244F4000000"]); // 1280 BNB
    this.signer = await ethers.provider.getSigner(minter);
    
    const provider = new ethers.providers.JsonRpcProvider("http://localhost:8545");
    await provider.send("hardhat_impersonateAccount", [wallet]);
    await network.provider.request({ method: "hardhat_impersonateAccount", params: [wallet] });
    await network.provider.send("hardhat_setBalance", [minter, "0x4563918244F40000000"]); // 1280 BNB
    this.signerWallet = await provider.getSigner(wallet);
  });

  it("should check creator balance for collection1", async () => {
    expect(await this.dao.balanceOf(minter, 1)).to.equal(10000, "Creator should initially have all 10K NFTs from COLLECTION1")
})

it("should transfer 10 NFTs from collection1 to another address", async () => {
    const transfer = await this.dao.safeTransferFrom(
        minter, // from
        wallet, // to
        1, // collection id
        10, // amount
        "0x00", // data
    );
    transfer.wait();

    expect(await this.dao.balanceOf(wallet, 1)).to.equal(10, "Wallet should have 10 NFTs from COLLECTION1")
  })
  
});