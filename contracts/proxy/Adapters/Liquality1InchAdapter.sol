// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Libraries/Adapter.sol";
import "../interfaces/ILiqualityProxyAdapter.sol";
import "../interfaces/IUniSwapPool.sol";
import "../Libraries/LibTransfer.sol";
import "hardhat/console.sol";

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
    bytes1 private constant UNOSWAP_TO_ETH_OFFSET = 0x40; // Prefix identifier on pool data, when ETH is tokenOut
    bytes1 private constant UNISWAPV3_TO_ETH_OFFSET = 0x20; // Prefix identifier on pool data, when ETH is tokenOut
    bytes1 private constant UNISWAP_FROM_TOKEN1_OFFSET = 0x80; // Prefix identifier on pool data, when Token1 is tokenIn
    bytes1 private constant UNISWAPV3_FROM_ETH_OFFSET = 0xc0; // Prefix identifier on pool data, when ETH is tokenIn

    function swap(
        uint256 feeRate,
        address feeCollector,
        address target,
        bytes calldata data
    ) external payable {
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
                uint256 unSpentAmount = sellAmount - spentAmount;
                if (unSpentAmount > 0) {
                    msg.sender.transferEth(unSpentAmount);
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
                uint256 unSpentAmount = sellAmount - spentAmount;
                if (unSpentAmount > 0) {
                    IERC20(tokenIn).safeTransfer(msg.sender, unSpentAmount);
                }
            } else {
                returnedAmount = abi.decode(response, (uint256));
            }

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
            (caller, desc) = abi.decode(data[4:], (address, AGV4SwapDescription));

            tokenIn = desc.srcToken;
            tokenOut = desc.dstToken;
            sellAmount = desc.amount;
        } else if (swapFnSelector == CLIPPER_SWAP) {
            (tokenIn, tokenOut, sellAmount) = abi.decode(data[4:], (address, address, uint256));
        } else if (swapFnSelector == UNISWAPV3_SWAP) {
            (tokenIn, tokenOut, sellAmount) = getUniswapV3Params(data);
        } else if (swapFnSelector == UNO_SWAP) {
            (tokenIn, tokenOut, sellAmount) = getUnoswapParams(data);
        }
    }

    function getUnoswapParams(bytes calldata data)
        internal
        view
        returns (
            address tokenIn,
            address tokenOut,
            uint256 sellAmount
        )
    {
        uint256 minReturn;
        bytes32[] memory pools;
        (tokenIn, sellAmount, minReturn, pools) = abi.decode(
            data[4:],
            (address, uint256, uint256, bytes32[])
        );

        uint256 lastIndex = pools.length - 1;
        address poolN = address(uint160(uint256(pools[lastIndex])));

        // Check First byte of pool to know if token1 is tokenIn
        bool poolNToken1IsTokenIn = bytes1(abi.encodePacked(pools[lastIndex])) ==
            UNISWAP_FROM_TOKEN1_OFFSET;

        // Check First byte of pool to know if it's swap to value
        bool swapToValue = bytes1(abi.encodePacked(pools[lastIndex])) == UNOSWAP_TO_ETH_OFFSET;

        if (swapToValue) {
            tokenOut = ETH_ADDRESS;
        } else {
            tokenOut = poolNToken1IsTokenIn
                ? IUniSwapPool(poolN).token0()
                : IUniSwapPool(poolN).token1();
        }
    }

    function getUniswapV3Params(bytes calldata data)
        internal
        view
        returns (
            address tokenIn,
            address tokenOut,
            uint256 sellAmount
        )
    {
        uint256 minReturn;
        uint256[] memory pools;

        (sellAmount, minReturn, pools) = abi.decode(data[4:], (uint256, uint256, uint256[]));
        bool swapFromValue = bytes1(abi.encodePacked(pools[0])) == UNISWAPV3_FROM_ETH_OFFSET;

        if (pools.length > 1) {
            // Multiple hops
            address pool0 = address(uint160(pools[0]));
            uint256 lastIndex = pools.length - 1;
            address poolN = address(uint160(pools[lastIndex]));

            bool swapToValue = bytes1(abi.encodePacked(pools[lastIndex])) ==
                UNISWAPV3_TO_ETH_OFFSET;
            bool poolNToken1IsTokenIn = bytes1(abi.encodePacked(pools[lastIndex])) ==
                UNISWAP_FROM_TOKEN1_OFFSET;

            if (swapFromValue) {
                tokenIn = ETH_ADDRESS;
            } else {
                bool pool0Token1IsTokenIn = bytes1(abi.encodePacked(pools[0])) ==
                    UNISWAP_FROM_TOKEN1_OFFSET;
                tokenIn = pool0Token1IsTokenIn
                    ? IUniSwapPool(pool0).token1()
                    : IUniSwapPool(pool0).token0();
            }

            if (swapToValue) {
                tokenOut = ETH_ADDRESS;
            } else {
                tokenOut = poolNToken1IsTokenIn
                    ? IUniSwapPool(poolN).token0()
                    : IUniSwapPool(poolN).token1();
            }
        } else {
            // Single hop
            bool swapToValue = bytes1(abi.encodePacked(pools[0])) == UNISWAPV3_TO_ETH_OFFSET;

            address pool0 = address(uint160(pools[0]));
            address token0 = IUniSwapPool(pool0).token0();
            address token1 = IUniSwapPool(pool0).token1();

            if (swapToValue) {
                tokenOut = ETH_ADDRESS;
                tokenIn = token0 == WETH_ADDRESS ? token1 : token0;
            } else if (swapFromValue) {
                tokenIn = ETH_ADDRESS;
                tokenOut = token0 == WETH_ADDRESS ? token1 : token0;
            } else {
                // Check First byte of pool to know if token1 is tokenIn
                bool pool0Token1IsTokenIn = bytes1(abi.encodePacked(pools[0])) ==
                    UNISWAP_FROM_TOKEN1_OFFSET;
                tokenIn = pool0Token1IsTokenIn ? token1 : token0;
                tokenOut = tokenIn == token0 ? token1 : token0;
            }
        }
    }

    function isETH(address tokenAdr) internal pure returns (bool) {
        return (tokenAdr == ZERO_ADDRESS || tokenAdr == ETH_ADDRESS);
    }
}
