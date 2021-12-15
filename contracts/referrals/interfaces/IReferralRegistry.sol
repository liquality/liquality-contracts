// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

struct Referral {
    address referrer;
    uint96 blockNumber; // 12 bytes so it packs
}

interface IReferralRegistry {
    /// Retrieve a referral of a user
    function getReferral(address referee) external view returns (Referral memory);

    /// @notice Registers a referral in the registry
    /// @param referrer The referrer
    /// @param referee The user that was referred
    function registerReferral(address referrer, address referee) external;

    /// @notice An event emitted when a successful registration is recorded
    /// @param referrer The referrer
    /// @param referee The user that was referred
    event ReferralRegistered(address referrer, address referee);

    /// @notice Address is not allowed
    error InvalidAddress();

    /// @notice Only the designated controller can call this contract
    error OnlyControllerAllowed();

    /// @notice A referee can only be referred once
    error RefereeAlreadyRegistered();

    /// @notice It is not possible to referrer yourself
    error RefferringSelfNotAllowed();
}
