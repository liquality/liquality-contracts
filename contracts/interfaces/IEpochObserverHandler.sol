// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// Allows observers to submit their calculated merkle roots.
interface IEpochObserverHandler {
    /// Returns the merkle root assigned to a specific epoch.
    function submitMerkleRoot(uint256, bytes32) external;

    /// Returns the merkle root assigned to a specific epoch.
    function isEpochSealed(uint256 epoch) external view returns (bool);

    event SealEpoch(uint256 indexed epoch, bytes32 indexed merkleRoot);
}
