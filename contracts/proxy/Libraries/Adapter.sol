// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice contains functions common to all adapters.
// @TODO consider(Yes or No) changing to an external library so it doesn't count
// in the code size of adapters that use it.
library Adapter {
    using SafeERC20 for IERC20;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    bytes4 constant WETH_WITHDRAW_FNC = 0x2e1a7d4d;

    function beginFromTokenSwap(
        address target,
        address fromToken,
        uint256 fromAmount,
        bytes calldata data
    ) internal returns (bytes memory) {
        // Transfer users token to proxy
        IERC20(fromToken).safeTransferFrom(msg.sender, address(this), fromAmount);

        // Approve target as spender
        IERC20(fromToken).safeApprove(target, fromAmount);
        // Call target
        (bool success, bytes memory response) = target.call(data);
        if (!success) {
            revert("");
        }

        return response;
    }

    function beginFromValueSwap(address target, bytes calldata data)
        internal
        returns (bytes memory)
    {
        // Call target with value
        (bool success, bytes memory response) = target.call{value: msg.value}(data);
        if (!success) {
            console.log("Call to Target swapper unsuccessful >>>  ");
            console.logBytes(response);

            revert("");
        }

        return response;
    }

    /// @notice collect fee and send remaining token to user
    function handleReturnedToken(
        address returnedToken,
        uint256 returnedAmount,
        uint256 feeRate,
        address feeCollector
    ) internal {
        // Collect fee from returnedAmount token
        uint256 fee = computeFee(returnedAmount, feeRate);
        sendToken(IERC20(returnedToken), feeCollector, fee);

        // Credit user with returnedAmount tokens less fee
        sendToken(IERC20(returnedToken), msg.sender, returnedAmount - fee);
    }

    /// @notice collect fee and send remaining value to user
    function handleReturnedValue(
        uint256 returnedAmount,
        uint256 feeRate,
        address payable feeCollector
    ) internal {
        // Collect fee from returnedAmount value
        uint256 fee = computeFee(returnedAmount, feeRate);
        sendValue(feeCollector, fee);

        // Credit user with returnedAmount value less fee
        sendValue(payable(msg.sender), returnedAmount - fee);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        (bool success, bytes memory __) = recipient.call{value: amount}("");
        if (!success) {
            revert("");
        }
    }

    function sendToken(
        IERC20 token,
        address recipient,
        uint256 amount
    ) internal {
        token.safeTransfer(recipient, amount);
    }

    function computeFee(uint256 amount, uint256 feeRate) internal pure returns (uint256) {
        return amount / feeRate;
    }

    function isSwapFromValue() internal returns (bool) {
        return msg.value > 0;
    }

    function unwrapWeth(uint256 amount) internal {
        (bool success, bytes memory response) = WETH.call(
            abi.encodeWithSelector(WETH_WITHDRAW_FNC, amount)
        );
        if (!success) {
            revert("");
        }
    }
}
