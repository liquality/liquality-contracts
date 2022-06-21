// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "../Libraries/FullSwap.sol";
import "../interfaces/ISwapperAdapter.sol";

contract LiqualityZeroXAdapter is ISwapperAdapter, FullSwap {
    /// @notice This works for ZeroX sellToUniswap.
    function swap(
        uint256 feeRate,
        address feeCollector,
        address swapper,
        bytes calldata data
    ) external payable {
        // Decode data
        (address[] memory tokens, uint256 sellAmount) = abi.decode(data[4:], (address[], uint256));

        address tokenIn = tokens[0];
        address tokenOut = tokens[tokens.length - 1];

        execute(feeRate, feeCollector, swapper, data, tokenIn, tokenOut, sellAmount);
    }
}
