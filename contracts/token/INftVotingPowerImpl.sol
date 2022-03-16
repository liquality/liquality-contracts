// SPDX-License-Identifier:MIT
pragma solidity >=0.8.10;

interface INftVotingPowerImpl {
    function balanceOf(address) external view returns (uint256);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function claim(bytes calldata data) external returns (bytes memory);
}
