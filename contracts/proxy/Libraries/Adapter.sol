// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../LibTransfer.sol";

/// @notice contains functions common to all adapters.
// @TODO consider(Yes or No) changing to an external library so it doesn't count
// in the code size of adapters that use it.
library Adapter {
    using SafeERC20 for IERC20;
    using LibTransfer for address payable;
    uint256 private constant MAX_UINT = type(uint256).max;

    function beginFromTokenSwap(
        address target,
        address fromToken,
        uint256 fromAmount,
        bytes memory data
    ) internal returns (bytes memory) {
        // Transfer users token to proxy
        IERC20(fromToken).safeTransferFrom(msg.sender, address(this), fromAmount);

        // Approve target as spender
        if (IERC20(fromToken).allowance(address(this), target) < fromAmount) {
            // Check if target already has allowance
            IERC20(fromToken).safeApprove(target, MAX_UINT);
        }

        // Call target
        // solhint-disable-next-line
        (bool success, bytes memory response) = target.call(data);
        if (!success) {
            revert(string(response));
        }

        return response;
    }

    function beginFromValueSwap(address target, bytes memory data) internal returns (bytes memory) {
        // Call target with value
        // solhint-disable-next-line
        (bool success, bytes memory response) = target.call{value: msg.value}(data);
        if (!success) {
            revert(string(response));
        }

        return response;
    }

    /// @notice collect fee and send remaining token to user
    function handleReturnedToken(
        address token,
        uint256 amount,
        uint256 feeRate,
        address feeCollector
    ) internal {
        // Collect fee from amount
        uint256 fee = computeFee(amount, feeRate);
        IERC20(token).safeTransfer(feeCollector, fee);

        // Credit user with amount less fee
        IERC20(token).safeTransfer(msg.sender, amount - fee);
    }

    /// @notice collect fee and send remaining value to user
    function handleReturnedValue(
        uint256 value,
        uint256 feeRate,
        address payable feeCollector
    ) internal {
        // Collect fee from value
        uint256 fee = computeFee(value, feeRate);
        feeCollector.transferEth(fee);

        // Credit user with value less fee
        payable(msg.sender).transferEth(value - fee);
    }

    function computeFee(uint256 amount, uint256 feeRate) internal pure returns (uint256) {
        return amount / feeRate;
    }

    function isSwapFromValue() internal returns (bool) {
        return msg.value > 0;
    }

    function isSwapToValue(address tokenOut) internal pure returns (bool) {
        return tokenOut == address(0);
    }
}
