async function approveToken(tokenContract, spenderAddress, amount) {
  await tokenContract.approve(spenderAddress, amount);
}

async function createTBAAndDeposit(
  yieldManager,
  nftAddress,
  tokenId,
  salt,
  amount
) {
  await yieldManager.depositAndInitializeTBA(nftAddress, tokenId, salt, amount);
  return await yieldManager.getTBAAddress(nftAddress, tokenId, salt);
}

module.exports = {
  approveToken,
  createTBAAndDeposit,
};
