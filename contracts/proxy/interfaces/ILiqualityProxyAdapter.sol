// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ILiqualityProxyAdapter {
    /// @dev Emitted when swap params are invalid.
    error LiqProxy__InvalidSwap();

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

    /// @param feeRate An int expression for the actual "rate in percentage".
    /// 5% (i.e 5/100) becomes as 20. So fee equals amount/20 in this case
    /// @param data the encoded data to be forwarded to the target swapper
    function swap(
        uint256 feeRate,
        address feeCollector,
        address target,
        bytes calldata data
    ) external payable;
}
