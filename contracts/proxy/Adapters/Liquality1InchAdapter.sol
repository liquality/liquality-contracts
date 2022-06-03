// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Libraries/Adapter.sol";
import "../interfaces/ILiqualityProxyAdapter.sol";
import "../LibTransfer.sol";

contract Liquality1InchAdapter is ILiqualityProxyAdapter {
    using LibTransfer for address payable;
    using SafeERC20 for IERC20;

    /// @notice This works for AggregationRouterV4
    function swap(
        uint256 feeRate,
        address feeCollector,
        LiqualityProxySwapParams calldata swapParams
    ) external payable {
        // Determine the swap type(fromToken or fromValue) and initiate swap.
        bytes memory response;
        uint256 returnedAmount;
        uint256 spentAmount;
        if (Adapter.isSwapFromValue()) {
            // If it's a swap from value
            response = Adapter.beginFromValueSwap(swapParams.target, swapParams.data);
            (returnedAmount, spentAmount, ) = abi.decode(response, (uint256, uint256, uint256));
            Adapter.handleReturnedToken(swapParams.tokenOut, returnedAmount, feeRate, feeCollector);

            // Return unspent value to user
            if (spentAmount < swapParams.amountIn) {
                payable(msg.sender).transferEth(swapParams.amountIn - spentAmount);
            }
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

            // Return unspent token to user
            if (spentAmount < swapParams.amountIn) {
                IERC20(swapParams.tokenIn).safeTransfer(
                    msg.sender,
                    swapParams.amountIn - spentAmount
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
