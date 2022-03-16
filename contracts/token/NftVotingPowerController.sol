// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../controller/Liqtroller.sol";
import "./INftVotingPowerImpl.sol";

contract NftVotingPowerController {
    IERC20 public immutable sLIQ;
    Liqtroller public immutable liqtroller;
    INftVotingPowerImpl public nftVotingPowerImpl;

    error NftVotingPowerController__VotingPowerExceedsAllowance(uint256 allowed, uint256 actual);

    constructor(address _sLIQ, address _liqtroller) {
        sLIQ = IERC20(_sLIQ);
        liqtroller = Liqtroller(_liqtroller);
    }

    function getMaximumVotingPowerAllowed() public view returns (uint256) {
        uint256 sLiqTotalSupply = sLIQ.totalSupply();
        uint256 nftVotingPowerPercentage = liqtroller.nftVotingPowerPercentage();
        return (sLiqTotalSupply * nftVotingPowerPercentage) / 10000;
    }

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256) {
        try nftVotingPowerImpl.getPriorVotes(account, blockNumber) returns (uint256 result) {
            return result;
        } catch {
            return 0;
        }
    }

    function balanceOf(address user) external view returns (uint256) {
        try nftVotingPowerImpl.balanceOf(user) returns (uint256 result) {
            return result;
        } catch {
            return 0;
        }
    }

    function claim(bytes calldata data) external returns (bytes memory result) {
        result = nftVotingPowerImpl.claim(data);
        uint256 totalVotingPowerAfterClaim = nftVotingPowerImpl.totalSupply();
        uint256 maxVotingPowerAllowed = getMaximumVotingPowerAllowed();
        if (totalVotingPowerAfterClaim > maxVotingPowerAllowed) {
            revert NftVotingPowerController__VotingPowerExceedsAllowance(
                maxVotingPowerAllowed,
                totalVotingPowerAfterClaim
            );
        }
    }
}
