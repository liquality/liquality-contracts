// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// Provides merkleroots assigned to a specific epoch.
interface IEpochMerkleProvider {
    /// Returns the merkle root assigned to a specific epoch.
    function merkleRoot(uint256) external view returns (bytes32);
}
