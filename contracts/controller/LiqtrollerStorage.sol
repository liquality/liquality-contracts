// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// Onchain decided parameters
contract LiqtrollerStorage {
    address public admin;
}

contract LiqtrollerStorageV1 is LiqtrollerStorage {
    uint256 public epochSealThreshold;
}
