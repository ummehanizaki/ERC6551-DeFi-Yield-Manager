const { ethers } = require("hardhat");
const {
  AaveLendingPool,
  aWETH,
  WETH,
  registryAddress,
} = require("./constants");

async function deploy() {
  try {
    const [contractOwner] = await ethers.getSigners();
    console.log("Contract Owner:", contractOwner.address);

    // Fetch contracts
    const [
      registry,
      ERC6551AccountFactory,
      YieldManager,
      NFTFactory,
      WETHTokenContract,
      aWETHContract,
    ] = await Promise.all([
      ethers.getContractAt("ERC6551Registry", registryAddress),
      ethers.getContractFactory("ERC6551Account"),
      ethers.getContractFactory("YieldManager"),
      ethers.getContractFactory("NFT"),
      ethers.getContractAt("WETH", WETH),
      ethers.getContractAt("WETH", aWETH),
    ]);

    // Deploy ERC6551Account
    const erc6551Account = await ERC6551AccountFactory.deploy();
    await erc6551Account.deployed();
    console.log("ERC6551Account deployed:", erc6551Account.address);

    // Deploy YieldManager
    const yieldManager = await YieldManager.deploy(
      registry.address,
      erc6551Account.address,
      AaveLendingPool,
      WETH,
      aWETH
    );
    await yieldManager.deployed();
    console.log("YieldManager deployed:", yieldManager.address);

    // Return deployed contracts
    return {
      contractOwner,
      registry,
      erc6551Account,
      yieldManager,
      NFTFactory,
      WETHTokenContract,
      aWETHContract,
    };
  } catch (error) {
    console.error("Deployment failed:", error);
    process.exit(1);
  }
}

if (require.main === module) {
  deploy();
}

exports.deploy = deploy;
