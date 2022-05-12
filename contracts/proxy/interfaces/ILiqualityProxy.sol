// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ILiqualityProxy {
    /// @dev Emitted when execution reverted with no reason.
    error LiqProxy__ExecutionReverted();

    /// @dev Emitted when the caller is not an EOA.
    error LiqProxy__ExecutionNotAuthorized(address caller, address target);

    /// @dev Emitted when the target swapper is not supported.
    error LiqProxy__SwapperNotSupported(address target);

    /// @dev Emitted when unsupported function of swapper is encountered.
    error LiqProxy__SwapperFunctionNotSupported(address target, bytes4 targetFunction);

    /// @dev Emitted when a successful swap operation goes throuth the proxy.
    event ProxySwap(address indexed target, bytes data);

    function swap(address target, bytes calldata data) external payable;

    // ///  @notice Use the targetToAdapter mapping to know which adapter to use
    // function chooseAdapter(address target) external returns (address);

    // ///  @notice Use the targetFunctionToAdapterFunction mapping to know which adapter function to call
    // function chooseAdapterFunction(address target, bytes calldata data) external returns (bytes4);

    ///  @notice Add/update adapter for a target swapper
    function addAdapter(address target, address adapter) external;

    ///  @notice Map a swapper function to an adapter function
    function mapSwapperFunctionToAdapterFunction(
        address target,
        bytes4 swapperFunction,
        bytes4 adapterFunction
    ) external;

    ///  @notice Sets the address of contract where fees get's deposited to
    function setFeeCollector(address payable _feeCollector) external;

    ///  @notice Sets the feeRate. Fee equals amount / feeRate
    function setFeeRate(uint256 _feeRate) external;
}
