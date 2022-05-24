// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Libraries/Adapter.sol";
import "../interfaces/ILiqualityProxyAdapter.sol";

contract LiqualityZeroXAdapter is ILiqualityProxyAdapter {
    /// @notice This works for ZeroX sellToUniswap.
    function swap(
        uint256 feeRate,
        address feeCollector,
        LiqualityProxySwapParams calldata swapParams
    ) external payable {
        // Determine the swap type(fromToken or fromValue) and initiate swap.
        bytes memory response;
        uint256 returnedAmount;
        if (Adapter.isSwapFromValue()) {
            // If it's a swap from value
            response = Adapter.beginFromValueSwap(swapParams.target, swapParams.data);
            returnedAmount = abi.decode(response, (uint256));
            Adapter.handleReturnedToken(swapParams.tokenOut, returnedAmount, feeRate, feeCollector);
        } else {
            // If it's a swap from Token
            response = Adapter.beginFromTokenSwap(
                swapParams.target,
                swapParams.tokenIn,
                swapParams.amountIn,
                swapParams.data
            );
            returnedAmount = abi.decode(response, (uint256));

            // handle returnedAmount
            if (Adapter.isSwapToValue(swapParams.tokenOut)) {
                Adapter.handleReturnedValue(returnedAmount, feeRate, payable(feeCollector));
            } else {
                // If it's a swap to token
                Adapter.handleReturnedToken(
                    swapParams.tokenOut,
                    returnedAmount,
                    feeRate,
                    feeCollector
                );
            }
        }

        LiqualityProxySwapInfo memory swapInfo = LiqualityProxySwapInfo({
            target: swapParams.target,
            user: msg.sender,
            feeRate: feeRate,
            tokenIn: swapParams.tokenIn,
            tokenOut: swapParams.tokenOut,
            amountIn: swapParams.amountIn,
            amountOut: returnedAmount
        });

        emit LiqualityProxySwap(swapInfo);
    }
}
