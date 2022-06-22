// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./BeginSwap.sol";
import "./LibTransfer.sol";

contract AtomicSwap is BeginSwap {
    function execute(
        address swapper,
        bytes calldata data,
        address tokenIn,
        address tokenOut,
        uint256 sellAmount
    ) internal {
        validateMsgValue(tokenIn);

        // Determine the swap type(fromToken or fromValue) and initiate swap.
        if (msg.value > 0) {
            // If it's a swap from value
            beginFromValueSwap(swapper, sellAmount, data);
        } else {
            // If it's a swap from Token
            beginFromTokenSwap(swapper, tokenIn, sellAmount, data);
        }

        LiqualityProxySwapInfo memory swapInfo = LiqualityProxySwapInfo({
            swapper: swapper,
            user: msg.sender,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: sellAmount,
            amountOut: 0
        });

        emit LiqualityProxySwap(swapInfo);
    }
}
