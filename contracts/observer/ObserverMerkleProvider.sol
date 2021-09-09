// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "hardhat/console.sol";
import "./interfaces/IEpochMerkleProvider.sol";
import "./interfaces/IEpochObserverHandler.sol";

contract ObserverMerkleProvider is IEpochMerkleProvider, IEpochObserverHandler {
    /// Threshold of merkle roots after which epoch is considered finalized
    /// @dev TODO: This will need to be governance decided or based on staked LIQ
    uint256 private constant SEALED_THRESHOLD = 3;

    /// @dev This is a simple implementation counting the merkle roots for an epoch.
    /// TODO: eventually this will need to considered stake
    mapping(uint256 => mapping(bytes32 => uint256)) public merkleRootCounts;

    /// A mapping of epoch to merkle root that is finalized.
    mapping(uint256 => bytes32) public sealedMerkleRoots;

    /// A mapping
    /// @dev TODO: optimise into a bitmap
    mapping(uint256 => mapping(address => bool)) public submittedObservers;

    /// List of merkle roots for a given epoch.
    /// Potentially usable?
    /// mapping(uint256 => bytes32[]) public epochMerkleRoots;

    uint256 public lastEpoch = 0;

    /// @dev Epochs must not be sealed and go forward.
    modifier onlyValidEpoch(uint256 epoch) {
        require(sealedMerkleRoots[epoch] == bytes32(0x0), "EPOCH_ALREADY_SEALED");
        require(epoch > lastEpoch, "EPOCH_INVALID");
        _;
    }

    /// @dev An observer can only submit merkle root once for an epoch
    modifier submitOnce(uint256 epoch, address observer) {
        require(submittedObservers[epoch][observer] == false, "OBSERVER_VOTED_ALREADY");
        _;
        submittedObservers[epoch][observer] = true;
    }

    /// @inheritdoc IEpochMerkleProvider
    function isEpochSealed(uint256 epoch) external view override returns (bool) {
        return sealedMerkleRoots[epoch] != bytes32(0x0);
    }

    /// @inheritdoc IEpochMerkleProvider
    function merkleRoot(uint256 epoch) external view override returns (bytes32) {
        return sealedMerkleRoots[epoch];
    }

    function sealEpoch(uint256 epoch, bytes32 _merkleRoot) private {
        sealedMerkleRoots[epoch] = _merkleRoot;
        lastEpoch = epoch;
        emit SealEpoch(epoch, _merkleRoot);
    }

    /// @inheritdoc IEpochObserverHandler
    function submitMerkleRoot(uint256 epoch, bytes32 _merkleRoot)
        external
        override
        onlyValidEpoch(epoch)
        submitOnce(epoch, msg.sender)
    {
        merkleRootCounts[epoch][_merkleRoot]++;
        if (merkleRootCounts[epoch][_merkleRoot] >= SEALED_THRESHOLD) {
            sealEpoch(epoch, _merkleRoot);
        }
    }
}
