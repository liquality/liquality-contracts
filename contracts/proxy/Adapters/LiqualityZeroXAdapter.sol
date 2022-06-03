// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Libraries/Adapter.sol";
import "../interfaces/ILiqualityProxyAdapter.sol";

contract LiqualityZeroXAdapter is ILiqualityProxyAdapter {
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice This works for ZeroX sellToUniswap.
    function swap(
        uint256 feeRate,
        address feeCollector,
        address target,
        bytes calldata data
    ) external payable {
        // Decode data
        (address[] memory tokens, uint256 sellAmount, uint256 minBuyAmount, ) = abi.decode(
            data[4:],
            (address[], uint256, uint256, bool)
        );

        address tokenIn = tokens[0];
        address tokenOut = tokens[tokens.length - 1];

        require(minBuyAmount >= 0, "Invalid minBuyAmount");

        // Validate input
        if ((msg.value > 0 && !isETH(tokenIn)) || (msg.value == 0 && isETH(tokenOut))) {
            revert("Invalid Swap");
        }

        // Validate input

        bytes memory response;
        uint256 returnedAmount;

        // Determine the swap type(fromToken or fromValue) and initiate swap.
        if (msg.value > 0) {
            // If it's a swap from value
            response = Adapter.beginFromValueSwap(target, data);
            returnedAmount = abi.decode(response, (uint256));
            Adapter.handleReturnedToken(tokenOut, returnedAmount, feeRate, feeCollector);
        } else {
            // If it's a swap from Token
            response = Adapter.beginFromTokenSwap(target, tokenIn, sellAmount, data);
            returnedAmount = abi.decode(response, (uint256));

            // handle returnedAmount
            if (isETH(tokens[tokens.length - 1])) {
                Adapter.handleReturnedValue(returnedAmount, feeRate, payable(feeCollector));
            } else {
                // If it's a swap to token
                Adapter.handleReturnedToken(tokenOut, returnedAmount, feeRate, feeCollector);
            }
        }

        LiqualityProxySwapInfo memory swapInfo = LiqualityProxySwapInfo({
            target: target,
            user: msg.sender,
            feeRate: feeRate,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: sellAmount,
            amountOut: returnedAmount
        });

        emit LiqualityProxySwap(swapInfo);
    }

    function isETH(address tokenAdr) internal pure returns (bool) {
        return (tokenAdr == ETH_ADDRESS);
    }
}
