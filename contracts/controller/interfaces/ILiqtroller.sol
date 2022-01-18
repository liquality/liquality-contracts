// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// Onchain decided parameters
interface ILiqtroller {
    /// Emitted when epoch seal threshold changes
    event NewEpochSealThreshold(uint256 oldEpochSealThreshold, uint256 newEpochSealThreshold);
    /// Emitted when epoch duration changes
    event NewEpochDuration(uint256 oldEpochDuration, uint256 newEpochDuration);
    /// Emitted when stake amount changes
    event NewStakeAmount(uint256 oldStakeAmount, uint256 newStakeAmount);
    /// Emitted when stake duration changes
    event NewStakeDuration(uint256 oldStakeDuration, uint256 newStakeDuration);
    /// Emitted when stake duration threshold changes
    event NewStakeDurationThreshold(
        uint256 oldStakeDurationThreshold,
        uint256 newStakeDurationThreshold
    );

    /// Set the epoch seal threshold
    function setEpochSealThreshold(uint256 newEpochSealThreshold) external;

    /// Set the epoch duration in blocks
    function setEpochDuration(uint256 newEpochDuration) external;

    /// Set the new stake amount
    function setStakeAmount(uint256 newStakeAmount) external;

    /// Set the new stake duration in blocks
    function setStakeDuration(uint256 newStakeDuration) external;

    /// Set the new stake duration threshold
    function setStakeDurationThreshold(uint256 newStakeDurationThreshold) external;

    function getStakeParameters()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}
