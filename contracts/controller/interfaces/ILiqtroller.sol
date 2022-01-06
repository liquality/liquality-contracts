// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// Onchain decided parameters
interface ILiqtroller {
    /// Emitted when epoch seasl threshold changes
    event NewEpochSealThreshold(uint256 oldEpochSealThreshold, uint256 newEpochSealThreshold);
    /// Emitted when epoch duration changes
    event NewEpochDuration(uint256 oldEpochDuration, uint256 newEpochDuration);

    /// Set the epoch seal threshold
    function setEpochSealThreshold(uint256 newEpochSealThreshold) external;

    /// Set the epoch duration in blocks
    function setEpochDuration(uint256 newEpochDuration) external;
}
