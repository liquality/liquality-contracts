// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;
import "./interfaces/IReferralRegistry.sol";

/**
 * @title A registry for recording referrals
 * @notice For future upgrades, do not change GovernorBravoDelegateStorageV1. Create a new
 * contract which implements GovernorBravoDelegateStorageV1 and following the naming convention
 * GovernorBravoDelegateStorageVX.
 */
contract ReferralRegistry is IReferralRegistry {
    address public controller;
    mapping(address => Referral) private referralMap;

    modifier onlyController() {
        if (msg.sender != controller) {
            revert OnlyControllerAllowed();
        }
        _;
    }

    constructor(address _controller) {
        controller = _controller;
    }

    /// @inheritdoc IReferralRegistry
    function getReferral(address referee) public view returns (Referral memory) {
        return referralMap[referee];
    }

    /// @inheritdoc IReferralRegistry
    function registerReferral(address referrer, address referee) public onlyController {
        if (referrer == address(0) || referee == address(0)) {
            revert InvalidAddress();
        }

        if (referrer == referee) {
            revert RefferringSelfNotAllowed();
        }

        if (referralMap[referee].referrer != address(0)) {
            revert RefereeAlreadyRegistered();
        }

        referralMap[referee] = Referral({referrer: referrer, blockNumber: block.number});

        emit ReferralRegistered(referrer, referee);
    }
}
