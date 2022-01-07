// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface IObserverStaking {
    struct StakeData {
        uint256 amount;
        uint256 expireBlock;
    }

    function slash(address observer, uint256 amount) external;

    /// @notice Stakes LIQ to be eligible to produce merkle roots
    /// The amount and duration are set by the governance and they reside inside the Liqtroller
    function stake() external;

    function unstake() external;

    function extend(uint256 amount, uint256 blocks) external;

    function isObserverEligible(address observer) external view returns (bool);

    /// @notice An event emitted when a successful stake is recorded
    /// @param observer The observer address
    /// @param amount The amount staked
    /// @param expiresAt The block at which the stake expires and can be unstaked
    event ObserverStaked(address observer, uint256 amount, uint256 expiresAt);

    /// @notice An event emitted when a successful unstake is recorded
    /// @param observer The observer address
    /// @param amount The amount unstaked
    event ObserverUnstaked(address observer, uint256 amount);

    /// @notice An event emitted when a the governance performs a slash
    /// @param observer The observer address
    /// @param slashedAmount The slashed amount
    event ObserverSlashed(address observer, uint256 slashedAmount);

    /// @notice Observers cannot unstake before the expire block
    error ObserverStaking__StakeNotExpired();

    /// @notice Cannot extend stakes that does not exists
    error ObserverStaking__CannotExtendNonExistentStake();

    /// @notice Emitted when the caller is not the governance
    error ObserverStaking__ExecutionNotAuthorized(address governance, address caller);

    /// @notice Emitted when the slash amount exceeds observer stake
    error ObserverStaking__InvalidSlashAmount(uint256 observerAmount, uint256 slashAmount);

    /// @notice The amount should match the amount specified by the governance
    error InvalidStakeAmount();
}
