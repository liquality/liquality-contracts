// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// Allows claiming tokens based on merkle tree assigned at an epoch
interface IEpochMerkleDistributor {
    /// Token to distribute.
    function token() external view returns (address);

    /// Returns the address of the contract that provides the merkle root for claiming.
    function merkleRootProvider() external view returns (address);

    /// Returns true if the epoch and index has been marked claimed.
    function isClaimed(uint256 epoch, uint256 index) external view returns (bool);

    /// Claim from the epoch, tokens to the provided address.
    function claim(
        uint256 epoch,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    /// This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 epoch, uint256 index, address account, uint256 amount);
}
