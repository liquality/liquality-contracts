// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ILiqProxy.sol";

contract LiqProxy is ILiqProxy {
    using SafeERC20 for IERC20;

    uint256 public gasReserve;

    constructor() {
        gasReserve = 5_000;
    }

    function execute(
        address target,
        address feeToken,
        bytes calldata data,
        FeeData[] calldata fees
    ) external payable returns (bytes memory response) {
        // Check that the target is a valid contract.
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(target)
        }
        if (codeSize == 0) {
            revert LiqProxy__TargetInvalid(target);
        }

        // handle ETH fees
        if (feeToken == address(0)) {
            uint256 totalFee = 0;
            for (uint256 i = 0; i < fees.length; i++) {
                totalFee += fees[i].fee;
                fees[i].account.transfer(fees[i].fee);
            }
            require(totalFee <= msg.value, "requested fee exceeds provided value");
        }
        // handle ERC20 fees
        else {
            for (uint256 i = 0; i < fees.length; i++) {
                IERC20(feeToken).safeTransferFrom(msg.sender, fees[i].account, fees[i].fee);
            }
        }

        // Reserve some gas to ensure that the function has enough to finish the execution.
        uint256 stipend = gasleft() - gasReserve;

        // Delegate call to the target contract.
        bool success;
        (success, response) = target.delegatecall{gas: stipend}(data);

        // Log the execution.
        emit Execute(target, data, response);

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
