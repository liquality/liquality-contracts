// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import "./MerkleDistributor.sol";
import "./interfaces/IAirdropMerkleDistributor.sol";

contract AirdropMerkleDistributor is MerkleDistributor, IAirdropMerkleDistributor {
    using BitMaps for BitMaps.BitMap;

    /// A packaed array of claimed account indexes, per epoch
    BitMaps.BitMap private airDropClaimBitmap;

    constructor(address _merkleRootProvider, address _token)
        MerkleDistributor(_merkleRootProvider, _token)
    // solhint-disable-next-line no-empty-blocks
    {

    }

    function isClaimed(uint256, uint256 airdropIndex) public view override returns (bool) {
        return airDropClaimBitmap.get(airdropIndex);
    }

    function setClaimed(uint256, uint256 airdropIndex) public override {
        airDropClaimBitmap.set(airdropIndex);
    }

    function claim(AirdropClaimRequest calldata claimRequest) external override {
        bytes32 node = keccak256(
            abi.encodePacked(
                claimRequest.index,
                claimRequest.airdropIndex,
                claimRequest.account,
                claimRequest.amount
            )
        );
        _claim(
            claimRequest.epoch,
            claimRequest.airdropIndex,
            claimRequest.account,
            claimRequest.amount,
            node,
            claimRequest.merkleProof
        );
    }

    function batchClaim(AirdropClaimRequest[] calldata claimRequests) external override {
        for (uint256 i = 0; i < claimRequests.length; i++) {
            bytes32 node = keccak256(
                abi.encodePacked(
                    claimRequests[i].index,
                    claimRequests[i].airdropIndex,
                    claimRequests[i].account,
                    claimRequests[i].amount
                )
            );
            _claim(
                claimRequests[i].epoch,
                claimRequests[i].airdropIndex,
                claimRequests[i].account,
                claimRequests[i].amount,
                node,
                claimRequests[i].merkleProof
            );
        }
    }
}
