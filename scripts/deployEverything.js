const hre = require("hardhat");

async function main() {
  const block = await hre.ethers.provider.getBlock("latest");
  const openingTime = Math.floor(block.timestamp) + 1 // now + 1 hour = 3600
  
  // We deploy the BTCLP Governance Token
  const BTCLPToken = await hre.ethers.getContractFactory("BTCLPToken");
  const btclp = await BTCLPToken.deploy(openingTime);
  await btclp.deployed();
  console.log("BTCLPToken deployed to:", btclp.address);

  // We deploy the NLL Utility Token
  const NLLToken = await hre.ethers.getContractFactory("NLLToken");
  const nll = await NLLToken.deploy(openingTime);
  await nll.deployed();
  console.log("NLLToken deployed to:", nll.address);

  // We deploy Meta Game Passes
  const BTCLPMetaGamePass = await hre.ethers.getContractFactory("BTCLPMetaGamePass");
  const gamepass = await BTCLPMetaGamePass.deploy(openingTime);
  await gamepass.deployed();
  console.log("BTCLPMetaGamePass deployed to:", gamepass.address);

  // We deploy the Governor Contract
  // We deploy the Timelock Contract
  // We deploy the Token No Loss Lottery
  // We deploy the NFTs No Loss Lottery
}

// This pattern enables async/await everywhere and properly handles errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});