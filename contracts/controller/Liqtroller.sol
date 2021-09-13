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
    constructor(address _admin, uint256 initialEpochSealThreshold) {
        admin = _admin;
        epochSealThreshold = initialEpochSealThreshold;
    }

    /// @inheritdoc ILiqtroller
    function _setEpochSealThreshold(uint256 newEpochSealThreshold) public override {
        // Check caller is admin
        require(msg.sender == admin, "only admin can set epoch seal threshold");

        uint256 oldEpochSealThreshold = epochSealThreshold;
        epochSealThreshold = newEpochSealThreshold;
        emit NewEpochSealThreshold(oldEpochSealThreshold, newEpochSealThreshold);
    }
}
