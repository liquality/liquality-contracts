// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "./interfaces/IMerkleDistributor.sol";
import "./interfaces/IEpochMerkleProvider.sol";

abstract contract MerkleDistributor is IMerkleDistributor {
    address public immutable merkleRootProvider;
    address public immutable token;

    constructor(address _merkleRootProvider, address _token) {
        merkleRootProvider = _merkleRootProvider;
        token = _token;
    }

    function isClaimed(uint256 epoch, uint256 index) public view virtual returns (bool);

    function setClaimed(uint256 epoch, uint256 index) public virtual;

    function _claim(
        uint256 epoch,
        uint256 index,
        address account,
        uint256 amount,
        bytes32 node,
        bytes32[] memory merkleProof
    ) internal {
        // Epoch must be sealed and merkle root available before claiming
        require(IEpochMerkleProvider(merkleRootProvider).isEpochActive(epoch), "EPOCH_NOT_ACTIVE");
        // Prevent duplicated claiming
        require(!isClaimed(epoch, index), "ALREADY_CLAIMED");

        // Retrieve the merkle root for the epoch
        bytes32 merkleRoot = IEpochMerkleProvider(merkleRootProvider).merkleRoot(epoch);

        require(MerkleProof.verify(merkleProof, merkleRoot, node), "MERKLE_PROOF_VERIFY_FAILED");

        // set claimed bit to avoid duplicate claims
        setClaimed(epoch, index);

        // transfer tokens
        require(IERC20(token).transfer(account, amount), "CLAIM_TRANSFER_FAILED");

        emit Claim(epoch, index, account, amount);
    }
}
