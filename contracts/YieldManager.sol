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
    address public immutable wethAddress;
    address public immutable aWethAddress;

    // Mapping from NFT contract address and token ID to the owner's address
    mapping(address => mapping(uint256 => address)) public nftOwners;

    event TBAInitialized(
        address indexed user,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 depositAmount,
        address tba
    );

    event YieldRedeemed(
        address indexed user,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 amount
    );

    constructor(
        address _registry,
        address _implementationAddress,
        address _aavePoolAddress,
        address _wethAddress,
        address _aWethAddress
    ) {
        registry = ERC6551Registry(_registry);
        implementationAddress = _implementationAddress;
        aavePool = IAavePool(_aavePoolAddress);
        wethAddress = _wethAddress;
        aWethAddress = _aWethAddress;
    }

    /**
     * @notice Deposits ERC-20 tokens (WETH) and initializes a Token Bound Account (TBA) for a given NFT.
     * @param nftContract The address of the NFT contract
     * @param tokenId The ID of the NFT token
     * @param salt A unique salt value for creating the TBA
     * @param depositAmount The amount of WETH to deposit
     * @return tba The address of the newly created TBA
     */
    function deposit(
        address nftContract,
        uint256 tokenId,
        bytes32 salt,
        uint256 depositAmount
    ) external returns (address tba) {
        tba = _createTBA(nftContract, tokenId, salt);
        IERC20(wethAddress).transferFrom(msg.sender, tba, depositAmount);
        _supplyToAavePool(tba, depositAmount);
        nftOwners[nftContract][tokenId] = msg.sender;

        emit TBAInitialized(
            msg.sender,
            nftContract,
            tokenId,
            depositAmount,
            tba
        );
    }

    /**
     * @notice Retrieves the address of the TBA for a specific NFT.
     * @param nftContract The address of the NFT token contract
     * @param tokenId The ID of the NFT token
     * @param salt A unique salt value for creating the TBA
     * @return tba The address of the TBA
     */
    function getTBA(
        address nftContract,
        uint256 tokenId,
        bytes32 salt
    ) public view returns (address tba) {
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
     * @param salt A unique salt value for creating the TBA
     * @param amount The amount of aWETH to redeem
     */
    function redeemYield(
        address nftContract,
        uint256 tokenId,
        bytes32 salt,
        uint256 amount
    ) external {
        require(
            nftOwners[nftContract][tokenId] == msg.sender,
            "Unauthorized: Caller is not the owner"
        );

        address tba = getTBA(nftContract, tokenId, salt);
        uint256 aWETHBalance = IERC20(aWethAddress).balanceOf(tba);

        ERC6551Account(payable(tba)).executeCall(
            address(aavePool),
            0,
            abi.encodeWithSignature(
                "withdraw(address,uint256,address)",
                wethAddress,
                aWETHBalance,
                msg.sender
            )
        );

        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        delete nftOwners[nftContract][tokenId];

        emit YieldRedeemed(msg.sender, nftContract, tokenId, amount);
    }

    /**
     * @notice Creates a new Token Bound Account (TBA) for a given NFT.
     * @param nftContract The address of the NFT token contract
     * @param tokenId The ID of the NFT token
     * @param salt A unique salt value for creating the TBA
     * @return tba The address of the newly created TBA
     */
    function _createTBA(
        address nftContract,
        uint256 tokenId,
        bytes32 salt
    ) internal returns (address tba) {
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        tba = registry.createAccount(
            implementationAddress,
            salt,
            block.chainid,
            nftContract,
            tokenId
        );
    }

    /**
     * @notice Supplies WETH to the Aave WETH lending pool
     * @param tba The TBA of the user
     * @param amount The amount of WETH to supply
     */
    function _supplyToAavePool(address tba, uint256 amount) internal {
        // Approve the Aave pool to spend the deposited WETH
        ERC6551Account(payable(tba)).executeCall(
            wethAddress,
            0,
            abi.encodeWithSignature(
                "approve(address,uint256)",
                address(aavePool),
                amount
            )
        );

        // Supply WETH to Aave pool from TBA
        ERC6551Account(payable(tba)).executeCall(
            address(aavePool),
            0,
            abi.encodeWithSignature(
                "supply(address,uint256,address,uint16)",
                wethAddress,
                amount,
                tba,
                0
            )
        );
    }
}
