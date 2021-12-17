// SPDX-License-Identifier:MIT

pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20NonTransferable is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // Initialized ERC20 token
    }

    /**
     * @dev Disables all transfer related functions
     */
    function _transfer(
        address,
        address,
        uint256
    ) internal virtual override {
        revert("ERC20NonTransferable: Transfer operation disabled for staked tokens");
    }

    /**
     * @dev Disables all approval related functions
     *
     */
    function _approve(
        address,
        address,
        uint256
    ) internal virtual override {
        revert("ERC20NonTransferable: Approval operation disabled for staked tokens");
    }
}
