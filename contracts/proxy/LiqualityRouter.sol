// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ILiqualityRouter.sol";
import "./interfaces/ILiqualityProxy.sol";
import "./LibTransfer.sol";
import "../referrals/interfaces/IReferralRegistry.sol";

contract LiqualityRouter is ILiqualityRouter {
    using LibTransfer for address;
    using SafeERC20 for IERC20;

    ILiqualityProxy public liqualityProxy;
    IReferralRegistry public referralRegistry;

    constructor(address _liqualityProxy) {
        liqualityProxy = ILiqualityProxy(_liqualityProxy);
    }

    function routeWithReferral(
        address target,
        address tokenFrom,
        address referrer,
        uint256 amount,
        bytes calldata data,
        FeeData[] calldata fees
    ) external payable {
        address user = msg.sender;
        // handle referrals
        Referral memory referral = referralRegistry.getReferral(user);
        if (referral.referrer != address(0x0)) {
            referralRegistry.registerReferral(referrer, user);
        }
        _route(target, user, tokenFrom, amount, data, fees);
    }

    function route(
        address target,
        address tokenFrom,
        uint256 amount,
        bytes calldata data,
        FeeData[] calldata fees
    ) external payable {
        _route(target, msg.sender, tokenFrom, amount, data, fees);
    }

    function _route(
        address target,
        address from,
        address tokenFrom,
        uint256 amount,
        bytes calldata data,
        FeeData[] calldata fees
    ) internal {
        uint256 totalFee = 0;
        // handle ETH fees
        if (tokenFrom == address(0)) {
            for (uint256 i = 0; i < fees.length; i++) {
                totalFee += fees[i].fee;
                fees[i].account.transfer(fees[i].fee);
            }
        }
        // handle ERC20 fees
        else {
            IERC20(tokenFrom).safeTransferFrom(from, address(liqualityProxy), amount);
            for (uint256 i = 0; i < fees.length; i++) {
                IERC20(tokenFrom).safeTransferFrom(from, fees[i].account, fees[i].fee);
            }
        }

        require(
            liqualityProxy.execute{value: msg.value - totalFee}(target, data),
            "proxy call failed"
        );

        emit Routed(target, tokenFrom, data);
    }
}
