// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IEpochMerkleDistributor.sol";
import "./interfaces/IEpochMerkleProvider.sol";
import "./libraries/ClaimBitmap.sol";

contract EpochMerkleDistributor is IEpochMerkleDistributor {
    using ClaimBitmap for mapping(uint256 => uint256);

    address public immutable override merkleRootProvider;
    address public immutable override token;

    /// A packaed array of claimed account indexes, per epoch
    mapping(uint256 => mapping(uint256 => uint256)) private claimBitmaps;

    constructor(address _merkleRootProvider, address _token) {
        merkleRootProvider = _merkleRootProvider;
        token = _token;
    }

    function isClaimed(uint256 epoch, uint256 index) public view override returns (bool) {
        return claimBitmaps[epoch].isClaimed(index);
    }

    function claim(
        uint256 epoch,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external override {
        // Epoch must be sealed and merkle root available before claiming
        require(IEpochMerkleProvider(merkleRootProvider).isEpochSealed(epoch), "EPOCH_NOT_SEALED");
        // Prevent duplicated claiming
        require(!isClaimed(epoch, index), "ALREADY_CLAIMED");

        // Retrieve the merkle root for the epoch
        bytes32 merkleRoot = IEpochMerkleProvider(merkleRootProvider).merkleRoot(epoch);
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "MERKLE_PROOF_VERIFY_FAILED");

        claimBitmaps[epoch].setClaimed(index);
        require(IERC20(token).transfer(account, amount), "CLAIM_TRANSFER_FAILED");

        emit Claim(epoch, index, account, amount);
    }
}
