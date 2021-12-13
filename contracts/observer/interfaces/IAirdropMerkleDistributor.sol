// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

/// Allows claiming tokens based on merkle tree assigned at an epoch
interface IAirdropMerkleDistributor {
    struct AirdropClaimRequest {
        uint256 epoch;
        uint256 index;
        uint256 airdropIndex;
        address account;
        uint256 amount;
        bytes32[] merkleProof;
    }

    /// Claim from the epoch, tokens to the provided address.
    function claim(AirdropClaimRequest calldata claimRequest) external;

    /// Batch claim from a number of epics, tokens to the provided address.
    function batchClaim(AirdropClaimRequest[] calldata claimRequests) external;
}
