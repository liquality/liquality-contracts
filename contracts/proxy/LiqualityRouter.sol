// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ILiqualityRouter.sol";
import "./interfaces/ILiqualityProxy.sol";
import "./LibTransfer.sol";

contract LiqualityRouter is ILiqualityRouter {
    using LibTransfer for address;
    using SafeERC20 for IERC20;

    uint256 public gasReserve;

    ILiqualityProxy public liqualityProxy;

    constructor(address _liqualityProxy) {
        liqualityProxy = ILiqualityProxy(_liqualityProxy);
    }

    function route(
        address exchange,
        address tokenFrom,
        uint256 amount,
        bytes calldata data,
        FeeData[] calldata fees
    ) external payable {
        uint256 totalFee = 0;
        address user = msg.sender;

        // handle ETH fees
        if (tokenFrom == address(0)) {
            for (uint256 i = 0; i < fees.length; i++) {
                totalFee += fees[i].fee;
                fees[i].account.transfer(fees[i].fee);
            }
        }
        // handle ERC20 fees
        else {
            IERC20(tokenFrom).safeTransferFrom(user, address(liqualityProxy), amount);
            for (uint256 i = 0; i < fees.length; i++) {
                IERC20(tokenFrom).safeTransferFrom(user, fees[i].account, fees[i].fee);
            }
        }

        require(
            liqualityProxy.execute{value: msg.value - totalFee}(exchange, data),
            "proxy call failed"
        );

        emit Routed(exchange, tokenFrom, data);
    }
}
