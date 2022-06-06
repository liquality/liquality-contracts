// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Libraries/Adapter.sol";
import "../interfaces/ILiqualityProxyAdapter.sol";
import "../LibTransfer.sol";
import "hardhat/console.sol";

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
    address private constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
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
            address tokenOut0,
            address tokenOut1,
            address tokenOut,
            uint256 sellAmount,
            bytes4 swapFnSelector
        ) = getSwapParams(data);

        console.log("Token out after decoding");
        console.log(tokenOut);
        // Validate input
        if (
            (msg.value > 0 && !isETH(tokenIn) && tokenIn != WETH_ADDRESS) ||
            (msg.value == 0 && isETH(tokenIn))
        ) {
            console.log("Reverting on invalid Swap");
            console.log(msg.value);
            console.log(tokenIn);
            console.log(tokenOut);
            revert("Invalid Swap");
        }

        bytes memory response;
        uint256 returnedAmount;

        // Determine the swap type(fromToken or fromValue) and initiate swap.
        if (msg.value > 0) {
            // If it's a swap from value
            response = Adapter.beginFromValueSwap(target, data);

            console.log("Uniswap call began");
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
                console.log("Amount returned");
                console.log(returnedAmount);
            }

            console.log("Just before call to return token");
            console.log(tokenOut);

            tokenOut = determineTokenOut(tokenOut, tokenOut0, tokenOut1, returnedAmount);
            console.log(tokenOut);

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
                tokenOut = determineTokenOut(tokenOut, tokenOut0, tokenOut1, returnedAmount);

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
            address tokenOut0,
            address tokenOut1,
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
            console.log("The Dest receiver");
            console.log(desc.dstReceiver);
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
                address tokenIn0 = IUniSwapPool(firstPool).token0();
                address tokenIn1 = IUniSwapPool(firstPool).token1();
                if (IERC20(tokenIn0).balanceOf(address(this)) >= sellAmount) {
                    tokenIn = tokenIn0;
                } else {
                    tokenIn = tokenIn1;
                }
                tokenOut0 = IUniSwapPool(lastPool).token0();
                tokenOut1 = IUniSwapPool(lastPool).token1();
            } else {
                // Single hop
                address pool = address(uint160(pools[0]));
                address token0 = IUniSwapPool(pool).token0();
                address token1 = IUniSwapPool(pool).token1();
                console.log("Uniswap v3 pool tokens");
                console.log(token0);
                console.log(token1);
                if (IERC20(token0).balanceOf(address(this)) >= sellAmount) {
                    tokenIn = token0;
                    tokenOut = token1;
                } else {
                    tokenIn = token1;
                    tokenOut = token0;
                }
            }
        } else if (swapFnSelector == UNO_SWAP) {
            uint256 minReturn;
            bytes32[] memory pools;
            (tokenIn, sellAmount, minReturn, pools) = abi.decode(
                data[4:],
                (address, uint256, uint256, bytes32[])
            );
            address pool = address(uint160(uint256(pools[pools.length - 1])));
            tokenOut0 = IUniSwapPool(pool).token0();
            tokenOut1 = IUniSwapPool(pool).token1();
        }
        console.log("Just after calling get params");

        console.log(tokenOut);
    }

    function isETH(address tokenAdr) internal pure returns (bool) {
        return (tokenAdr == ZERO_ADDRESS || tokenAdr == ETH_ADDRESS);
    }

    function determineTokenOut(
        address tokenOut,
        address tokenOut0,
        address tokenOut1,
        uint256 amount
    ) internal view returns (address actualTokenOut) {
        // Determine tokenOut
        if (tokenOut == ZERO_ADDRESS) {
            if (IERC20(tokenOut0).balanceOf(address(this)) >= amount) {
                actualTokenOut = tokenOut0;
            } else {
                actualTokenOut = tokenOut1;
            }
        }
        actualTokenOut = tokenOut;
    }
}
