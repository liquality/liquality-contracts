// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "hardhat/console.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "./interfaces/IEpochMerkleDistributor.sol";
import "./interfaces/IEpochMerkleProvider.sol";

contract EpochMerkleDistributor is IEpochMerkleDistributor {
    using BitMaps for BitMaps.BitMap;

    address public immutable override merkleRootProvider;
    address public immutable override token;

    /// A packaed array of claimed account indexes, per epoch
    mapping(uint256 => BitMaps.BitMap) private claimBitmaps;

    constructor(address _merkleRootProvider, address _token) {
        merkleRootProvider = _merkleRootProvider;
        token = _token;
    }

    function isClaimed(uint256 epoch, uint256 index) public view override returns (bool) {
        return BitMaps.get(claimBitmaps[epoch], index);
    }

    function singleClaim(
        uint256 epoch,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] memory merkleProof
    ) private {
        // Epoch must be sealed and merkle root available before claiming
        require(IEpochMerkleProvider(merkleRootProvider).isEpochSealed(epoch), "EPOCH_NOT_SEALED");
        // Prevent duplicated claiming
        require(!isClaimed(epoch, index), "ALREADY_CLAIMED");

        // Retrieve the merkle root for the epoch
        bytes32 merkleRoot = IEpochMerkleProvider(merkleRootProvider).merkleRoot(epoch);
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));

        require(MerkleProof.verify(merkleProof, merkleRoot, node), "MERKLE_PROOF_VERIFY_FAILED");

        BitMaps.set(claimBitmaps[epoch], index);
        require(IERC20(token).transfer(account, amount), "CLAIM_TRANSFER_FAILED");

        emit Claim(epoch, index, account, amount);
    }

    function claim(
        uint256 epoch,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external override {
        return singleClaim(epoch, index, account, amount, merkleProof);
    }

    function batchClaim(ClaimRequest[] calldata claimRequests) external override {
        // Can only batch claim for 15 epoch at a go, to avoid running out of gas
        require(claimRequests.length <= 15, "MAX_BATCH_CLAIM_EXCEED");

        uint8 successClaims = 0;
        for (uint256 i = 0; i < claimRequests.length; i++) {
            // This trys as much to avoid reverts in the loop and only process batch inputs more likely to succeed
            if (
                !IEpochMerkleProvider(merkleRootProvider).isEpochSealed(claimRequests[i].epoch) ||
                isClaimed(claimRequests[i].epoch, claimRequests[i].index)
            ) {
                continue;
            } else {
                singleClaim(
                    claimRequests[i].epoch,
                    claimRequests[i].index,
                    claimRequests[i].account,
                    claimRequests[i].amount,
                    claimRequests[i].merkleProof
                );
                successClaims++;
            }
        }
        emit BatchClaim(claimRequests.length, successClaims);
    }
}
