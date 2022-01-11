// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

/// Allows observers to submit their calculated merkle roots.
interface IEpochObserverHandler {
    /// Submit a merklroot for a given epoch.
    function submitMerkleRoot(uint256, bytes32) external;

    /// Event emitted when an epoch is sealed.
    event SealEpoch(uint256 indexed epoch, bytes32 indexed merkleRoot);
}
