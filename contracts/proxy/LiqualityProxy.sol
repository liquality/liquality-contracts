// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ILiqualityProxy.sol";

contract LiqualityProxy is ILiqualityProxy {
    address payable private feeCollector;
    uint256 private feeRate;

    constructor() {
        feeRate = 1000;
        feeCollector = payable(0x0EDd8AF763D0a7999f15623859dA9a0A786D1A9B);
    }

    ///@notice targetFunctionToAdapterFunction maps each function in each swapper to the
    /// adapter function that handles it.
    mapping(address => mapping(bytes4 => bytes4)) public targetFunctionToAdapterFunction;

    ///@notice targetToAdapter maps each swapper to it's adapter
    mapping(address => address) public targetToAdapter;

    function swap(address target, bytes calldata data) external payable {
        // Check that the caller is an EOA
        if (msg.sender != tx.origin) {
            revert LiqProxy__ExecutionNotAuthorized(msg.sender, target);
        }

        // Determine adapter to use
        address adapter = targetToAdapter[target];
        if (target == address(0)) {
            revert LiqProxy__SwapperNotSupported(target);
        }

        // Determine adapter function to use
        bytes4 targetFunction = bytes4(data);
        bytes4 adapterFunction = targetFunctionToAdapterFunction[target][targetFunction];
        if (adapterFunction == bytes4(0)) {
            revert LiqProxy__SwapperFunctionNotSupported(target, targetFunction);
        }

        // Delegate call to the adapter contract.
        (bool success, bytes memory __) = adapter.delegatecall(
            abi.encodeWithSelector(adapterFunction, target, feeRate, feeCollector, data)
        );

        // Check if the call was successful or not.
        if (!success) {
            revert LiqProxy__ExecutionReverted();
        }

        emit ProxySwap(target, data);
    }

    function addAdapter(address target, address adapter) external {
        targetToAdapter[target] = adapter;
    }

    function mapSwapperFunctionToAdapterFunction(
        address target,
        bytes4 swapperFunction,
        bytes4 adapterFunction
    ) external {
        targetFunctionToAdapterFunction[target][swapperFunction] = adapterFunction;
    }

    function setFeeCollector(address payable _feeCollector) external {
        feeCollector = _feeCollector;
    }

    function setFeeRate(uint256 _feeRate) external {
        feeRate = _feeRate;
    }

    // @notice Needed in case there a swapper refunds value
    receive() external payable {}
}
