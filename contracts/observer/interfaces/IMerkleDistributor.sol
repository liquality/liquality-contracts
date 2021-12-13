// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

/// Allows claiming tokens based on merkle tree assigned at an epoch
interface IMerkleDistributor {
    /// Event triggered when claim is successful.
    event Claim(uint256 epoch, uint256 index, address account, uint256 amount);

    /// Token distributed by the merkle root.
    function token() external view returns (address);

    /// Returns the address of the contract that provides the merkle root for claiming.
    function merkleRootProvider() external view returns (address);
}
