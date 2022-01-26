// SPDX-License-Identifier:MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILiqualityToken is IERC20 {
    function getChainId() external view returns (uint256 chainId);

    function getDomainSeparator() external view returns (bytes32);

    function mint(address to, uint256 value) external returns (bool);

    function burn(uint256 value) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
