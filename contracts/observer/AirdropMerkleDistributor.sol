// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import "./MerkleDistributor.sol";
import "./interfaces/IAirdropMerkleDistributor.sol";
import "./interfaces/IVestedMerkleDistributor.sol";
import "./interfaces/ISablier.sol";

contract AirdropMerkleDistributor is
    MerkleDistributor,
    IAirdropMerkleDistributor,
    IVestedMerkleDistributor
{
    using BitMaps for BitMaps.BitMap;

    /// A packaed array of claimed account indexes, per epoch
    BitMaps.BitMap private airDropClaimBitmap;

    ISablier public constant SABLIER = ISablier(0xCD18eAa163733Da39c232722cBC4E8940b1D8888);
    uint256 public constant VESTING_DURATION = 60 days;

    constructor(address _merkleRootProvider, address _token)
        MerkleDistributor(_merkleRootProvider, _token)
    {
        IERC20(token).approve(address(SABLIER), type(uint256).max);
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

        SABLIER.createStream(
            claimRequest.account,
            claimRequest.amount,
            token,
            block.timestamp,
            block.timestamp + VESTING_DURATION
        );
    }

    function batchClaim(AirdropClaimRequest[] calldata claimRequests) external override {
        uint256 vestingEnd = block.timestamp + VESTING_DURATION;

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

            SABLIER.createStream(
                claimRequests[i].account,
                claimRequests[i].amount,
                token,
                block.timestamp,
                vestingEnd
            );
        }
    }

    function getPendingAmount(uint256 streamId, address who)
        external
        view
        override
        returns (uint256 balance)
    {
        return SABLIER.balanceOf(streamId, who);
    }

    function withdrawPendingAmount(uint256 streamId, uint256 funds)
        external
        override
        returns (bool)
    {
        return SABLIER.withdrawFromStream(streamId, funds);
    }
}
