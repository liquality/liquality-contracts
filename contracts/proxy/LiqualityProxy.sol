// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ILiqualityProxy.sol";
import "./LibTransfer.sol";

contract LiqualityProxy is ILiqualityProxy {
    using SafeERC20 for IERC20;
    using LibTransfer for address payable;
    address payable private feeCollector;
    address private admin;
    uint256 private feeRate;

    ///@notice targetFunctionToAdapterFunction maps each function in each swapper to the
    /// adapter function that handles it.
    mapping(address => mapping(bytes4 => bytes4)) public targetFunctionToAdapterFunction;

    ///@notice targetToAdapter maps each swapper to it's adapter
    mapping(address => address) public targetToAdapter;

    constructor(address _admin) {
        admin = _admin;
    }

    function swap(LiqualityProxySwapParams calldata swapParams) external payable {
        // Determine adapter to use
        address adapter = targetToAdapter[swapParams.target];

        // Determine adapter function to use
        bytes4 targetFunction = bytes4(swapParams.data);
        bytes4 adapterFunction = targetFunctionToAdapterFunction[swapParams.target][targetFunction];

        // Delegate call to the adapter contract.
        // solhint-disable-next-line
        (bool success, bytes memory response) = adapter.delegatecall(
            abi.encodeWithSelector(adapterFunction, feeRate, feeCollector, swapParams)
        );

        // Check if the call was successful or not.
        if (!success) {
            revert(string(response));
        }
    }

    function addAdapter(address target, address adapter) external onlyAdmin {
        if (target == address(0)) {
            revert LiqProxy__SwapperNotSupported(target);
        }
        targetToAdapter[target] = adapter;
    }

    function mapSwapperFunctionToAdapterFunction(
        address target,
        bytes4 swapperFunction,
        bytes4 adapterFunction
    ) external onlyAdmin {
        if (adapterFunction == bytes4(0) || bytes4(swapperFunction) == bytes4(0)) {
            revert LiqProxy__SwapperFunctionNotSupported(target, swapperFunction);
        }
        targetFunctionToAdapterFunction[target][swapperFunction] = adapterFunction;
    }

    function setFeeCollector(address payable _feeCollector) external onlyAdmin {
        feeCollector = _feeCollector;
    }

    function setFeeRate(uint256 _feeRate) external onlyAdmin {
        feeRate = _feeRate;
    }

    /// @notice Needed in case a swapper refunds value
    // solhint-disable-next-line
    receive() external payable {}

    /// @notice Transfer any stuck value from contract to fee collector
    function withdrawStuckValue() external onlyAdmin {
        feeCollector.transferEth(address(this).balance);
    }

    /// @notice Transfer any stuck token from contract to fee collector
    function withdrawStuckToken(IERC20 token) external onlyAdmin {
        token.safeTransfer(feeCollector, token.balanceOf(address(this)));
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) revert LiqProxy__ExecutionNotAuthorized();
        _;
    }
}
