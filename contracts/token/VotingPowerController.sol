// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../controller/Liqtroller.sol";
import "./IVotingPowerImpl.sol";

contract VotingPowerController {
    IERC20 public immutable sLIQ;
    Liqtroller public immutable liqtroller;
    IVotingPowerImpl public votingPowerImpl;

    error VotingPowerController__VotingPowerExceedsAllowance(uint256 allowed, uint256 actual);

    constructor(address _sLIQ, address _liqtroller) {
        sLIQ = IERC20(_sLIQ);
        liqtroller = Liqtroller(_liqtroller);
    }

    function getMaximumVotingPowerAllowed() public view returns (uint256) {
        uint256 sLiqTotalSupply = sLIQ.totalSupply();
        uint256 votingPowerPercentage = liqtroller.votingPowerPercentage();
        return (sLiqTotalSupply * votingPowerPercentage) / 10000;
    }

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256) {
        try votingPowerImpl.getPriorVotes(account, blockNumber) returns (uint256 result) {
            return result;
        } catch {
            return 0;
        }
    }

    function balanceOf(address user) external view returns (uint256) {
        try votingPowerImpl.balanceOf(user) returns (uint256 result) {
            return result;
        } catch {
            return 0;
        }
    }

    function claim(bytes calldata data) external returns (bytes memory result) {
        result = votingPowerImpl.claim(data);
        uint256 totalVotingPowerAfterClaim = votingPowerImpl.totalSupply();
        uint256 maxVotingPowerAllowed = getMaximumVotingPowerAllowed();
        if (totalVotingPowerAfterClaim > maxVotingPowerAllowed) {
            revert VotingPowerController__VotingPowerExceedsAllowance(
                maxVotingPowerAllowed,
                totalVotingPowerAfterClaim
            );
        }
    }
}
