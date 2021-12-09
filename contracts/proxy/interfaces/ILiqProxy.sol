// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ILiqProxy {
    /// @dev Emitted when passing an EOA or an undeployed contract as the target.
    error LiqProxy__TargetInvalid(address target);

    /// @dev Emitted when execution reverted with no reason.
    error LiqProxy__ExecutionReverted();

    event Execute(address indexed target, bytes data, bytes response);

    struct FeeData {
        address payable account;
        uint256 fee;
    }
}
