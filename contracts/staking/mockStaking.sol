// SPDX-License-Identifier:MIT

//@title MockStaking Contract

pragma solidity >=0.8.4;

import "./LiqStaking.sol";

contract MockStaking is LiqStaking {
    constructor(IERC20 liq) LiqStaking(liq) {}

    function getCurrentTs() external view returns (uint256) {
        return block.timestamp;
    }

    function addStakeNoMinLimit(uint256 amount, uint256 unlockTime) external {
        Stake memory stakeInfo = stakings[msg.sender];

        require(amount > 0, "Amount not valid"); // dev: need non-zero value
        require(stakeInfo.amount == 0, "Withdraw old tokens first");
        require(unlockTime <= block.timestamp + MAXTIME, "Unlock time cannot exceed max lock");

        _depositFor(msg.sender, amount, unlockTime, stakeInfo, CREATE_LOCK_TYPE);
    }
}
