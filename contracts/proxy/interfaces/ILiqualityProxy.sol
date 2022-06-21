// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ILiqualityProxy {
    /// @dev Emitted when execution reverted with no reason.
    error LiqProxy__ExecutionReverted();

    error LiqProxy__ExecutionNotAuthorized();

    /// @dev Emitted when the swapper is not supported.
    error LiqProxy__SwapperNotSupported(address swapper);

    /// @dev Emitted when feeRate is zero(0)
    error LiqProxy__InvalidFeeRate();

    error LiqProxy__InvalidAdmin();

    /// @notice this function is callable by anyone
    function swap(address swapper, bytes calldata data) external payable;

    ///  @notice this function changes the admin
    function changeAdmin(address newAdmin) external;

    ///  @notice Add/update adapter for a swapper
    function addAdapter(address swapper, address adapter) external;

    ///  @notice Removes an adapter
    function removeAdapter(address swapper) external;

    ///  @notice Sets the address of contract where fees get's deposited to
    function setFeeCollector(address payable _feeCollector) external;

    ///  @notice Sets the _feeRate. Fee equals amount / _feeRate
    /// @param feeRate An int expression for the actual "rate in percentage".
    /// @param swapper The swapper to which the feeRate should apply
    /// 5% (i.e 5/100) becomes as 20. So fee equals amount/20 in this case;
    /// 0.2% (i.e 2/1000) becomes as 500, and 0.02% (i.e 2/10000) becomes as 5000
    function setFeeRate(uint256 feeRate, address swapper) external;

    struct SwapperInfo {
        address swapper;
        address adapter;
        uint256 feeRate;
    }
}
