// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC6551Account} from "./ERC6551Account.sol";
import {ERC6551Registry} from "./ERC6551Registry.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IAavePool.sol";

contract YieldManager is AccessControl {
    ERC6551Registry public immutable registry;
    address public immutable implementationAddress;
    IAavePool public immutable aavePool;
    address public immutable wethTokenAddress;
    address public immutable aWETHTokenAddress;

    // Mapping from NFT contract and token ID to the address of the owner
    mapping(address => mapping(uint256 => address)) public nftOwner;

    event TBAInitialized(
        address indexed user,
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        address tbaAddress
    );
    event YieldRedeemed(
        address indexed user,
        address nftContract,
        uint256 tokenId,
        uint256 amount
    );

    constructor(
        address _registry,
        address _implementationAddress,
        address _aavePoolAddress,
        address _wethTokenAddress,
        address _aWETHTokenAddress
    ) {
        registry = ERC6551Registry(_registry);
        implementationAddress = _implementationAddress;
        aavePool = IAavePool(_aavePoolAddress);
        wethTokenAddress = _wethTokenAddress;
        aWETHTokenAddress = _aWETHTokenAddress;
    }

    /**
     * @notice Deposits ERC-20 tokens and initializes a Token Bound Account (TBA) for a given NFT.
     * @param nftContract The address of the NFT contract
     * @param tokenId The ID of the NFT token
     * @param salt A unique salt value for creating the TBA
     * @param amount The amount of ERC-20 tokens to deposit
     * @return tbaAddress The address of the newly created TBA
     */
    function depositAndInitializeTBA(
        address nftContract,
        uint256 tokenId,
        bytes32 salt,
        uint256 amount
    ) external returns (address tbaAddress) {
        tbaAddress = _createTBA(nftContract, tokenId, salt);
        IERC20(wethTokenAddress).transferFrom(msg.sender, tbaAddress, amount);
        _supplyToAavePool(tbaAddress, amount);
        nftOwner[nftContract][tokenId] = msg.sender;

        emit TBAInitialized(
            msg.sender,
            nftContract,
            tokenId,
            amount,
            tbaAddress
        );
    }

    /**
     * @notice Gets the address of the Token Bound Account (TBA) for a specific NFT.
     * @param nftContract The address of the NFT token contract
     * @param tokenId The ID of the NFT token
     * @param salt A unique salt value for creating the TBA
     * @return tbaAddress The address of the TBA
     */
    function getTBAAddress(
        address nftContract,
        uint256 tokenId,
        bytes32 salt
    ) public view returns (address tbaAddress) {
        return
            registry.account(
                implementationAddress,
                salt,
                block.chainid,
                nftContract,
                tokenId
            );
    }

    /**
     * @notice Redeems a specified amount of aWETH from the TBA and withdraws WETH to the caller.
     * @param nftContract The address of the NFT token contract
     * @param tokenId The ID of the NFT token
     * @param salt A unique salt value for the TBA
     * @param amount The amount of aWETH to redeem
     */
    function redeemYield(
        address nftContract,
        uint256 tokenId,
        bytes32 salt,
        uint256 amount
    ) external {
        require(
            nftOwner[nftContract][tokenId] == msg.sender,
            "Unauthorized: Caller is not the owner"
        );
        address tbaAddress = getTBAAddress(nftContract, tokenId, salt);
        uint256 aWETHBalance = IERC20(aWETHTokenAddress).balanceOf(tbaAddress);

        _executeCall(
            tbaAddress,
            address(aavePool),
            abi.encodeWithSignature(
                "withdraw(address,uint256,address)",
                wethTokenAddress,
                aWETHBalance,
                msg.sender
            )
        );
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        nftOwner[nftContract][tokenId] == address(0);
        emit YieldRedeemed(msg.sender, nftContract, tokenId, amount);
    }

    /**
     * @notice Creates a new Token Bound Account (TBA) for a given NFT.
     * @param nftContract The address of the NFT token contract
     * @param tokenId The ID of the NFT token
     * @param salt A unique salt value for creating the TBA
     * @return tbaAddress The address of the newly created TBA
     */
    function _createTBA(
        address nftContract,
        uint256 tokenId,
        bytes32 salt
    ) internal returns (address) {
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        return
            registry.createAccount(
                implementationAddress,
                salt,
                block.chainid,
                nftContract,
                tokenId
            );
    }

    /**
     * @notice Supplies WETH to the Aave WETH lending pool
     * @param tbaAddress The TBA of the user
     * @param contractAddress The contract address to interact with
     * @param data The function data
     */
    function _executeCall(
        address tbaAddress,
        address contractAddress,
        bytes memory data
    ) internal {
        ERC6551Account(payable(tbaAddress)).executeCall(
            contractAddress,
            0,
            data
        );
    }

    /**
     * @notice Supplies WETH to the Aave WETH lending pool
     * @param tbaAddress The TBA of the user
     * @param amount The amount of tokens to transfer
     */
    function _supplyToAavePool(address tbaAddress, uint256 amount) internal {
        // Approve the Aave pool to spend the deposited WETH
        _executeCall(
            tbaAddress,
            address(wethTokenAddress),
            abi.encodeWithSignature(
                "approve(address,uint256)",
                address(aavePool),
                amount
            )
        );

        // Supply WETH to Aave pool from TBA
        _executeCall(
            tbaAddress,
            address(aavePool),
            abi.encodeWithSignature(
                "supply(address,uint256,address,uint16)",
                wethTokenAddress,
                amount,
                tbaAddress,
                0
            )
        );
    }
}
