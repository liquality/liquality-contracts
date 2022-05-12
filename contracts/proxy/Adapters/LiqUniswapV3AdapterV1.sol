// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

pragma abicoder v2;

import {Adapter} from "../Libraries/Adapter.sol";
import {ILiqUniswapV3AdapterV1} from "../interfaces/ILiqUniswapV3AdapterV1.sol";

contract LiqUniswapV3AdapterV1 is ILiqUniswapV3AdapterV1 {
    /// @notice data length when end goal of swap is a token. Greate if end goal is value
    uint256 constant TO_TOKEN_DATA_LENGTH = 260;

    // @TODO Update this function after understanding how swaps involving values work in Uniswap V3
    function exactInputSingle(
        address target,
        uint256 feeRate,
        address feeCollector,
        bytes calldata data
    ) external payable {
        bool isSwapFromValue = Adapter.isSwapFromValue();

        ExactInputSingleParams memory params;

        // Decode data to get fromToken and fromAmount
        (params) = abi.decode(data[4:TO_TOKEN_DATA_LENGTH], (ExactInputSingleParams));

        // Determine the swap type(fromToken or fromValue) and initiate swap.
        bytes memory response;
        if (isSwapFromValue) {
            // If it's a swap from value
            response = Adapter.beginFromValueSwap(target, data);
        } else {
            // If it's a swap from Token
            response = Adapter.beginFromTokenSwap(target, params.tokenIn, params.amountIn, data);
        }
        uint256 returnedAmount = abi.decode(response, (uint256));

        // handle returnedAmount
        if (data.length > TO_TOKEN_DATA_LENGTH) {
            // If it's a swap to value
            // Unwrap returned weth first
            Adapter.unwrapWeth(returnedAmount);

            Adapter.handleReturnedValue(returnedAmount, feeRate, payable(feeCollector));
        } else {
            // If it's a swap to token
            Adapter.handleReturnedToken(params.tokenOut, returnedAmount, feeRate, feeCollector);
        }
    }
}
