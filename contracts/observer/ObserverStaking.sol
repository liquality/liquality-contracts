// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/IObserverStaking.sol";
import "../token/interfaces/ILiqualityToken.sol";
import "../controller/Liqtroller.sol";

contract ObserverStaking is IObserverStaking {
    Liqtroller public immutable liqtroller;
    address public immutable governance;
    address public immutable token;

    mapping(address => StakeData) public stakes;

    constructor(
        address _liqtroller,
        address _governance,
        address _token
    ) {
        liqtroller = Liqtroller(_liqtroller);
        governance = _governance;
        token = _token;
    }

    modifier onlyGovernance() {
        if (msg.sender != governance) {
            revert ObserverStaking__ExecutionNotAuthorized(governance, msg.sender);
        }
        _;
    }

    function slash(address observer, uint256 amount) external onlyGovernance {
        StakeData memory s = stakes[observer];
        if (amount > s.amount) {
            revert ObserverStaking__InvalidSlashAmount(s.amount, amount);
        }
        delete stakes[observer];
        ILiqualityToken(token).burn(amount);
        uint256 remainder = s.amount - amount;
        if (remainder > 0) {
            ILiqualityToken(token).transfer(observer, remainder);
        }
        emit ObserverSlashed(observer, amount);
    }

    function stake() external {
        address observer = msg.sender;
        (uint256 stakeAmount, uint256 stakeDuration, ) = liqtroller.getStakeParameters();
        uint256 expiresAt = block.number + stakeDuration;
        ILiqualityToken(token).transferFrom(observer, address(this), stakeAmount);
        stakes[observer] = StakeData({amount: stakeAmount, expireBlock: expiresAt});
        emit ObserverStaked(observer, stakeAmount, expiresAt);
    }

    function unstake() external {
        address observer = msg.sender;
        StakeData memory s = stakes[observer];
        if (block.number < s.expireBlock) {
            revert ObserverStaking__StakeNotExpired();
        }
        uint256 unstakeAmount = s.amount;
        delete stakes[observer];
        ILiqualityToken(token).transfer(observer, unstakeAmount);
        emit ObserverUnstaked(observer, unstakeAmount);
    }

    function extend(uint256 amount, uint256 blocks) external {
        address observer = msg.sender;
        StakeData storage s = stakes[observer];
        if (s.amount == 0) {
            revert ObserverStaking__CannotExtendNonExistentStake();
        }
        ILiqualityToken(token).transferFrom(observer, address(this), amount);
        s.amount += amount;
        s.expireBlock += blocks;
        emit ObserverStaked(observer, s.amount, s.expireBlock);
    }

    function isObserverEligible(address observer) external view override returns (bool isEligible) {
        StakeData memory s = stakes[observer];
        (uint256 stakeAmount, , uint256 stakeDurationTreshold) = liqtroller.getStakeParameters();
        isEligible =
            s.amount >= stakeAmount &&
            (s.expireBlock - stakeDurationTreshold) >= block.number;
    }
}
