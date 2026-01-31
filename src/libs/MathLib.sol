// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library MathLib {
    function calculateReward(
        uint256 userStake,
        uint256 winningPool,
        uint256 losingPool
    ) internal pure returns (uint256) {
        return userStake + (userStake * losingPool) / winningPool;
    }
}
