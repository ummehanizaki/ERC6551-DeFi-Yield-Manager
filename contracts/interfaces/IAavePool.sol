// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAavePool {
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(address asset, uint256 amount, address to) external;

    function balanceOf(address owner) external view returns (uint256);
}
