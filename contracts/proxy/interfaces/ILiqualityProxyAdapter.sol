// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

// import "./IProxyCommons.sol";

interface ILiqualityProxyAdapter {
    struct LiqualityProxySwapInfo {
        address target;
        address user;
        uint256 feeRate;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut;
    }

    /// @dev Emitted when a successful swap operation goes throuth the proxy.
    event LiqualityProxySwap(LiqualityProxySwapInfo swapInfo);

    function swap(
        uint256 feeRate,
        address feeCollector,
        address target,
        bytes calldata swapParams
    ) external payable;
}
