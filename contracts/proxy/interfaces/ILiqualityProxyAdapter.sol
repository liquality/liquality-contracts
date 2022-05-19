// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./ILiqualityProxySwapParams.sol";

interface ILiqualityProxyAdapter is ILiqualityProxySwapParams {
    /// @dev Emitted when a successful swap operation goes throuth the proxy.
    event LiqualityProxySwap(
        address indexed target,
        address indexed user,
        uint256 indexed feeRate,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @dev Swaps exact input for atleast X output
    function exactInputSwap(
        uint256 feeRate,
        address feeCollector,
        LiqualityProxySwapParams calldata swapParams
    ) external payable;

    /// @dev Swaps atmost X input for exact output
    ///  This usecase is different from exactInputSwap in that, here, unspent amountIn is returned to the user
    function exactOutputSwap(
        uint256 feeRate,
        address feeCollector,
        LiqualityProxySwapParams calldata swapParams
    ) external payable;
}
