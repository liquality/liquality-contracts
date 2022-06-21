// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "../Libraries/FullSwap.sol";
import "../interfaces/ISwapperAdapter.sol";
import "../interfaces/IUniSwapPool.sol";
import "hardhat/console.sol";

contract Liquality1InchAdapter is ISwapperAdapter, FullSwap {
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

    address private immutable wNativeAddress;
    bytes4 private constant AGV4_SWAP = 0x7c025200; //swap(address,(address,address,address,address,uint256,uint256,uint256,bytes),bytes)
    bytes4 private constant CLIPPER_SWAP = 0xb0431182; //clipperSwap(address,address,uint256,uint256)
    bytes4 private constant UNISWAPV3_SWAP = 0xe449022e; //uniswapV3Swap(uint256,uint256,uint256[])
    bytes4 private constant UNO_SWAP = 0x2e95b6c8; //unoswap(address,uint256,uint256,bytes32[])

    uint256 private constant ONE_FOR_ZERO_MASK = 1 << 255; // Mask data for identifing when Token0 is tokenIn
    uint256 private constant FROM_NATIVE_MASK = 1 << 254; // Mask data for identifing when ETH is tokenIn
    uint256 private constant TO_NATIVE_MASK = 1 << 253; // Mask data for identifing when ETH is tokenOut

    bytes1 private constant UNOSWAP_TO_ETH_OFFSET = 0x40; // Pool prefix identifier on pool data, when ETH is tokenOut
    bytes1 private constant UNOSWAP_FROM_TOKEN1_OFFSET = 0x80;

    constructor(address wNative) {
        wNativeAddress = wNative;
    }

    function swap(
        uint256 feeRate,
        address feeCollector,
        address swapper,
        bytes calldata data
    ) external payable {
        console.log("Got here");

        (address tokenIn, address tokenOut, uint256 sellAmount) = getSwapParams(data);
        console.log("Swap Details");
        console.log(tokenIn);
        console.log(tokenOut);
        console.log(sellAmount);

        execute(feeRate, feeCollector, swapper, data, tokenIn, tokenOut, sellAmount);
    }

    function getSwapParams(bytes calldata data)
        internal
        view
        returns (
            address tokenIn,
            address tokenOut,
            uint256 sellAmount
        )
    {
        bytes4 swapFnSelector = bytes4(data[0:4]);
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
            UNOSWAP_FROM_TOKEN1_OFFSET;

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
        console.log("Got to Uniswapv3");
        uint256 minReturn;
        uint256[] memory pools;

        (sellAmount, minReturn, pools) = abi.decode(data[4:], (uint256, uint256, uint256[]));
        console.log("Decode uniswap V3");

        bool swapFromValue = pools[0] & FROM_NATIVE_MASK > 0;

        if (pools.length > 1) {
            // Multiple hops
            address pool0 = address(uint160(pools[0]));
            uint256 lastIndex = pools.length - 1;
            address poolN = address(uint160(pools[lastIndex]));

            bool swapToValue = pools[lastIndex] & TO_NATIVE_MASK > 0;
            bool poolNToken0IsTokenIn = pools[lastIndex] & ONE_FOR_ZERO_MASK == 0;

            if (swapFromValue) {
                tokenIn = ETH_ADDRESS;
            } else {
                bool pool0Token0IsTokenIn = pools[0] & ONE_FOR_ZERO_MASK == 0;
                tokenIn = pool0Token0IsTokenIn
                    ? IUniSwapPool(pool0).token0()
                    : IUniSwapPool(pool0).token1();
            }

            if (swapToValue) {
                tokenOut = ETH_ADDRESS;
            } else {
                tokenOut = poolNToken0IsTokenIn
                    ? IUniSwapPool(poolN).token1()
                    : IUniSwapPool(poolN).token0();
            }
        } else {
            // Single hop
            bool swapToValue = pools[0] & TO_NATIVE_MASK > 0;

            address pool0 = address(uint160(pools[0]));
            address token0 = IUniSwapPool(pool0).token0();
            address token1 = IUniSwapPool(pool0).token1();

            if (swapToValue) {
                tokenOut = ETH_ADDRESS;
                tokenIn = token0 == wNativeAddress ? token1 : token0;
            } else if (swapFromValue) {
                tokenIn = ETH_ADDRESS;
                tokenOut = token0 == wNativeAddress ? token1 : token0;
            } else {
                // Check whether token0 is tokenIn
                bool pool0Token0IsTokenIn = pools[0] & ONE_FOR_ZERO_MASK == 0;
                tokenIn = pool0Token0IsTokenIn ? token0 : token1;
                tokenOut = tokenIn == token0 ? token1 : token0;
            }
        }
    }
}
