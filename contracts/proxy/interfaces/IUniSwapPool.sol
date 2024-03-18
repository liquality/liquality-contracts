// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface IUniSwapPool {
    function token0() external view returns (address);

    function token1() external view returns (address);
}
