// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ILiqualityAdapter {
    /// @dev Emitted when a successful swap operation goes throuth the proxy.
    event LiqualityProxySwap(
        address indexed target,
        address indexed user,
        uint256 indexed feeRate,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @dev Swaps exact input for atleast X output
    function exactInputSwap(
        address target,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 feeRate,
        address feeCollector,
        bytes calldata data
    ) external payable;

    /// @dev Swaps atmost X input for exact output
    ///  This usecase is different from exactInputSwap in that, here, unspent amountIn is returned to the user
    function exactOutputSwap(
        address target,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 feeRate,
        address feeCollector,
        bytes calldata data
    ) external payable;
}
