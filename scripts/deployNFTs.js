const hre = require("hardhat");

async function main() {
  // We get the contract to deploy
  const BTCLPMetaGamePassRoyalties = await hre.ethers.getContractFactory("BTCLPMetaGamePass");
  const gamepass = await BTCLPMetaGamePassRoyalties.deploy();
  await gamepass.deployed();

  console.log("BTCLPMetaGamePassRoyalties deployed to:", gamepass.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
