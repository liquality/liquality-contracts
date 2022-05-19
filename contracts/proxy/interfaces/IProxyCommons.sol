// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface IProxyCommons {
    struct LiqualityProxySwapParams {
        // The target swapper
        address target;
        // tokenIn is 0x000... when swapping from value else it should be same as the tokenIn encoded in data.
        address tokenIn;
        // tokenOut is 0x000... when swapping to value else it should be same as the tokenOut encoded in data.
        address tokenOut;
        // same as amountIn encoded in data
        uint256 amountIn;
        // same as amountOut encoded in data
        uint256 amountOut;
        // encode data to be forwarded to target.
        bytes data;
    }
}
