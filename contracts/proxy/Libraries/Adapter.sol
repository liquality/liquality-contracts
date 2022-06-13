// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./LibTransfer.sol";
import "hardhat/console.sol";

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
        console.log("Came to beginFromTokenSwap");
        console.log(fromToken);
        console.log(fromAmount);
        console.log(IERC20(fromToken).balanceOf(msg.sender));
        // Transfer users token to proxy
        IERC20(fromToken).safeTransferFrom(msg.sender, address(this), fromAmount);
        console.log("Tansfered token to  proxy");
        // Approve target as spender
        if (IERC20(fromToken).allowance(address(this), target) < fromAmount) {
            // Check if target already has allowance
            IERC20(fromToken).safeApprove(target, MAX_UINT);
        }
        console.log("Approved target  as spender");
        // Call target
        // solhint-disable-next-line
        (bool success, bytes memory response) = target.call(data);
        if (!success) {
            revert(string(response));
        }
        console.log("Finished calling target");
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
        uint256 feeRate,
        address feeCollector
    ) internal returns (uint256 amount) {
        amount = IERC20(token).balanceOf(address(this));
        // Collect fee from amount
        uint256 fee = computeFee(amount, feeRate);
        console.log(fee);
        console.log(feeCollector);
        console.log(token);
        console.log("See ether balance of the contract below >>> ");
        console.log(address(this).balance);
        IERC20(token).safeTransfer(feeCollector, fee);

        console.log("Transfered to feeCollector");
        // Credit user with amount less fee
        IERC20(token).safeTransfer(msg.sender, amount - fee);
        console.log("Transfered to user");
    }

    /// @notice collect fee and send remaining value to user
    function handleReturnedValue(uint256 feeRate, address payable feeCollector)
        internal
        returns (uint256 value)
    {
        value = address(this).balance;
        // Collect fee from value
        uint256 fee = computeFee(value, feeRate);
        console.log(fee);
        console.log(feeCollector);
        console.log(value);
        console.log("Handle  returned  value See ether balance of the contract below >>> ");
        console.log(address(this).balance);
        feeCollector.transferEth(fee);
        // Credit user with value less fee
        payable(msg.sender).transferEth(value - fee);
    }

    function computeFee(uint256 amount, uint256 feeRate) internal pure returns (uint256) {
        return amount / feeRate;
    }
}
