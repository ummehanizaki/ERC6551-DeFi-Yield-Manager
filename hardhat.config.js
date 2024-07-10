require("@nomiclabs/hardhat-waffle");
require("dotenv").config({ path: ".env" });
require("@nomiclabs/hardhat-etherscan");

const SEPOLIA_API_KEY_URL = "https://eth.merkle.io";

const PRIVATE_KEY = process.env.PRIVATE_KEY;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

module.exports = {
  solidity: {
    compilers: [{ version: "0.8.20" }],
  },
  networks: {
    hardhat: {
      forking: {
        url: SEPOLIA_API_KEY_URL,
        accounts: [PRIVATE_KEY],
        enabled: true,
        chainId: 12345,
        blockNumber: 20135534,
      },
    },
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.ETHERSCAN_API_KEY,
    },
  },
  lockGasLimit: 200000000000,
  gasPrice: 10000000000,
};
