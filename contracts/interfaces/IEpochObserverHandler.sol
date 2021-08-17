// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// Allows observers to submit their calculated merkle roots.
interface IEpochObserverHandler {
    /// Returns the merkle root assigned to a specific epoch.
    function submitRoot(uint256, bytes32) external;
}
