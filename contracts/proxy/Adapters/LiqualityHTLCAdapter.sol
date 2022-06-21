// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "../Libraries/AtomicSwap.sol";
import "../interfaces/ISwapperAdapter.sol";

contract LiqualityHTLCAdapter is ISwapperAdapter, AtomicSwap {
    struct HTLCData {
        uint256 amount;
        uint256 expiration;
        bytes32 secretHash;
        address tokenAddress;
        address refundAddress;
        address recipientAddress;
    }

    /// @notice This works for ZeroX sellToUniswap.
    function swap(
        uint256 feeRate,
        address feeCollector,
        address swapper,
        bytes calldata data
    ) external payable {
        // Decode data
        HTLCData memory htlc;
        (htlc) = abi.decode(data[4:], (HTLCData));

        // We arbitrarily use address(1) as tokenOut is unknown
        execute(feeRate, feeCollector, swapper, data, htlc.tokenAddress, address(1), htlc.amount);
    }
}
