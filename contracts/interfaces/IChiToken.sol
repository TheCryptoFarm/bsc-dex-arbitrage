// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChiToken {
    function free(uint256 value) external returns (bool success);
    function freeUpTo(uint256 value) external returns (uint256 freed);
    function freeFrom(address from, uint256 value) external returns (bool success);
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
    function mint(uint256 value) external;
}
