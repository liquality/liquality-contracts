// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Adapter} from "../Libraries/Adapter.sol";
import {ILiqualityAdapter} from "../interfaces/ILiqualityAdapter.sol";
import "../interfaces/ILiqualityProxyEvent.sol";

contract LiqZeroXAdapter is ILiqualityAdapter, ILiqualityProxyEvent {
    function exactInput(
        address target,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256, //amountOut,
        uint256 feeRate,
        address feeCollector,
        bytes calldata data
    ) external payable {
        // Determine the swap type(fromToken or fromValue) and initiate swap.
        bytes memory response;
        if (Adapter.isSwapFromValue()) {
            // If it's a swap from value
            response = Adapter.beginFromValueSwap(target, data);
        } else {
            // If it's a swap from Token
            response = Adapter.beginFromTokenSwap(target, tokenIn, amountIn, data);
        }
        uint256 returnedAmount = abi.decode(response, (uint256));

        // handle returnedAmount
        if (Adapter.isSwapToValue(tokenOut)) {
            Adapter.handleReturnedValue(returnedAmount, feeRate, payable(feeCollector));
        } else {
            // If it's a swap to token
            Adapter.handleReturnedToken(tokenOut, returnedAmount, feeRate, feeCollector);
        }

        emit LiqualityProxySwap(
            target,
            msg.sender,
            feeRate,
            tokenIn,
            tokenOut,
            amountIn,
            returnedAmount
        );
    }

    function exactOutput(
        address, //target
        address, //tokenIn
        address, //tokenOut
        uint256, //amountIn
        uint256, //amountOut
        uint256, //feeRate
        address, //feeCollector
        bytes calldata //data
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
