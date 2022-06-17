// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Adapter.sol";
import "./LibTransfer.sol";

/// @notice contains functions common to all adapters.
contract BeginSwap is Adapter {
    using SafeERC20 for IERC20;
    using LibTransfer for address payable;
    uint256 private constant MAX_UINT = type(uint256).max;

    function beginFromTokenSwap(
        address target,
        address token,
        uint256 amount,
        uint256 feeRate,
        address feeCollector,
        bytes memory data
    ) internal returns (uint256 fee) {
        // Collect fee from amount
        fee = computeFee(amount, feeRate);
        IERC20(token).safeTransferFrom(msg.sender, feeCollector, fee);

        // Transfer users token to proxy
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Approve target as spender
        if (IERC20(token).allowance(address(this), target) < amount) {
            // Check if target already has allowance
            IERC20(token).safeApprove(target, MAX_UINT);
        }
        // Call target
        // solhint-disable-next-line
        (bool success, bytes memory response) = target.call(data);
        if (!success) {
            revert(string(response));
        }

        //  Return any unused token
        uint256 proxyTokenInBal = IERC20(token).balanceOf(address(this));
        if (proxyTokenInBal > 0) {
            IERC20(token).safeTransfer(msg.sender, proxyTokenInBal);
        }
    }

    function beginFromValueSwap(
        address target,
        uint256 value,
        uint256 feeRate,
        address payable feeCollector,
        bytes memory data
    ) internal returns (uint256 fee) {
        // Collect fee from value
        fee = computeFee(value, feeRate);
        feeCollector.transferEth(fee);

        if (msg.value != value + fee) revert LiqProxy__InvalidMsgVal();

        // Call target with value
        // solhint-disable-next-line
        (bool success, bytes memory response) = target.call{value: value}(data);
        if (!success) {
            revert(string(response));
        }

        // Return any unused value
        uint256 proxyTokenInBal = address(this).balance;
        if (proxyTokenInBal > 0) {
            payable(msg.sender).transferEth(proxyTokenInBal);
        }
    }

    function computeFee(uint256 amount, uint256 feeRate) internal pure returns (uint256) {
        return amount / feeRate;
    }
}
