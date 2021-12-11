// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ILiqualityProxy.sol";

contract LiqualityProxy is ILiqualityProxy {
    using SafeERC20 for IERC20;

    uint256 public constant gasReserve = 5_000;

    address public liqualityRouter;

    constructor(address _liqualityRouter) {
        liqualityRouter = _liqualityRouter;
    }

    function execute(address target, bytes calldata data) external payable returns (bool success) {
        // Check that the caller is the liquality router
        if (liqualityRouter != msg.sender) {
            revert LiqProxy__ExecutionNotAuthorized(liqualityRouter, msg.sender, target);
        }

        // Check that the target is a valid contract.
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(target)
        }
        if (codeSize == 0) {
            revert LiqProxy__TargetInvalid(target);
        }

        // Save the router address in memory. This local variable cannot be modified during the DELEGATECALL.
        address liqualityRouter_ = liqualityRouter;

        // Reserve some gas to ensure that the function has enough to finish the execution.
        uint256 stipend = gasleft() - gasReserve;

        // Delegate call to the target contract.
        bytes memory response;
        (success, response) = target.delegatecall{gas: stipend}(data);

        // Check that the router has not been changed.
        if (liqualityRouter_ != liqualityRouter) {
            revert LiqProxy__RouterChanged(liqualityRouter_, liqualityRouter);
        }

        // Check if the call was successful or not.
        if (!success) {
            // If there is return data, the call reverted with a reason or a custom error.
            if (response.length > 0) {
                assembly {
                    let returndata_size := mload(response)
                    revert(add(32, response), returndata_size)
                }
            } else {
                revert LiqProxy__ExecutionReverted();
            }
        }
    }
}
