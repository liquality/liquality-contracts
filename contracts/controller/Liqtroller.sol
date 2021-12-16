// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

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
        uint256 _epochDuration
    ) {
        admin = _admin;
        epochSealThreshold = _epochSealThreshold;
        epochDuration = _epochDuration;
    }

    /// @inheritdoc ILiqtroller
    function setEpochSealThreshold(uint256 newEpochSealThreshold) public override onlyAdmin {
        emit NewEpochSealThreshold(epochSealThreshold, newEpochSealThreshold);
        epochSealThreshold = newEpochSealThreshold;
    }

    /// @inheritdoc ILiqtroller
    function setEpochDuration(uint256 newEpochDuration) public override onlyAdmin {
        emit NewEpochDuration(epochDuration, newEpochDuration);
        epochDuration = newEpochDuration;
    }
}
