// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

/// Allows claiming tokens based on merkle tree assigned at an epoch
interface IEpochMerkleDistributor {
    struct ClaimRequest {
        uint256 epoch;
        uint256 index;
        address account;
        uint256 amount;
        bytes32[] merkleProof;
    }

    /// Claim from the epoch, tokens to the provided address.
    function claim(ClaimRequest calldata claimRequest) external;

    /// Batch claim from a number of epics, tokens to the provided address.
    function batchClaim(ClaimRequest[] calldata claimRequests) external;
}
