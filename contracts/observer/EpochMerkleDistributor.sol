// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import "./MerkleDistributor.sol";
import "./interfaces/IEpochMerkleDistributor.sol";

contract EpochMerkleDistributor is MerkleDistributor, IEpochMerkleDistributor {
    using BitMaps for BitMaps.BitMap;

    /// A packaed array of claimed account indexes, per epoch
    mapping(uint256 => BitMaps.BitMap) private claimBitmaps;

    constructor(address _merkleRootProvider, address _token)
        MerkleDistributor(_merkleRootProvider, _token)
    // solhint-disable-next-line no-empty-blocks
    {

    }

    function isClaimed(uint256 epoch, uint256 index) public view override returns (bool) {
        return claimBitmaps[epoch].get(index);
    }

    function setClaimed(uint256 epoch, uint256 index) public override {
        claimBitmaps[epoch].set(index);
    }

    function claim(ClaimRequest calldata claimRequest) external override {
        bytes32 node = keccak256(
            abi.encodePacked(claimRequest.index, claimRequest.account, claimRequest.amount)
        );
        _claim(
            claimRequest.epoch,
            claimRequest.index,
            claimRequest.account,
            claimRequest.amount,
            node,
            claimRequest.merkleProof
        );
        require(
            IERC20(token).transfer(claimRequest.account, claimRequest.amount),
            "CLAIM_TRANSFER_FAILED"
        );
    }

    function batchClaim(ClaimRequest[] calldata claimRequests) external override {
        for (uint256 i = 0; i < claimRequests.length; i++) {
            bytes32 node = keccak256(
                abi.encodePacked(
                    claimRequests[i].index,
                    claimRequests[i].account,
                    claimRequests[i].amount
                )
            );
            _claim(
                claimRequests[i].epoch,
                claimRequests[i].index,
                claimRequests[i].account,
                claimRequests[i].amount,
                node,
                claimRequests[i].merkleProof
            );
            require(
                IERC20(token).transfer(claimRequests[i].account, claimRequests[i].amount),
                "CLAIM_TRANSFER_FAILED"
            );
        }
    }
}
