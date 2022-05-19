// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Libraries/Adapter.sol";
import "../interfaces/ILiqualityProxyAdapter.sol";

contract LiqualityZeroXAdapter is ILiqualityProxyAdapter {
    /// @notice This works for ZeroX sellToUniswap.
    function exactInputSwap(
        uint256 feeRate,
        address feeCollector,
        LiqualityProxySwapParams calldata swapParams
    ) external payable {
        // Determine the swap type(fromToken or fromValue) and initiate swap.
        bytes memory response;
        if (Adapter.isSwapFromValue(swapParams.tokenIn)) {
            // If it's a swap from value
            response = Adapter.beginFromValueSwap(swapParams.target, swapParams.data);
        } else {
            // If it's a swap from Token
            response = Adapter.beginFromTokenSwap(
                swapParams.target,
                swapParams.tokenIn,
                swapParams.amountIn,
                swapParams.data
            );
        }
        uint256 returnedAmount = abi.decode(response, (uint256));

        // handle returnedAmount
        if (Adapter.isSwapToValue(swapParams.tokenOut)) {
            Adapter.handleReturnedValue(returnedAmount, feeRate, payable(feeCollector));
        } else {
            // If it's a swap to token
            Adapter.handleReturnedToken(swapParams.tokenOut, returnedAmount, feeRate, feeCollector);
        }

        emit LiqualityProxySwap(
            swapParams.target,
            msg.sender,
            feeRate,
            swapParams.tokenIn,
            swapParams.tokenOut,
            swapParams.amountIn,
            returnedAmount
        );
    }

    /// @notice No usecase currently in ZeroX for this function but
    /// it's here because it's part of the LiqualityAdapter Interface
    function exactOutputSwap(
        uint256, //feeRate,
        address, // feeCollector,
        LiqualityProxySwapParams calldata //swapParams
    ) external payable {
        revert("");
    }

    /// @notice refund unspent value
    function refundValue(uint256 amount) internal {
        // send unspent value out of proxy to user
        Adapter.sendValue(payable(msg.sender), amount);
    }

    function refundToken(uint256 amount, address token) internal {
        Adapter.sendToken(IERC20(token), msg.sender, amount);
    }
}
