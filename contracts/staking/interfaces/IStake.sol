// SPDX-License-Identifier:MIT

//@title Stake interface

pragma solidity >=0.8.4;

interface IStake {
    function setMinLock(uint32 minLock) external;

    function setMaxLock(uint32 minLock) external;

    // Add LIQ token for staking, get back proportional sLIQ and additional sLIQ as reward for longer voting periods
    function addStake(uint256 amount, uint256 unlockTime) external; // Deposit

    // Send back sLIQ to withdraw LIQ stake
    function removeStake() external; // Withdraw

    // Increase amount of LIQ locked and get back proportional sLIQ
    function increaseStake(uint256 amount) external;

    // Increase duration of LIQ locked and get more sLIQ as reward
    function increaseLock(uint256 amount) external;

    // Smart account checker interface

    event MinLockUpdated(uint256 prevMinLock, uint256 newMinLock);
    event MaxLockUpdated(uint256 prevMaxLock, uint256 newMaxLock);
    event Supply(uint256 prevSupply, uint256 supply);
    event StakeRemoved(address indexed staker, uint256 amount, uint256 timeStamp); // Withdraw
    event StakeAdded(
        address indexed staker,
        uint256 amount,
        uint256 indexed locktime,
        uint128 actionType,
        uint256 timeStamp
    ); // Deposit

    event WhitelistedChanged(address indexed user, bool indexed whitelisted);
    event StakeIncreased(address staker, uint256 amount);
}
