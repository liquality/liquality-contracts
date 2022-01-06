// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

/// Provides merkleroots assigned to a specific epoch.
interface IEpochMerkleProvider {
    /// Returns the merkle root assigned to a specific epoch.
    function merkleRoot(uint256 epoch) external view returns (bytes32);

    /// Returns true if the epoch is sealed (merkleroot is finalised) and it's before the epoch end block.
    function isEpochActive(uint256 epoch) external view returns (bool);
}
