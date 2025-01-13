// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { FarmConfig } from "../interfaces/IFarm.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

library FarmMath {
    uint256 internal constant REWARD_PER_TOKEN_PRECISION = 1e18;

    function computeReward(
        FarmConfig memory farmConfig,
        uint256 share,
        uint256 lastRewardPerToken,
        uint256 lastUserRewardPerToken
    )
        internal
        view
        returns (uint256)
    {
        if (farmConfig.rewardStartTime == 0 || farmConfig.rewardEndTime == 0 || farmConfig.rewardRate == 0) {
            return 0;
        }
        if (block.timestamp < farmConfig.rewardStartTime) {
            return 0;
        }
        return Math.mulDiv(share, (lastRewardPerToken - lastUserRewardPerToken), REWARD_PER_TOKEN_PRECISION);
    }

    function computeLatestRewardPerToken(
        uint256 lastRewardPerToken,
        uint256 rewardRate,
        uint256 interval,
        uint256 totalShares
    )
        internal
        pure
        returns (uint256)
    {
        return lastRewardPerToken + computeRewardPerToken(rewardRate, interval, totalShares);
    }

    function computeRewardPerToken(
        uint256 rewardRate,
        uint256 interval,
        uint256 totalShares
    )
        internal
        pure
        returns (uint256)
    {
        if (totalShares == 0) {
            return 0;
        }
        return Math.mulDiv(rewardRate * interval, REWARD_PER_TOKEN_PRECISION, totalShares);
    }

    function computeInterval(
        uint256 currentTime,
        uint256 lastUpdateTime,
        uint256 startTime,
        uint256 endTime
    )
        internal
        pure
        returns (uint256)
    {
        if (currentTime < startTime) {
            return 0;
        }
        if (currentTime > endTime) {
            return endTime - Math.max(lastUpdateTime, startTime);
        }
        return currentTime - Math.max(lastUpdateTime, startTime);
    }
}
