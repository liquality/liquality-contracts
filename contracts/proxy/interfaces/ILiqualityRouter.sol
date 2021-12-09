// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ILiqualityRouter {
    struct FeeData {
        address payable account;
        uint256 fee;
    }

    event Routed(address indexed exchange, address indexed tokenFrom, bytes data);

    function route(
        address exchange,
        address tokenFrom,
        uint256 amount,
        bytes calldata data,
        FeeData[] calldata fees
    ) external payable;
}
