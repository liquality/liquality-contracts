// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ILiqualityProxy {
    /// @dev Emitted when execution reverted with no reason.
    error LiqProxy__ExecutionReverted();

    error LiqProxy__ExecutionNotAuthorized();

    /// @dev Emitted when the target swapper is not supported.
    error LiqProxy__SwapperNotSupported(address target);

    /// @dev Emitted when unsupported function of swapper is encountered.
    error LiqProxy__SwapperFunctionNotSupported(address target, bytes4 targetFunction);

    error LiqProxy__InvalidAdmin();

    /// @notice this function is callable by anyone
    function swap(address target, bytes calldata data) external payable;

    ///  @notice this function changes the admin
    function changeAdmin(address newAdmin) external;

    ///  @notice Add/update adapter for a target swapper
    function addAdapter(address target, address adapter) external;

    ///  @notice Removes an adapter
    function removeAdapter(address target) external;

    ///  @notice Sets the address of contract where fees get's deposited to
    function setFeeCollector(address payable _feeCollector) external;

    ///  @notice Sets the _feeRate. Fee equals amount / _feeRate
    /// @param _feeRate An int expression for the actual "rate in percentage".
    /// 5% (i.e 5/100) becomes as 20. So fee equals amount/20 in this case;
    /// 0.2% (i.e 2/1000) becomes as 500, and 0.02% (i.e 2/10000) becomes as 5000
    function setFeeRate(uint256 _feeRate) external;
}
