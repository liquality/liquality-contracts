// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// Onchain decided parameters
interface ILiqtroller {
    /// Emitted when epoch seasl threshold changes
    event NewEpochSealThreshold(uint256 oldEpochSealThreshold, uint256 newEpochSealThreshold);

    /// Set the epoch seal threshold
    function _setEpochSealThreshold(uint256 newEpochSealThreshold) external;
}
