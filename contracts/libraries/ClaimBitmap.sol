// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

library ClaimBitmap {
    /// Computes the position in the mapping for the given index
    function position(uint256 index) internal pure returns (uint256 word, uint256 bit) {
        word = index / 256;
        bit = index % 256;
    }

    /// Sets the index as claimed.
    function setClaimed(mapping(uint256 => uint256) storage self, uint256 index) internal {
        (uint256 word, uint256 bit) = position(index);
        uint256 mask = 1 << bit;
        self[word] ^= mask;
    }

    /// Returns true if index is claimed.
    function isClaimed(mapping(uint256 => uint256) storage self, uint256 index)
        internal
        view
        returns (bool)
    {
        (uint256 word, uint256 bit) = position(index);
        uint256 claimedWord = self[word];
        uint256 mask = (1 << bit);
        return claimedWord & mask == mask;
    }
}
