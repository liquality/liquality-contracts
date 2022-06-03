// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Libraries/Adapter.sol";
import "../interfaces/ILiqualityProxyAdapter.sol";
import "../LibTransfer.sol";

interface IUniSwapPool {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

contract Liquality1InchAdapter is ILiqualityProxyAdapter {
    using LibTransfer for address;
    using SafeERC20 for IERC20;

    struct AGV4SwapDescription {
        address srcToken;
        address dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant ZERO_ADDRESS = address(0);
    bytes4 private constant AGV4_SWAP = 0x7c025200; //swap(address,(address,address,address,address,uint256,uint256,uint256,bytes),bytes)
    bytes4 private constant CLIPPER_SWAP = 0xb0431182; //clipperSwap(address,address,uint256,uint256)
    bytes4 private constant UNISWAPV3_SWAP = 0xe449022e; //uniswapV3Swap(uint256,uint256,uint256[])
    bytes4 private constant UNO_SWAP = 0x2e95b6c8; //unoswap(address,uint256,uint256,bytes32[])

    /// @notice This works for ZeroX sellToUniswap.
    function swap(
        uint256 feeRate,
        address feeCollector,
        address target,
        bytes calldata data
    ) external payable {
        // Swap Params
        (
            address tokenIn,
            address tokenOut,
            uint256 sellAmount,
            bytes4 swapFnSelector
        ) = getSwapParams(data);

        // Validate input
        if ((msg.value > 0 && !isETH(tokenIn)) || (msg.value == 0 && isETH(tokenIn))) {
            revert("Invalid Swap");
        }

        bytes memory response;
        uint256 returnedAmount;

        // Determine the swap type(fromToken or fromValue) and initiate swap.
        if (msg.value > 0) {
            // If it's a swap from value
            response = Adapter.beginFromValueSwap(target, data);

            if (swapFnSelector == AGV4_SWAP) {
                // Only this swap function behaves differently
                uint256 spentAmount;
                (returnedAmount, spentAmount, ) = abi.decode(response, (uint256, uint256, uint256));

                // Since AGV4 is designed to refund unspent value, check contract for any value and refund user
                uint256 thisBalance = address(this).balance;
                if (thisBalance > 0) {
                    msg.sender.transferEth(thisBalance);
                }
            } else {
                returnedAmount = abi.decode(response, (uint256));
            }

            Adapter.handleReturnedToken(tokenOut, returnedAmount, feeRate, feeCollector);
        } else {
            // If it's a swap from Token
            response = Adapter.beginFromTokenSwap(target, tokenIn, sellAmount, data);

            if (swapFnSelector == AGV4_SWAP) {
                uint256 spentAmount;
                (returnedAmount, spentAmount, ) = abi.decode(response, (uint256, uint256, uint256));

                // Since AGV4 is designed to refund unspent token, check contract for any value and refund user
                uint256 thisBalance = IERC20(tokenIn).balanceOf(address(this));
                if (thisBalance > 0) {
                    IERC20(tokenIn).safeTransfer(msg.sender, thisBalance);
                }
            } else {
                returnedAmount = abi.decode(response, (uint256));
            }

            returnedAmount = abi.decode(response, (uint256));

            // handle returnedAmount
            if (isETH(tokenOut)) {
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

    function getSwapParams(bytes calldata data)
        internal
        view
        returns (
            address tokenIn,
            address tokenOut,
            uint256 sellAmount,
            bytes4 swapFnSelector
        )
    {
        swapFnSelector = bytes4(data[0:4]);

        if (swapFnSelector == AGV4_SWAP) {
            address caller;
            AGV4SwapDescription memory desc;
            (caller, desc, ) = abi.decode(data[4:], (address, AGV4SwapDescription, bytes));
            tokenIn = desc.srcToken;
            tokenOut = desc.dstToken;
            sellAmount = desc.amount;
        } else if (swapFnSelector == CLIPPER_SWAP) {
            (tokenIn, tokenOut, sellAmount, ) = abi.decode(
                data[4:],
                (address, address, uint256, uint256)
            );
        } else if (swapFnSelector == UNISWAPV3_SWAP) {
            uint256 minReturn;
            uint256[] memory pools;
            (sellAmount, minReturn, pools) = abi.decode(data[4:], (uint256, uint256, uint256[]));

            if (pools.length > 1) {
                // Multiple hops
                address firstPool = address(uint160(pools[0]));
                address lastPool = address(uint160(pools[pools.length - 1]));
                tokenIn = IUniSwapPool(firstPool).token0();
                tokenOut = IUniSwapPool(lastPool).token1();
            } else {
                // Single hop
                address pool = address(uint160(pools[0]));
                tokenIn = IUniSwapPool(pool).token0();
                tokenOut = IUniSwapPool(pool).token1();
            }
        } else if (swapFnSelector == UNO_SWAP) {
            uint256 minReturn;
            bytes32[] memory pools;
            (tokenIn, sellAmount, minReturn, pools) = abi.decode(
                data[4:],
                (address, uint256, uint256, bytes32[])
            );
            address pool = address(uint160(uint256(pools[pools.length - 1])));
            tokenOut = IUniSwapPool(pool).token1();
        }
    }

    function isETH(address tokenAdr) internal pure returns (bool) {
        return (tokenAdr == ZERO_ADDRESS || tokenAdr == ETH_ADDRESS);
    }
}
