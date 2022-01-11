// SPDX-License-Identifier:MIT

//@title Util Contract

pragma solidity >=0.8.4;

contract UtilContract {
    constructor() {
        //
    }

    function getCurrentTs() external view returns (uint256) {
        return block.timestamp;
    }
}
