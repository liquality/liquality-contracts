// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/ISwapperAdapter.sol";
import "./interfaces/ILiqualityProxy.sol";

contract LiqualityProxy is ILiqualityProxy {
    address payable private feeCollector;
    address private admin;

    ///@notice swapperToAdapter maps each swapper to it's adapter
    mapping(address => address) public swapperToAdapter;

    ///@notice swapperToAdapter maps each swapper to the fee rate we use in it's case
    mapping(address => uint256) public swapperToFeeRate;

    constructor(
        address _admin,
        address payable _feeCollector,
        SwapperInfo[] memory swappersInfo
    ) {
        admin = _admin;
        feeCollector = _feeCollector;

        address adapter;
        address swapper;
        uint256 feeRate;
        for (uint256 i = 0; i < swappersInfo.length; i++) {
            swapper = swappersInfo[i].swapper;
            adapter = swappersInfo[i].adapter;
            feeRate = swappersInfo[i].feeRate;

            if (adapter == address(0) || swapper == address(0))
                revert LiqProxy__SwapperNotSupported(swapper);
            if (feeRate <= 0) revert LiqProxy__InvalidFeeRate();

            swapperToAdapter[swapper] = adapter;
            swapperToFeeRate[swapper] = feeRate;
        }
    }

    function swap(address swapper, bytes calldata data) external payable {
        // Determine adapter to use
        address adapter = swapperToAdapter[swapper];
        if (adapter == address(0)) revert LiqProxy__SwapperNotSupported(swapper);
        // Determine applicable feeRate
        uint256 feeRate = swapperToFeeRate[swapper];
        if (feeRate <= 0) revert LiqProxy__InvalidFeeRate();

        // Delegate call to the adapter contract.
        // solhint-disable-next-line
        (bool success, bytes memory response) = adapter.delegatecall(
            abi.encodeWithSelector(
                ISwapperAdapter.swap.selector,
                feeRate,
                feeCollector,
                swapper,
                data
            )
        );

        // Check if the call was successful or not.
        if (!success) {
            revert(string(response));
        }
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert LiqProxy__InvalidAdmin();
        admin = newAdmin;
    }

    function addAdapter(address swapper, address adapter) external onlyAdmin {
        if (adapter == address(0) || swapper == address(0))
            revert LiqProxy__SwapperNotSupported(swapper);
        swapperToAdapter[swapper] = adapter;
    }

    function removeAdapter(address swapper) external onlyAdmin {
        swapperToAdapter[swapper] = address(0);
    }

    function setFeeCollector(address payable _feeCollector) external onlyAdmin {
        feeCollector = _feeCollector;
    }

    function setFeeRate(uint256 feeRate, address swapper) external onlyAdmin {
        if (feeRate <= 0) revert LiqProxy__InvalidFeeRate();
        swapperToFeeRate[swapper] = feeRate;
    }

    /// @notice Needed in case a swapper refunds value
    // solhint-disable-next-line
    receive() external payable {}

    modifier onlyAdmin() {
        if (msg.sender != admin) revert LiqProxy__ExecutionNotAuthorized();
        _;
    }
}
