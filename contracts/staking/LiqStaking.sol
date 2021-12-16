// SPDX-License-Identifier:MIT

//@title LiqStaking Contract
//@author Liquality
//@notice For every LIQ staked, a corresponding sLIQ (vote power) is minted to staker, value of sLIQ minted is based on the staking duration.
//Votes have a weight depending on time, so that users are committed to the future of
//(whatever they are voting for; incentiving users to continue to stake inorder to increase vote weight)
//@dev Vote weight decays linearly over time. Lock time cannot be more than `MAXTIME` (5 years).
//# Voting escrow to have time-weighted votes
//# The weight in this implementation is linear, linearly decaying with time, and lock cannot be more than maxtime:
//# w ^
//# 1 +        /
//#   |      /
//#   |    /
//#   |  /
//#   |/
//# 0 +--------+------> time
//#       maxtime (5 years?)

//Notes :
//Admin should be the governance contract
//Check uint128 addiotions for safeMaths
//Add ; to all lines
//confirm variable naming
//remove duplicate functions
//Add @dev; @notice to all functions
//Update comment descriptions
//Add reentrancy guard
//Refactor assets for modifier
//Refactor out all binary search into a func
// Implement set min and max lock

pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20NonTransfer.sol";
import "./IStake.sol";

// REMOVE
import "hardhat/console.sol";

