// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./IProxyCommons.sol";

interface ILiqualityProxyAdapter is IProxyCommons {
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

    function swap(
        uint256 feeRate,
        address feeCollector,
        LiqualityProxySwapParams calldata swapParams
    ) external payable;
}
