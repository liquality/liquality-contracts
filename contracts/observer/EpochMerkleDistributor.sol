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

    function _claim(
        uint256 epoch,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] memory merkleProof
    ) internal {
        // Epoch must be sealed and merkle root available before claiming
        require(IEpochMerkleProvider(merkleRootProvider).isEpochActive(epoch), "EPOCH_NOT_SEALED");
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

    function claim(ClaimRequest calldata claimRequest) external override {
        return
            _claim(
                claimRequest.epoch,
                claimRequest.index,
                claimRequest.account,
                claimRequest.amount,
                claimRequest.merkleProof
            );
    }

    function batchClaim(ClaimRequest[] calldata claimRequests) external override {
        for (uint256 i = 0; i < claimRequests.length; i++) {
            _claim(
                claimRequests[i].epoch,
                claimRequests[i].index,
                claimRequests[i].account,
                claimRequests[i].amount,
                claimRequests[i].merkleProof
            );
        }
    }
}
