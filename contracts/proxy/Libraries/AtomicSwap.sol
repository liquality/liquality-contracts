// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./BeginSwap.sol";
import "./LibTransfer.sol";

contract AtomicSwap is BeginSwap {
    function execute(
        uint256 feeRate,
        address feeCollector,
        address swapper,
        bytes calldata data,
        address tokenIn,
        address tokenOut,
        uint256 sellAmount
    ) internal {
        validateMsgValue(tokenIn);

        uint256 fee;

        // Determine the swap type(fromToken or fromValue) and initiate swap.
        if (msg.value > 0) {
            // If it's a swap from value
            fee = beginFromValueSwap(swapper, sellAmount, feeRate, payable(feeCollector), data);
        } else {
            // If it's a swap from Token
            fee = beginFromTokenSwap(swapper, tokenIn, sellAmount, feeRate, feeCollector, data);
        }

        LiqualityProxySwapInfo memory swapInfo = LiqualityProxySwapInfo({
            swapper: swapper,
            user: msg.sender,
            fee: fee,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: sellAmount,
            amountOut: 0
        });

        emit LiqualityProxySwap(swapInfo);
    }
}
