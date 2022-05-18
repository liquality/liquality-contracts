// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ILiqualityProxyEvent {
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
}
