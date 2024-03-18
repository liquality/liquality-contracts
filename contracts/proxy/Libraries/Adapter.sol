// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

/// @notice Common util.
contract Adapter {
    /// @dev Emitted when swap params are invalid.
    error LiqProxy__InvalidMsgVal();

    struct LiqualityProxySwapInfo {
        address swapper;
        address user;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut;
    }

    /// @dev Emitted when a successful swap operation goes throuth the proxy.
    event LiqualityProxySwap(LiqualityProxySwapInfo swapInfo);

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant ZERO_ADDRESS = address(0);

    /// @dev some swappers use ZERO_ADDRESS
    function isETH(address tokenAdr) internal pure returns (bool) {
        return (tokenAdr == ZERO_ADDRESS || tokenAdr == ETH_ADDRESS);
    }

    function validateMsgValue(address tokenIn) internal {
        if ((msg.value > 0 && !isETH(tokenIn)) || (msg.value == 0 && isETH(tokenIn))) {
            revert LiqProxy__InvalidMsgVal();
        }
    }
}
