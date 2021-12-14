// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface IVestedMerkleDistributor {
    function withdrawFromStream(uint256 streamId, uint256 funds) external returns (bool);

    function balanceOf(uint256 streamId, address who) external view returns (uint256 balance);
}
