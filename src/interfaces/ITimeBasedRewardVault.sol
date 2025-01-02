// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IRewardVault } from "./IRewardVault.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

struct RewardConfig {
    uint256 startTime;
    uint256 endTime;
    uint256 rewardRate;
    uint256 claimStartTime;
    uint256 claimEndTime;
}

interface ITimeBasedRewardVault is IRewardVault {
    error ClaimNotStarted(uint256 blockTimestamp, uint256 claimStartTime);

    event UpdatePendingReward(address indexed user, uint256 amount, uint256 timestamp);
    event UpdateRewardConfig(RewardConfig config);
    event UpdateLastRewardPerToken(uint256 lastRewardPerToken, uint256 lastUpdateTime);
    event UpdateUserRewardPerToken(address user, uint256 lastRewardPerToken, uint256 lastUpdateTime);

    function getRewardConfig() external view returns (RewardConfig memory);

    function updateRewardConfig(RewardConfig memory _config) external;

    function getLastRewardPerToken() external view returns (uint256);

    function getLastUpdateTime() external view returns (uint256);

    function getUserLastRewardPerToken(address _user) external view returns (uint256);
}
