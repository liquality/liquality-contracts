// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./BeginSwap.sol";
import "./EndSwap.sol";

/// @notice contains logic common to all full swap adapters.
contract FullSwap is BeginSwap, EndSwap {
    function execute(
        uint256 feeRate,
        address feeCollector,
        address target,
        bytes calldata data,
        address tokenIn,
        address tokenOut,
        uint256 sellAmount
    ) internal {
        validateMsgValue(tokenIn);

        uint256 fee;
        uint256 returnedAmount;

        // Determine the swap type(fromToken or fromValue) and initiate swap.
        if (msg.value > 0) {
            // If it's a swap from value
            fee = beginFromValueSwap(target, sellAmount, feeRate, payable(feeCollector), data);
            returnedAmount = handleReturnedToken(tokenOut);
        } else {
            // If it's a swap from Token
            fee = beginFromTokenSwap(target, tokenIn, sellAmount, feeRate, feeCollector, data);

            // handle returnedAmount
            if (isETH(tokenOut)) {
                returnedAmount = handleReturnedValue();
            } else {
                // If it's a swap to token
                returnedAmount = handleReturnedToken(tokenOut);
            }
        }

        LiqualityProxySwapInfo memory swapInfo = LiqualityProxySwapInfo({
            target: target,
            user: msg.sender,
            fee: fee,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: sellAmount,
            amountOut: returnedAmount
        });

        emit LiqualityProxySwap(swapInfo);
    }
}
