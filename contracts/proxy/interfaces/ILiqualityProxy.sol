// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./IProxyCommons.sol";

interface ILiqualityProxy is IProxyCommons {
    /// @dev Emitted when execution reverted with no reason.
    error LiqProxy__ExecutionReverted();

    error LiqProxy__ExecutionNotAuthorized();

    /// @dev Emitted when the target swapper is not supported.
    error LiqProxy__SwapperNotSupported(address target);

    /// @dev Emitted when unsupported function of swapper is encountered.
    error LiqProxy__SwapperFunctionNotSupported(address target, bytes4 targetFunction);

    /// @notice this function is callable by anyone
    function swap(LiqualityProxySwapParams calldata swapParams) external payable;

    ///  @notice Add/update adapter for a target swapper
    function addAdapter(address target, address adapter) external;

    ///  @notice Sets the address of contract where fees get's deposited to
    function setFeeCollector(address payable _feeCollector) external;

    ///  @notice Sets the feeRate. Fee equals amount / feeRate
    function setFeeRate(uint256 _feeRate) external;
}
