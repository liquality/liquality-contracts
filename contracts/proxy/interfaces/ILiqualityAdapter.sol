// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ILiqualityAdapter {
    /// @dev Swaps exact input for atleast X output
    function exactInput(
        address target,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 feeRate,
        address feeCollector,
        bytes calldata data
    ) external payable;

    /// @dev Swaps atmost X input for exact output
    function exactOutput(
        address target,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 feeRate,
        address feeCollector,
        bytes calldata data
    ) external payable;
}
