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
        address swapper,
        address token,
        uint256 amount,
        bytes memory data
    ) internal {
        // Transfer users token to proxy
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Approve swapper as spender
        if (IERC20(token).allowance(address(this), swapper) < amount) {
            // Check if swapper already has allowance
            IERC20(token).safeApprove(swapper, MAX_UINT);
        }
        // Call swapper
        // solhint-disable-next-line
        (bool success, bytes memory response) = swapper.call(data);
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
        address swapper,
        uint256 value,
        bytes memory data
    ) internal {
        // Call swapper with value
        // solhint-disable-next-line
        (bool success, bytes memory response) = swapper.call{value: value}(data);
        if (!success) {
            revert(string(response));
        }

        // Return any unused value
        uint256 proxyTokenInBal = address(this).balance;
        if (proxyTokenInBal > 0) {
            payable(msg.sender).transferEth(proxyTokenInBal);
        }
    }
}
