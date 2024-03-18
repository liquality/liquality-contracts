// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./LibTransfer.sol";

import "hardhat/console.sol";

/// @notice contains functions common to all adapters.
contract EndSwap {
    using SafeERC20 for IERC20;
    using LibTransfer for address payable;

    function handleReturnedToken(address token) internal returns (uint256 amount) {
        console.log("Now in Handle returned Token");
        console.log(address(this));
        amount = IERC20(token).balanceOf(address(this));
        console.log(token);
        console.log(amount);

        // Credit user with amount
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function handleReturnedValue() internal returns (uint256 value) {
        value = address(this).balance;

        // Credit user with value less fee
        payable(msg.sender).transferEth(value);
    }
}