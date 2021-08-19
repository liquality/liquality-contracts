// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// Provides merkleroots assigned to a specific epoch.
interface IEpochMerkleProvider {
    /// Returns the merkle root assigned to a specific epoch.
    function merkleRoot(uint256 epoch) external view returns (bytes32);

    /// Returns true if the epoch is sealed and a merkleroot is finalised.
    function isEpochSealed(uint256 epoch) external view returns (bool);
}
