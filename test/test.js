const { amount, tokenId, salt } = require("../scripts/constants");
const {
  approveToken,
  mintTokens,
  createTBAAndDeposit,
} = require("../scripts/helper");
const { deploy } = require("../scripts/deploy");
const { assert } = require("chai");

describe("Deployment and Yield Management", async function () {
  let contractOwner;
  let NFTFactory;
  let WETHTokenContract;
  let nftTokenContract;
  let yieldManager;
  let aWETHContract;
  let account;
  before(async function () {
    ({
      contractOwner,
      yieldManager,
      NFTFactory,
      WETHTokenContract,
      aWETHContract,
    } = await deploy());

    nftTokenContract = await NFTFactory.deploy();
    await nftTokenContract.deployed();
    console.log("NFT Contract deployed and minted:", nftTokenContract.address);

    // Mint and approve tokens

    await nftTokenContract.safeMint(contractOwner.address, tokenId);
    await WETHTokenContract.deposit({ value: amount });
    await approveToken(WETHTokenContract, yieldManager.address, amount);
    await approveToken(nftTokenContract, yieldManager.address, tokenId);
  });

  it("owner should have WETH balance & NFT ownership", async function () {
    assert.equal(
      await WETHTokenContract.balanceOf(contractOwner.address),
      amount
    );
    assert.equal(
      await nftTokenContract.ownerOf(tokenId),
      contractOwner.address
    );
  });

  it("should create TBA and deposit NFT & WETH", async function () {
    account = await createTBAAndDeposit(
      yieldManager,
      nftTokenContract.address,
      tokenId,
      salt,
      amount
    );
  });

  it("should alter WETH & aWETH balances after deposit", async function () {
    // Owner's WETH balance gets deposited into the strategy by the yield manager
    assert.equal(await WETHTokenContract.balanceOf(contractOwner.address), 0);
    // The TBA account gets aWETH on depositing WETH
    assert.equal(await aWETHContract.balanceOf(account), amount);
  });

  it("should transfer NFT ownership to the yield manager after deposit", async function () {
    // The NFT ownership gets transferred to the yield manager on depositing the NFT
    assert.equal(await nftTokenContract.ownerOf(tokenId), yieldManager.address);
  });

  it("should redeem yield", async function () {
    await yieldManager.redeemYield(
      nftTokenContract.address,
      tokenId,
      salt,
      amount
    );
  });

  it("should alter WETH & aWETH balances after redeem", async function () {
    // The aWETH gets redeemed for WETH
    assert.equal(await aWETHContract.balanceOf(account), 0);
    // Owner's WETH is added back to the account along with reward
    assert.isAbove(
      await WETHTokenContract.balanceOf(contractOwner.address),
      amount
    );
  });

  it("should transfer NFT ownership back to the user account after redeem", async function () {
    assert.equal(
      await nftTokenContract.ownerOf(tokenId),
      contractOwner.address
    );
  });
});
