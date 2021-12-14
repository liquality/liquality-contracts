// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface IVestedMerkleDistributor {
    function withdrawPendingAmount(uint256 streamId, uint256 funds) external returns (bool);

    function getPendingAmount(uint256 streamId, address who)
        external
        view
        returns (uint256 balance);
}
