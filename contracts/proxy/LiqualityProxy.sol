// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../referrals/interfaces/IReferralRegistry.sol";

import "./Libraries/LibTransfer.sol";

import "./interfaces/ISwapperAdapter.sol";
import "./interfaces/ILiqualityProxy.sol";

contract LiqualityProxy is ILiqualityProxy {
    using SafeERC20 for IERC20;
    using LibTransfer for address payable;

    IReferralRegistry public referralRegistry;
    address private admin;

    ///@notice swapperToAdapter maps each swapper to it's adapter
    mapping(address => address) public swapperToAdapter;

    constructor(
        address _admin,
        SwapperInfo[] memory swappersInfo,
        address referralRegistryAdr
    ) {
        admin = _admin;

        // Register swapper adapters
        address adapter;
        address swapper;
        for (uint256 i = 0; i < swappersInfo.length; i++) {
            swapper = swappersInfo[i].swapper;
            adapter = swappersInfo[i].adapter;

            if (adapter == address(0) || swapper == address(0))
                revert LiqProxy__SwapperNotSupported(swapper);

            swapperToAdapter[swapper] = adapter;
        }

        // Set referral Registry
        referralRegistry = IReferralRegistry(referralRegistryAdr);
    }

    function swap(
        address swapper,
        bytes calldata data,
        address feeToken,
        FeeData[] calldata fees
    ) external payable {
        _swap(swapper, data, feeToken, fees);
    }

    function swapWithReferral(
        address swapper,
        bytes calldata data,
        address feeToken,
        FeeData[] calldata fees,
        address referrer
    ) external payable {
        address user = msg.sender;
        // handle referrals
        Referral memory referral = referralRegistry.getReferral(user);
        if (referral.referrer != address(0x0)) {
            referralRegistry.registerReferral(referrer, user);
        }

        _swap(swapper, data, feeToken, fees);
    }

    function _swap(
        address swapper,
        bytes calldata data,
        address feeToken,
        FeeData[] calldata fees
    ) internal {
        // Determine adapter to use
        address adapter = swapperToAdapter[swapper];
        if (adapter == address(0)) revert LiqProxy__SwapperNotSupported(swapper);

        uint256 totalFee = 0;
        address user = msg.sender;

        // handle ETH fees
        if (feeToken == address(0)) {
            for (uint256 i = 0; i < fees.length; i++) {
                totalFee += fees[i].fee;
                fees[i].account.transferEth(fees[i].fee);
            }
        }
        // handle ERC20 fees
        else {
            for (uint256 i = 0; i < fees.length; i++) {
                totalFee += fees[i].fee;
                IERC20(feeToken).safeTransferFrom(user, fees[i].account, fees[i].fee);
            }
        }

        // Delegate call to the adapter contract.
        // solhint-disable-next-line
        (bool success, bytes memory response) = adapter.delegatecall(
            abi.encodeWithSelector(ISwapperAdapter.swap.selector, swapper, data)
        );

        // Revert if call to swapper adapter was not successful.
        require(success, string(response));

        emit FeePayment(feeToken, totalFee);
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

    /// @notice Needed in case a swapper refunds value
    // solhint-disable-next-line
    receive() external payable {}

    modifier onlyAdmin() {
        if (msg.sender != admin) revert LiqProxy__ExecutionNotAuthorized();
        _;
    }
}
