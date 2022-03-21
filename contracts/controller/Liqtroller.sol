// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/ILiqtroller.sol";
import "./LiqtrollerStorage.sol";

/// TODO: implement Unitroller method: https://github.com/compound-finance/compound-protocol/blob/master/contracts/Unitroller.sol
/// Needs only have setImplementation method with admin being Governance
/// Liqtrollers will need to be changed to have _become() method that:
/// 1. Sets implementation of unitroller to the current contract
/// 2. Copies over any storage variables from pervious controller version

contract Liqtroller is ILiqtroller, LiqtrollerStorageV1 {
    constructor(
        address _admin,
        uint256 _epochSealThreshold,
        uint256 _epochDuration,
        uint256 _stakeAmount,
        uint256 _stakeDuration,
        uint256 _stakeDurationTreshold
    ) {
        admin = _admin;
        epochSealThreshold = _epochSealThreshold;
        epochDuration = _epochDuration;
        stakeAmount = _stakeAmount;
        stakeDuration = _stakeDuration;
        stakeDurationTreshold = _stakeDurationTreshold;
    }

    /// @inheritdoc ILiqtroller
    function setEpochSealThreshold(uint256 newEpochSealThreshold) external override onlyAdmin {
        emit NewEpochSealThreshold(epochSealThreshold, newEpochSealThreshold);
        epochSealThreshold = newEpochSealThreshold;
    }

    /// @inheritdoc ILiqtroller
    function setEpochDuration(uint256 newEpochDuration) external override onlyAdmin {
        emit NewEpochDuration(epochDuration, newEpochDuration);
        epochDuration = newEpochDuration;
    }

    /// @inheritdoc ILiqtroller
    function setStakeAmount(uint256 newStakeAmount) external override onlyAdmin {
        emit NewStakeAmount(stakeAmount, newStakeAmount);
        stakeAmount = newStakeAmount;
    }

    /// @inheritdoc ILiqtroller
    function setStakeDuration(uint256 newStakeDuration) external override onlyAdmin {
        emit NewStakeDuration(stakeDuration, newStakeDuration);
        stakeDuration = newStakeDuration;
    }

    /// @inheritdoc ILiqtroller
    function setStakeDurationThreshold(uint256 newStakeDurationThreshold)
        external
        override
        onlyAdmin
    {
        emit NewStakeDurationThreshold(stakeDurationTreshold, newStakeDurationThreshold);
        stakeDurationTreshold = newStakeDurationThreshold;
    }

    /// @inheritdoc ILiqtroller
    function setVotingPowerPercentage(uint256 newVotingPowerPercentage)
        external
        override
        onlyAdmin
    {
        require(
            newVotingPowerPercentage <= 4000 && newVotingPowerPercentage >= 2000,
            "Liqtroller: Voting power cannot exceed 50%"
        );
        emit NewVotingPowerPercentage(votingPowerPercentage, newVotingPowerPercentage);
        votingPowerPercentage = newVotingPowerPercentage;
    }

    /// @inheritdoc ILiqtroller
    function getStakeParameters()
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (stakeAmount, stakeDuration, stakeDurationTreshold);
    }
}
