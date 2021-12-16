// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ILiqualityProxy {
    /// @dev Emitted when passing an EOA or an undeployed contract as the target.
    error LiqProxy__TargetInvalid(address target);

    /// @dev Emitted when execution reverted with no reason.
    error LiqProxy__ExecutionReverted();

    /// @dev Emitted when the caller is not the liquality router.
    error LiqProxy__ExecutionNotAuthorized(address liqualityRouter, address caller, address target);

    /// @notice Emitted when the liquality router is changed during the DELEGATECALL.
    error LiqProxy__RouterChanged(address originalRouter, address newRouter);

    struct FeeData {
        address payable account;
        uint256 fee;
    }

    function execute(address target, bytes calldata data) external payable returns (bool success);
}
