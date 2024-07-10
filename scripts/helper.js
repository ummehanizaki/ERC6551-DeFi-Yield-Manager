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
  await yieldManager.deposit(nftAddress, tokenId, salt, amount);
  return await yieldManager.getTBA(nftAddress, tokenId, salt);
}

module.exports = {
  approveToken,
  createTBAAndDeposit,
};
