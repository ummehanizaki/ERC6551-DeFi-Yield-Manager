// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./interfaces/IERC6551Account.sol";
import "./interfaces/ERC6551Bytecode.sol";

contract ERC6551Account is IERC165, IERC1271, IERC6551Account {
    using SafeERC20 for IERC20;
    uint256 public nonce;

    receive() external payable {}

    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory result) {
        require(msg.sender == owner(), "Not token owner");
        bool success;
        (success, result) = to.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function send(address payable to, uint256 amount) external payable {
        require(msg.sender == owner(), "Not token owner");
        require(address(this).balance >= amount, "Insufficient funds");
        to.transfer(amount);
    }

    function sendCustom(
        address to,
        uint256 amount,
        IERC20 erc20contract
    ) external {
        require(msg.sender == owner(), "Not token owner");
        uint256 balance = erc20contract.balanceOf(address(this));
        require(balance >= amount, "Insufficient funds");
        erc20contract.transfer(to, amount);
    }

    function nftInfo()
        external
        view
        returns (uint256 chainId, address tokenContract, uint256 tokenId)
    {
        uint256 length = address(this).code.length;
        return
            abi.decode(
                Bytecode.codeAt(address(this), length - 0x60, length),
                (uint256, address, uint256)
            );
    }

    function owner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = this
            .nftInfo();
        if (chainId != block.chainid) return address(0);
        return IERC721(tokenContract).ownerOf(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return (interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC6551Account).interfaceId);
    }

    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) external view returns (bytes4 signValues) {
        bool isValid = SignatureChecker.isValidSignatureNow(
            owner(),
            hash,
            signature
        );
        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }
        return "";
    }
}
