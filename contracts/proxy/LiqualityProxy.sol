// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ILiqualityProxyAdapter.sol";
import "./interfaces/ILiqualityProxy.sol";
import "./LibTransfer.sol";

contract LiqualityProxy is ILiqualityProxy {
    using SafeERC20 for IERC20;
    using LibTransfer for address payable;
    address payable private feeCollector;
    address private admin;
    uint256 private feeRate;

    ///@notice targetToAdapter maps each swapper to it's adapter
    mapping(address => address) public targetToAdapter;

    constructor(address _admin) {
        admin = _admin;
    }

    function swap(LiqualityProxySwapParams calldata swapParams) external payable {
        // Determine adapter to use
        address adapter = targetToAdapter[swapParams.target];

        // Delegate call to the adapter contract.
        // solhint-disable-next-line
        (bool success, bytes memory response) = adapter.delegatecall(
            abi.encodeWithSelector(
                ILiqualityProxyAdapter.swap.selector,
                feeRate,
                feeCollector,
                swapParams
            )
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

    function setFeeCollector(address payable _feeCollector) external onlyAdmin {
        feeCollector = _feeCollector;
    }

    function setFeeRate(uint256 _feeRate) external onlyAdmin {
        feeRate = _feeRate;
    }

    /// @notice Needed in case a swapper refunds value
    // solhint-disable-next-line
    receive() external payable {}

    modifier onlyAdmin() {
        if (msg.sender != admin) revert LiqProxy__ExecutionNotAuthorized();
        _;
    }
}
