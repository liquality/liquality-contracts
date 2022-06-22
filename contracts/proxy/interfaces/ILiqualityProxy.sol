// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ILiqualityProxy {
    /// @dev Emitted when execution reverted with no reason.
    error LiqProxy__ExecutionReverted();

    error LiqProxy__ExecutionNotAuthorized();

    /// @dev Emitted when the swapper is not supported.
    error LiqProxy__SwapperNotSupported(address swapper);

    error LiqProxy__InvalidAdmin();

    struct SwapperInfo {
        address swapper;
        address adapter;
    }

    struct FeeData {
        address payable account;
        uint256 fee;
    }

    event FeePayment(address feeToken, uint256 fee);

    /// @notice this function is callable by anyone
    function swap(
        address swapper,
        bytes calldata data,
        address feeToken,
        FeeData[] calldata fees
    ) external payable;

    /// @notice this function is callable by anyone
    function swapWithReferral(
        address swapper,
        bytes calldata data,
        address feeToken,
        FeeData[] calldata fees,
        address referrer
    ) external payable;

    ///  @notice this function changes the admin
    function changeAdmin(address newAdmin) external;

    ///  @notice Add/update adapter for a swapper
    function addAdapter(address swapper, address adapter) external;

    ///  @notice Removes an adapter
    function removeAdapter(address swapper) external;
}
