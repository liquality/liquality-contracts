// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// Onchain decided parameters
contract LiqtrollerStorage {
    address public admin;

    modifier onlyAdmin() {
        require(msg.sender == admin, "LiqtrollerStorage: onlyAdmin");
        _;
    }
}

contract LiqtrollerStorageV1 is LiqtrollerStorage {
    /// @notice indicates the required amount of observers' input so the epoch becomes valid
    uint256 public epochSealThreshold;

    /// @notice indicates the epoch duration in blocks
    uint256 public epochDuration;

    /// @notice to become observer, one must stake the specified amount of LIQ
    uint256 public stakeAmount;

    /// @notice to become observer, one must stake LIQ for the specified stake duration
    uint256 public stakeDuration;

    /// @notice the observers should not be allowed to submit merkle root if their stake is expiring,
    /// so the governance will have the time specified by the stakeDurationTreshold to slash the observer if they act maliciously
    uint256 public stakeDurationTreshold;

    /// @notice the total amount of voting power in percentages
    /// 10000 = 100%
    uint256 public votingPowerPercentage;
}
