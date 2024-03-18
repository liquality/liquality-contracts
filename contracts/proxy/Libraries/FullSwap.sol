// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./BeginSwap.sol";
import "./EndSwap.sol";

/// @notice contains logic common to all full swap adapters.
contract FullSwap is BeginSwap, EndSwap {
    function execute(
        address swapper,
        bytes calldata data,
        address tokenIn,
        address tokenOut,
        uint256 sellAmount
    ) internal {
        validateMsgValue(tokenIn);

        uint256 returnedAmount;

        // Determine the swap type(fromToken or fromValue) and initiate swap.
        if (msg.value > 0) {
            // If it's a swap from value
            beginFromValueSwap(swapper, sellAmount, data);
            returnedAmount = handleReturnedToken(tokenOut);
        } else {
            // If it's a swap from Token
            beginFromTokenSwap(swapper, tokenIn, sellAmount, data);

            // handle returnedAmount
            if (isETH(tokenOut)) {
                returnedAmount = handleReturnedValue();
            } else {
                // If it's a swap to token
                returnedAmount = handleReturnedToken(tokenOut);
            }
        }

        LiqualityProxySwapInfo memory swapInfo = LiqualityProxySwapInfo({
            swapper: swapper,
            user: msg.sender,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: sellAmount,
            amountOut: returnedAmount
        });

        emit LiqualityProxySwap(swapInfo);
    }
}