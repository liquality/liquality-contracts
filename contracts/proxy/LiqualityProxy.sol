// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/ISwapperAdapter.sol";
import "./interfaces/ILiqualityProxy.sol";

contract LiqualityProxy is ILiqualityProxy {
    address payable private feeCollector;
    address private admin;

    ///@notice targetToAdapter maps each swapper to it's adapter
    mapping(address => address) public targetToAdapter;

    ///@notice targetToAdapter maps each swapper to the fee rate we use in it's case
    mapping(address => uint256) public targetToFeeRate;

    constructor(address _admin, address payable _feeCollector) {
        admin = _admin;
        feeCollector = _feeCollector;
    }

    function swap(address target, bytes calldata data) external payable {
        // Determine adapter to use
        address adapter = targetToAdapter[target];
        if (adapter == address(0)) revert LiqProxy__SwapperNotSupported(target);
        // Determine applicable feeRate
        uint256 feeRate = targetToFeeRate[target];
        if (feeRate <= 0) revert LiqProxy__InvalidFeeRate();

        // Delegate call to the adapter contract.
        // solhint-disable-next-line
        (bool success, bytes memory response) = adapter.delegatecall(
            abi.encodeWithSelector(
                ISwapperAdapter.swap.selector,
                feeRate,
                feeCollector,
                target,
                data
            )
        );

        // Check if the call was successful or not.
        if (!success) {
            revert(string(response));
        }
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) {
            revert LiqProxy__InvalidAdmin();
        }
        admin = newAdmin;
    }

    function addAdapter(address target, address adapter) external onlyAdmin {
        if (target == address(0)) {
            revert LiqProxy__SwapperNotSupported(target);
        }
        targetToAdapter[target] = adapter;
    }

    function removeAdapter(address target) external onlyAdmin {
        targetToAdapter[target] = address(0);
    }

    function setFeeCollector(address payable _feeCollector) external onlyAdmin {
        feeCollector = _feeCollector;
    }

    function setFeeRate(uint256 feeRate, address target) external onlyAdmin {
        targetToFeeRate[target] = feeRate;
    }

    /// @notice Needed in case a swapper refunds value
    // solhint-disable-next-line
    receive() external payable {}

    modifier onlyAdmin() {
        if (msg.sender != admin) revert LiqProxy__ExecutionNotAuthorized();
        _;
    }
}
