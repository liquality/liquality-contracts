// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ISwapperAdapter {
    /// @param feeRate An int expression for the actual "rate in percentage".
    /// 5% (i.e 5/100) becomes as 20. So fee equals amount/20 in this case
    /// 0.2% (i.e 2/1000) becomes as 500, and 0.02% (i.e 2/10000) becomes as 5000
    /// @param data the encoded data to be forwarded to the swapper
    function swap(
        uint256 feeRate,
        address feeCollector,
        address swapper,
        bytes calldata data
    ) external payable;
}
