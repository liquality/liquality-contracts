// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// Onchain decided parameters
contract LiqtrollerStorage {
    address public admin;

    modifier onlyAdmin() {
        require(msg.sender == admin, "LiqtrollerStorage: onlyAdmin");
        _;
    }
}

contract LiqtrollerStorageV1 is LiqtrollerStorage {
    uint256 public epochSealThreshold;
    uint256 public epochDuration;
}
