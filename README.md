# DeFi Yield Manager using ERC6551

The DeFi Yield Manager is a system designed to generate yield on ERC-20 tokens while securely managing deposited NFTs. Users contribute both tokens and NFTs, which are stored in a secure Token Bound Account (TBA) based on the ERC-6551 standard. The TBA interacts with a DeFi lending service, such as Aave, which acts as a lending pool for the tokens and generates interest over time. Users can redeem their assets at any time, receiving their original NFT along with aWETH tokens that represent the accrued interest on the initial deposit. This system leverages NFTs to securely earn interest on tokens through DeFi lending platforms.

## Installation

To get started with the DeFi Yield Manager, follow these steps:

1. Clone the repository:

```console
git clone git@github.com:ummehanizaki/ERC6551-Implementation.git
```

2. Navigate to the project directory and install the necessary NPM packages::

```console
cd ERC6551-Implementation
npm install
```

## Running Tests

To ensure the functionality of various components, run the following command:

```console
npx hardhat test
```

### Testing Overview

This command executes unit tests to verify the functionality of the following components:

- Initial user balances & NFT ownership: Checks ERC-20 token and NFT ownership before the deposit.
- TBA creation and deposit: Validates the creation of the Token Bound Account and token deposits.
- Balance changes: Verifies the changes in balances after deposit and interaction with DeFi services.
- NFT ownership transfer: Ensures correct NFT ownership during deposit and redemption processes.
- Yield redemption: Confirms the process of redeeming yield and transferring NFT ownership back to the user.

## Deployment

Deploy the contracts using the following command:

```console
npx hardhat run scripts/deploy.js
```

### Deployment Overview
+ `ERC6551AccountFactory`: Deployed to handle the creation of ERC-6551 compliant accounts. This contract contains the bytecode and logic required for TBA creation.
+ `ERC6551Registry`: Utilizes an existing deployment of the ERC6551Registry to save on deployment costs. This address remains constant and is used in deploying the YieldManager.
+ `YieldManager`: Deployed to manage interactions with DeFi services like Aave. It handles token deposits into the lending pool and yield redemption processes.