contract LiqStaking is ERC20NonTransferable("LIQ Staking", "sLIQ"), Ownable, IStake {
    using SafeERC20 for IERC20;
    IERC20 public Liq;

    /// @notice Staking Info
    struct Stake {
        uint256 amount;
        uint256 stackedAt;
        uint256 lockEnd;
    }

    /// @notice Point Info for tracking voting weight
    // We cannot really do block numbers per se b/c slope is per time, not per block
    // and per block could be fairly bad b/c Ethereum changes blocktimes.
    // What we can do is to extrapolate ***At functions
    struct Point {
        uint128 bias;
        uint128 slope; // dweight / dt [Rate of decay of voting power as time tends towards the lock time]
        uint256 ts;
        uint256 blk;
    }

    uint128 constant DEPOSIT_FOR_TYPE = 0;
    uint128 constant CREATE_LOCK_TYPE = 1;
    uint128 constant INCREASE_LOCK_AMOUNT = 2;
    uint128 constant INCREASE_UNLOCK_TIME = 3;

    uint256 public epoch;
    uint256 public supply;

    uint256 public WEEK = 7 * 86400; // all future times are rounded by week
    uint256 public MONTH = 30 * 86400;
    uint256 public YEAR = 365 * 86400;
    uint256 public MINTIME;
    uint256 public MAXTIME;
    uint256 public MULTIPLIER = 10**18;

    //@notice Record of user account staking
    mapping(address => Stake) public stakings;
    mapping(address => bool) public whitelisted;

    Point[100000000000000000000000000000] public pointHistory; // epoch -> unsigned point
    mapping(address => uint256) public lastUserPointIndex; // Last user point index
    mapping(address => Point[1000000000]) public userPointHistory; // user -> Point[user_epoch]
    mapping(uint256 => uint128) public slopeChanges; // time -> signed slope change

    // Modifier : Only allow un-staking if lock period is fully reached
    modifier MustCallFromEOAOrWhitelisted(address receiver) {
        // only allow whitelisted contracts or EOAS
        require(
            tx.origin == _msgSender() || whitelisted[_msgSender()],
            "Only EOA or whitelisted address allowed"
        );
        // only allow whitelisted addresses to deposit to another address
        require(
            _msgSender() == receiver || whitelisted[_msgSender()],
            "Only whitelisted address can stake to another address"
        );
        _;
    }

    constructor(IERC20 liq) {
        Liq = liq;
        pointHistory[0] = Point(0, 0, block.timestamp, block.number);
        MINTIME = 30 * 86400; // Starting with min lock time as 1month
        MAXTIME = 5 * 365 * 86400; // Starting with min lock time as 5years
    }

    function setMinLock(uint32 minLock) external override onlyOwner {
        uint256 minLockInSeconds = minLock * 86400;
        require(
            minLockInSeconds > 0 && minLockInSeconds < MAXTIME,
            "INVALIDLOCK : Min lock time must be greater than zero and less than max lock"
        );
        uint256 prevMinLock = MINTIME;
        MINTIME = minLockInSeconds;
        emit MinLockUpdated(prevMinLock / 86400, minLock);
    }

    // Lock in days
    function setMaxLock(uint32 maxLock) external override onlyOwner {
        uint256 maxLockInSeconds = maxLock * 86400;
        require(
            maxLockInSeconds > 0 && maxLockInSeconds > MINTIME,
            "INVALIDLOCK : Lock time must be greater than zero and greater than min lock"
        );
        uint256 prevMaxLock = MAXTIME;
        MAXTIME = maxLockInSeconds;
        emit MaxLockUpdated(prevMaxLock / 86400, maxLock);
    }

    // The goal is to prevent tokenizing the escrow
    //# Checker for whitelisted (smart contract) wallets which are allowed to deposit
    function setWhitelisted(address user, bool isWhitelisted) external onlyOwner {
        whitelisted[user] = isWhitelisted;
        emit WhitelistedChanged(user, isWhitelisted);
    }

    // @notice : Get the most recently recorded rate of voting power decrease for `account`
    // @param account : Address of the user wallet
    // @returns : Value of the slope
    function getLastUserSlope(address account) external view returns (uint128) {
        uint256 userPointIndex = lastUserPointIndex[account];
        return userPointHistory[account][userPointIndex].slope;
    }

    // @notice : Get the timestamp for checkpoint `userEpoch` for `account`
    // @param account : Address of the user wallet
    // @param userPointIndex : Index of user epoch number
    // @returns : Epoch time of the checkpoint
    function userPointHistoryTimestamp(address account, uint256 userPointIndex)
        external
        view
        returns (uint256)
    {
        return userPointHistory[account][userPointIndex].ts;
    }

    // @notice : Get staking info for a user
    // @param account : Address of the user wallet
    // @returns : Staking info
    function stakeInfo(address account) external view returns (Stake memory) {
        return stakings[account];
    }

    // @notice : Record global and per-user data to checkpoint
    // @param account : Address of the user wallet
    // @param prevStake : Pevious locked amount / end lock time for the user
    // @param newStake : New locked amount / end lock time for the user
    // @returns : Epoch time of the checkpoint
    function _checkpoint(
        address account,
        Stake memory prevStake,
        Stake memory newStake
    ) internal {
        Point memory prevPoint;
        Point memory newPoint;
        uint128 oldSlope;
        uint128 newSlope;
        uint256 _epoch = epoch;

        if (account != address(0)) {
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (prevStake.lockEnd > block.timestamp && prevStake.amount > 0) {
                prevPoint.slope = SafeCast.toUint128(prevStake.amount / MAXTIME);
                prevPoint.bias =
                    prevPoint.slope *
                    SafeCast.toUint128(prevStake.lockEnd - block.timestamp);
            }
            if (newStake.lockEnd > block.timestamp && newStake.amount > 0) {
                newPoint.slope = SafeCast.toUint128(newStake.amount / MAXTIME);
                newPoint.bias =
                    newPoint.slope *
                    SafeCast.toUint128(newStake.lockEnd - block.timestamp);
            }

            // Read values of scheduled changes in the slope
            // prevStake.lockEnd can be in the past and in the future
            // newStake.lockEnd can ONLY by in the FUTURE unless everything expired: than zeros
            oldSlope = slopeChanges[prevStake.lockEnd];
            if (newStake.lockEnd != 0) {
                if (newStake.lockEnd == prevStake.lockEnd) {
                    newSlope = oldSlope;
                } else {
                    newSlope = slopeChanges[newStake.lockEnd];
                }
            }
        }

        Point memory lastPoint = Point({bias: 0, slope: 0, ts: block.timestamp, blk: block.number});
        if (_epoch > 0) {
            lastPoint = pointHistory[_epoch];
        }
        uint256 lastCheckpoint = lastPoint.ts;

        // initialLastPoint is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case
        Point memory initialLastPoint = lastPoint;
        uint256 blockslope = 0; // dblock/dt
        if (block.timestamp > lastPoint.ts) {
            blockslope =
                MULTIPLIER *
                ((block.number - (lastPoint.blk)) / (block.timestamp - (lastPoint.ts)));
        }

        // Go over weeks to fill history and calculate what the current point is
        uint256 t_i = WEEK * (lastCheckpoint / WEEK);
        for (uint256 i; i < 255; i++) {
            // Hopefully it won't happen that this won't get used in 5 years!
            // If it does, users will be able to withdraw but vote weight will be broken
            t_i = t_i + WEEK;
            uint128 d_slope;
            if (t_i > block.timestamp) {
                t_i = block.timestamp;
            } else {
                d_slope = slopeChanges[t_i];
            }

            lastPoint.bias =
                lastPoint.bias -
                (lastPoint.slope * SafeCast.toUint128(t_i - (lastCheckpoint)));
            lastPoint.slope = lastPoint.slope + d_slope;
            // This can happen
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
            // This cannot happen - just in case
            if (lastPoint.slope < 0) {
                lastPoint.slope = 0;
            }
            lastCheckpoint = t_i;
            lastPoint.ts = t_i;
            lastPoint.blk =
                initialLastPoint.blk +
                (blockslope) *
                ((t_i - initialLastPoint.ts) / MULTIPLIER);
            _epoch = _epoch + 1;

            if (t_i == block.timestamp) {
                lastPoint.blk = block.number;
                break;
            } else {
                pointHistory[_epoch] = lastPoint;
            }
        }
        // Now point_history is filled until t=now
        epoch = _epoch;

        // If last point was in this block, the slope change has been applied already
        // But in such case we have 0 slope(s)
        if (account != address(0)) {
            lastPoint.slope = lastPoint.slope + (newPoint.slope - prevPoint.slope);
            lastPoint.bias = lastPoint.bias + (newPoint.bias - prevPoint.bias);

            if (lastPoint.slope < 0) {
                lastPoint.slope = 0;
            }
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
        }

        //Record the changed point into history
        pointHistory[_epoch] = lastPoint;

        // Schedule the slope changes (slope is going down)
        // We subtract newPoint.slope from [newStake.lockEnd]
        // and add prevPoint.slope to [prevStake.lockEnd]
        if (account != address(0)) {
            if (prevStake.lockEnd > block.timestamp) {
                // oldSlope was <something> - prevPoint.slope, so we cancel that
                oldSlope = oldSlope + prevPoint.slope;
                if (newStake.lockEnd == prevStake.lockEnd) {
                    oldSlope = oldSlope - newPoint.slope; // It was a new deposit, not extension
                }
                slopeChanges[prevStake.lockEnd] = oldSlope;
            }

            if (newStake.lockEnd > block.timestamp) {
                if (newStake.lockEnd > prevStake.lockEnd) {
                    newSlope = newSlope - newPoint.slope; // old slope disappeared at this point
                    slopeChanges[newStake.lockEnd] = newSlope;
                } // else, we recorded it already in old_dslope
            }

            // Now handle user history
            _handleCheckpointHistory(account, newPoint);
        }
    }

    function _handleCheckpointHistory(address account, Point memory newPoint) internal {
        lastUserPointIndex[account] = lastUserPointIndex[account] + 1;
        newPoint.ts = block.timestamp;
        newPoint.blk = block.number;
        userPointHistory[account][lastUserPointIndex[account]] = newPoint;
    }

    // @notice : Record global data to checkpoint
    function checkpoint() external {
        Stake memory stakedBal;
        _checkpoint(address(0), stakedBal, stakedBal);
    }

    //    @notice Deposit and lock tokens for a user
    //    @param account User's wallet address
    //    @param amount Amount to deposit
    //    @param unlockTime New time when to unlock the tokens, or 0 if unchanged
    //    @param stakeInfo : Previous locked amount / timestamp
    function _depositFor(
        address account,
        uint256 amount,
        uint256 unlockTime,
        Stake memory stakeInfo,
        uint128 actionType
    ) internal {
        Stake memory stakedBal = stakeInfo;
        uint256 supplyBefore = supply;
        supply = supplyBefore + amount;
        Stake memory prevStake = stakedBal;
        // Adding to existing lock, or if a lock is expired - creating a new one
        stakedBal.amount = stakedBal.amount + SafeCast.toUint128(amount); // Needs uint128 addition
        if (unlockTime != 0) {
            stakeInfo.lockEnd = unlockTime;
        }
        stakings[account] = stakeInfo;
        // Possibilities:
        // Both prevStake.lockEnd could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // stakeInfo.lockEnd > block.timestamp (always)
        _checkpoint(account, prevStake, stakeInfo);
        if (amount != 0) {
            Liq.safeTransferFrom(account, address(this), amount);
        }
        emit StakeAdded(account, amount, stakeInfo.lockEnd, actionType, block.timestamp); // import curve types here
        emit Supply(supplyBefore, supplyBefore + amount);
    }

    // @notice : Stake `amount` tokens for `account` and add to the lock
    // @dev Anyone (even a smart contract) can deposit for someone else, but
    // cannot extend their locktime and deposit for a brand new user
    // @param account: User's wallet address
    // @param amount: Amount to stake
    function addStakeFor(address account, uint256 amount) external {
        Stake memory stakeInfo = stakings[account];

        require(amount > 0, "Cannot stake a 0 amount");
        require(stakeInfo.amount > 0, "No existing lock found");
        require(stakeInfo.lockEnd > block.timestamp, "Cannot add to expired lock.");

        _depositFor(account, amount, 0, stakings[account], DEPOSIT_FOR_TYPE);
    }

    // @notice Deposit `amount` tokens for `msg.sender` and lock until `_unlock_time`
    // @param account User's wallet address
    // @param unlockTime : Epoch time when tokens unlock, rounded down to whole weeks
    function addStake(uint256 amount, uint256 unlockTime)
        external
        override
        MustCallFromEOAOrWhitelisted(msg.sender)
    {
        Stake memory stakeInfo = stakings[msg.sender];

        require(amount > 0, "Amount not valid"); // dev: need non-zero value
        require(stakeInfo.amount == 0, "Withdraw old tokens first");
        require(
            unlockTime >= block.timestamp + MINTIME,
            "unlock time must be greater than minimun lock time"
        );
        require(unlockTime <= block.timestamp + MAXTIME, "Unlock time cannot exceed max lock");

        _depositFor(msg.sender, amount, unlockTime, stakeInfo, CREATE_LOCK_TYPE);
    }

    // @notice Deposit `amount` additional tokens for `msg.sender`
    //  without modifying the unlock time
    // @param amount : Amount of tokens to deposit and add to the lock
    function increaseStake(uint256 amount)
        external
        override
        MustCallFromEOAOrWhitelisted(msg.sender)
    {
        Stake memory stakeInfo = stakings[msg.sender];

        require(amount > 0, "Cannot stake a 0 amount");
        require(stakeInfo.amount > 0, "No existing lock found");
        require(stakeInfo.lockEnd > block.timestamp, "Cannot add to expired lock. Withdraw");

        _depositFor(msg.sender, amount, 0, stakeInfo, INCREASE_LOCK_AMOUNT);
    }

    // @notice Extend the unlock time for `msg.sender` to `unlockTime`
    // @param unlockTime : New epoch time for unlocking
    function increaseLock(uint256 unlockTime)
        external
        override
        MustCallFromEOAOrWhitelisted(msg.sender)
    {
        uint256 unlockTimeInWeeks = (unlockTime / WEEK) * WEEK; // Locktime is rounded down to weeks
        Stake memory stakeInfo = stakings[msg.sender];

        require(stakeInfo.lockEnd > block.timestamp, "Lock expired");
        require(stakeInfo.amount > 0, "Nothing is locked");
        require(unlockTimeInWeeks > stakeInfo.lockEnd, "Can only increase lock duration");
        require(stakeInfo.lockEnd <= block.timestamp + MAXTIME, "Voting lock can be 4 years max");

        _depositFor(msg.sender, 0, unlockTimeInWeeks, stakeInfo, INCREASE_UNLOCK_TIME);
    }

    // @notice Withdraw all tokens for `msg.sender`
    // @dev Only possible if the lock has expired
    function removeStake() external override MustCallFromEOAOrWhitelisted(msg.sender) {
        Stake memory stakeInfo = stakings[msg.sender];

        require(block.timestamp >= stakeInfo.lockEnd, "The lock didn't expire");
        uint256 amountToWithdraw = stakeInfo.amount;

        Stake memory prevStake = stakeInfo;
        stakeInfo.lockEnd = 0;
        stakeInfo.amount = 0;
        stakings[msg.sender] = stakeInfo;

        uint256 supplyBefore = supply;
        supply = supplyBefore - amountToWithdraw;

        // prevStake can have either expired <= timestamp or zero end
        // stakeInfo has only 0 end
        // Both can have >= 0 amount
        _checkpoint(msg.sender, prevStake, stakeInfo);
        Liq.safeTransfer(msg.sender, amountToWithdraw);

        emit StakeRemoved(msg.sender, amountToWithdraw, block.timestamp);
        emit Supply(supplyBefore, supplyBefore - amountToWithdraw);
    }

    // @note : The following ERC20-compatible methods are not real balanceOf and supply!
    // They measure the weights for the purpose of voting, so they don't represent real coins.

    // @notice Binary search to estimate timestamp for block number
    // @param block : Block to find
    // @param maxEpoch : Don't go beyond this epoch
    // @return Approximate timestamp for block
    function findBlockEpoch(uint256 blockNo, uint256 maxEpoch) internal view returns (uint256) {
        //# Binary search
        uint256 min = 0;
        uint256 max = maxEpoch;

        for (uint256 i; i < 128; i++) {
            // Will be always enough for 128-bit numbers
            if (min >= max) {
                break;
            }
            uint256 mid = (min + max + 1) / 2;
            if (pointHistory[mid].blk <= blockNo) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return min;
    }

    // @notice Get the current voting power for `msg.sender`
    // @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
    // @param account User wallet address
    // @param blockTS Epoch time to return voting power at
    // @return User voting power
    function balanceOf(address account, uint256 blockTS) public view returns (uint256) {
        if (blockTS == 0) {
            blockTS = block.timestamp;
        }
        uint256 userEpoch = lastUserPointIndex[account];
        if (userEpoch == 0) {
            return 0;
        } else {
            Point memory lastPoint = userPointHistory[account][userEpoch];
            lastPoint.bias =
                lastPoint.bias -
                (lastPoint.slope * (SafeCast.toUint128(blockTS - lastPoint.ts)));
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
            return uint256(lastPoint.bias);
        }
    }

    // @notice Measure voting power of `account` at block height `blockNo`
    // @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
    // @param account User's wallet address
    // @param blockNo Block to calculate the voting power at
    // @return Voting power
    function balanceOfAt(address account, uint256 blockNo) external view returns (uint256) {
        require(blockNo <= block.number && blockNo > 0, "Invalid block number");

        uint256 min = 0;
        uint256 max = lastUserPointIndex[account];

        for (uint256 i; i < 128; i++) {
            // Will be always enough for 128-bit numbers
            if (min >= max) {
                break;
            }
            uint256 mid = (min + max + 1) / 2;
            if (userPointHistory[account][mid].blk <= blockNo) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        Point memory userPoint = userPointHistory[account][min];

        uint256 maxEpoch = epoch;
        uint256 _epoch = findBlockEpoch(blockNo, maxEpoch);
        Point memory point0 = pointHistory[_epoch];
        uint256 d_block = 0;
        uint256 d_t = 0;
        if (_epoch < maxEpoch) {
            Point memory point1 = pointHistory[_epoch + 1];
            d_block = point1.blk - point0.blk;
            d_t = point1.ts - point0.ts;
        } else {
            d_block = block.number - point0.blk;
            d_t = block.timestamp - point0.ts;
        }
        uint256 blockTime = point0.ts;
        if (d_block != 0) {
            blockTime = blockTime + ((d_t * (blockNo - point0.blk)) / (d_block));
        }

        userPoint.bias =
            userPoint.bias -
            (userPoint.slope * (SafeCast.toUint128(blockTime - userPoint.ts)));
        if (userPoint.bias >= 0) {
            return uint256(userPoint.bias);
        } else {
            return 0;
        }
    }

    // @notice Calculate total voting power at some point in the past
    // @param point : The point (bias/slope) to start search from
    // @param ts  : Time to calculate the total voting power at
    // @return Total voting power at that time
    function supplyAt(Point memory point, uint256 ts) internal view returns (uint256) {
        Point memory lastPoint = point;
        uint256 t_i = (lastPoint.ts / WEEK) * WEEK;

        for (uint256 i; i < 255; i++) {
            t_i = t_i + WEEK;
            uint128 d_slope = 0;

            if (t_i > ts) {
                t_i = ts;
            } else {
                d_slope = slopeChanges[t_i];
            }

            lastPoint.bias =
                lastPoint.bias -
                (lastPoint.slope * (SafeCast.toUint128(t_i - (lastPoint.ts))));

            if (t_i == ts) {
                break;
            }
            lastPoint.slope = lastPoint.slope + d_slope;
            lastPoint.ts = t_i;
        }
        if (lastPoint.bias < 0) {
            lastPoint.bias = 0;
        }
        return uint256(lastPoint.bias);
    }

    // @notice Calculate total voting power
    // @dev Adheres to the ERC20 `totalSupply` interface
    // @return Total voting power
    function totalSupply(uint256 ts) external view returns (uint256) {
        if (ts == 0) {
            ts = block.timestamp;
        }
        uint256 _epoch = epoch;
        Point memory lastPoint = pointHistory[_epoch];
        return supplyAt(lastPoint, ts);
    }

    // @notice Calculate total voting power at some point in the past
    // @param blockNo Block to calculate the total voting power at
    // @return Total voting power at `_block`
    function totalSupplyAt(uint256 blockNo) external view returns (uint256) {
        require(blockNo <= block.number, "Invalid block number");
        uint256 _epoch = epoch;
        uint256 targetEpoch = findBlockEpoch(blockNo, _epoch);
        Point memory point = pointHistory[targetEpoch];
        uint256 dt = 0;

        if (targetEpoch < _epoch) {
            Point memory pointNext = pointHistory[targetEpoch + 1];
            if (point.blk != pointNext.blk) {
                dt = blockNo - point.blk * (pointNext.ts - point.ts / pointNext.blk - point.blk);
            }
        } else {
            if (point.blk != block.number) {
                dt =
                    blockNo -
                    point.blk *
                    (block.timestamp - point.ts / (block.number - point.blk));
            }
        } // Now dt contains info on how far are we beyond point
        return supplyAt(point, point.ts + dt);
    }
}
