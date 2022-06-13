// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Libraries/Adapter.sol";
import "../interfaces/ILiqualityProxyAdapter.sol";
import "../interfaces/IUniSwapPool.sol";
import "../Libraries/LibTransfer.sol";
import "hardhat/console.sol";

contract Liquality1InchAdapter is ILiqualityProxyAdapter {
    using LibTransfer for address payable;
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

    address private immutable WNATIVE_ADDRESS;
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant ZERO_ADDRESS = address(0);
    bytes4 private constant AGV4_SWAP = 0x7c025200; //swap(address,(address,address,address,address,uint256,uint256,uint256,bytes),bytes)
    bytes4 private constant CLIPPER_SWAP = 0xb0431182; //clipperSwap(address,address,uint256,uint256)
    bytes4 private constant UNISWAPV3_SWAP = 0xe449022e; //uniswapV3Swap(uint256,uint256,uint256[])
    bytes4 private constant UNO_SWAP = 0x2e95b6c8; //unoswap(address,uint256,uint256,bytes32[])

    uint256 private constant ONE_FOR_ZERO_MASK = 1 << 255; // Mask data for identifing when Token0 is tokenIn
    uint256 private constant FROM_NATIVE_MASK = 1 << 254; // Mask data for identifing when ETH is tokenIn
    uint256 private constant TO_NATIVE_MASK = 1 << 253; // Mask data for identifing when ETH is tokenOut

    bytes1 private constant UNOSWAP_TO_ETH_OFFSET = 0x40; // Pool prefix identifier on pool data, when ETH is tokenOut
    // bytes1 private constant UNISWAPV3_TO_ETH_OFFSET = 0x20; // Mask identifier on pool data, when ETH is tokenOut
    bytes1 private constant UNOSWAP_FROM_TOKEN1_OFFSET = 0x80;

    // bytes1 private constant UNISWAPV3_FROM_ETH_OFFSET = 0xc0;

    constructor(address wNative) {
        WNATIVE_ADDRESS = wNative;
    }

    function swap(
        uint256 feeRate,
        address feeCollector,
        address target,
        bytes calldata data
    ) external payable {
        (address tokenIn, address tokenOut, uint256 sellAmount) = getSwapParams(data);

        // Validate input
        if ((msg.value > 0 && !isETH(tokenIn)) || (msg.value == 0 && isETH(tokenIn))) {
            revert("Invalid Swap");
        }

        uint256 returnedAmount;

        // Determine the swap type(fromToken or fromValue) and initiate swap.
        if (msg.value > 0) {
            // If it's a swap from value
            Adapter.beginFromValueSwap(target, data);
            uint256 proxyTokenInBal = address(this).balance;
            if (proxyTokenInBal > 0) {
                payable(msg.sender).transferEth(proxyTokenInBal);
            }

            returnedAmount = Adapter.handleReturnedToken(tokenOut, feeRate, feeCollector);
        } else {
            // If it's a swap from Token
            Adapter.beginFromTokenSwap(target, tokenIn, sellAmount, data);
            uint256 proxyTokenInBal = IERC20(tokenIn).balanceOf(address(this));
            if (proxyTokenInBal > 0) {
                IERC20(tokenIn).safeTransfer(msg.sender, proxyTokenInBal);
            }

            // handle returnedAmount
            if (isETH(tokenOut)) {
                console.log("Got to handleReturnedValue");
                returnedAmount = Adapter.handleReturnedValue(feeRate, payable(feeCollector));
                console.log("sent returned ETH");
            } else {
                // If it's a swap to token
                returnedAmount = Adapter.handleReturnedToken(tokenOut, feeRate, feeCollector);
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
        uint256 minReturn;
        uint256[] memory pools;

        (sellAmount, minReturn, pools) = abi.decode(data[4:], (uint256, uint256, uint256[]));
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
                tokenIn = token0 == WNATIVE_ADDRESS ? token1 : token0;
            } else if (swapFromValue) {
                tokenIn = ETH_ADDRESS;
                tokenOut = token0 == WNATIVE_ADDRESS ? token1 : token0;
            } else {
                // Check First byte of pool to know if token1 is tokenIn
                bool pool0Token0IsTokenIn = pools[0] & ONE_FOR_ZERO_MASK == 0;
                tokenIn = pool0Token0IsTokenIn ? token0 : token1;
                tokenOut = tokenIn == token0 ? token1 : token0;
            }
        }
    }

    function isETH(address tokenAdr) internal pure returns (bool) {
        return (tokenAdr == ZERO_ADDRESS || tokenAdr == ETH_ADDRESS);
    }
}
