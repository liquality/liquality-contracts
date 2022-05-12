// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ILiqUniswapV3AdapterV1 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @dev Swaps exact input for atleast X
    function exactInputSingle(
        address target,
        uint256 feeRate,
        address feeCollector,
        bytes calldata data
    ) external payable;
}
