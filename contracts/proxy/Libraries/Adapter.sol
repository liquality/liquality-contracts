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
    uint256 private constant MAX_INT = 2**256 - 1;

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
            IERC20(fromToken).safeApprove(target, MAX_INT);
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
        address returnedToken,
        uint256 returnedAmount,
        uint256 feeRate,
        address feeCollector
    ) internal {
        // Collect fee from returnedAmount token
        uint256 fee = computeFee(returnedAmount, feeRate);
        IERC20(returnedToken).safeTransfer(feeCollector, fee);

        // Credit user with returnedAmount tokens less fee
        IERC20(returnedToken).safeTransfer(msg.sender, returnedAmount - fee);
    }

    /// @notice collect fee and send remaining value to user
    function handleReturnedValue(
        uint256 returnedAmount,
        uint256 feeRate,
        address payable feeCollector
    ) internal {
        // Collect fee from returnedAmount value
        uint256 fee = computeFee(returnedAmount, feeRate);
        feeCollector.transferEth((fee));

        // Credit user with returnedAmount value less fee
        payable(msg.sender).transferEth((returnedAmount - fee));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        recipient.transferEth((amount));
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

    function isSwapToValue(address tokenOut) internal pure returns (bool) {
        return tokenOut == address(0);
    }
}
