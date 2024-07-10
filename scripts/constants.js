const amount = 100000000000000;
const registryAddress = "0x000000006551c19487814612e58FE06813775758";
const chainId = 42161;
const tokenId = 1;
const salt =
  "0x0000000000000000000000000000000000000000000000000000000000000000";

const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const AaveLendingPool = "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2";
const aWETH = "0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8";

module.exports = {
  amount,
  AaveLendingPool,
  aWETH,
  WETH,
  registryAddress,
  chainId,
  tokenId,
  salt,
};
