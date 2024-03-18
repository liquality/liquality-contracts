// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ISwapperAdapter {
    /// @param data the encoded data to be forwarded to the swapper
    function swap(address swapper, bytes calldata data) external payable;
}
