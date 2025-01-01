// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IRewardVault } from "../../interfaces/IRewardVault.sol";
import { ITimeBasedRewardVault, RewardConfig, UserRewardInfo } from "../../interfaces/ITimeBasedRewardVault.sol";
import { IRewardVaultMintCallback } from "../../interfaces/callbacks/IRewardVaultMintCallback.sol";

import { RewardVaultMath } from "../../libraries/RewardVaultMath.sol";
import { RewardVault } from "./RewardVault.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

abstract contract TimeBasedRewardVault is ITimeBasedRewardVault, RewardVault {
    event UpdatePendingReward(address indexed user, uint256 amount, uint256 timestamp);

    RewardConfig public rewardConfig;
    uint256 public lastRewardPerToken;
    uint256 public lastUpdateTime;
    mapping(address => UserRewardInfo) public userRewards;
    mapping(address => uint256) public pendingRewards;

    function updateRewardConfig(RewardConfig memory _config) public {
        rewardConfig = _config;
        emit UpdateRewardConfig(_config);
    }

    function previewReward(address _user) public view override returns (uint256) {
        UserRewardInfo memory userReward = userRewards[_user];
        uint256 rewardPerToken = _computeLatestRewardPerToken(
            rewardConfig.rewardRate,
            _computeInterval(lastUpdateTime, rewardConfig.startTime, rewardConfig.endTime),
            totalShares()
        );
        uint256 rewardAmount = _computeReward(rewardConfig, userReward, rewardPerToken);
        return rewardAmount + pendingRewards[_user];
    }

    function claimReward(address _owner, address _recipient) public override returns (uint256) {
        _updateReward(_owner);
        uint256 pendingReward = pendingRewards[_owner];
        if (pendingReward > 0) {
            _claimReward(_owner, _recipient, pendingReward);
            emit RewardClaimed(reward(), _owner, _recipient, pendingReward);
        }
        return pendingReward;
    }

    function getRewardConfig() public view returns (RewardConfig memory) {
        return rewardConfig;
    }

    function getLastRewardPerToken() public view returns (uint256) {
        return lastRewardPerToken;
    }

    function getLastUpdateTime() public view returns (uint256) {
        return lastUpdateTime;
    }

    function getUserRewardInfo(address _user) public view returns (UserRewardInfo memory) {
        return userRewards[_user];
    }

    function getPendingReward(address _user) public view returns (uint256) {
        return pendingRewards[_user];
    }

    function _updateReward(address _user) internal returns (uint256) {
        uint256 rewardPerToken = _updateRewardPerToken();
        uint256 rewardAmount = _computeReward(rewardConfig, userRewards[_user], rewardPerToken);
        _updateUserRewardPerToken(_user, rewardPerToken);
        pendingRewards[_user] += rewardAmount;
        emit UpdatePendingReward(_user, rewardAmount, block.timestamp);
        return rewardAmount;
    }

    function _computeReward(
        RewardConfig memory _config,
        UserRewardInfo memory _userReward,
        uint256 _rewardPerToken
    )
        internal
        view
        returns (uint256)
    {
        uint256 currentTime = block.timestamp;
        if (_config.startTime == 0 || _config.endTime == 0 || _config.rewardRate == 0) {
            return 0;
        }
        if (currentTime < _config.startTime) {
            return 0;
        }
        uint256 rewardAmount =
            RewardVaultMath.computeReward(_userReward.amount, _rewardPerToken, _userReward.lastRewardPerToken);
        return rewardAmount;
    }

    function _computeLatestRewardPerToken(
        uint256 _rewardRate,
        uint256 _interval,
        uint256 _totalShares
    )
        internal
        pure
        returns (uint256)
    {
        return RewardVaultMath.computeRewardPerToken(_rewardRate, _interval, _totalShares);
    }

    function _updateRewardPerToken() internal returns (uint256) {
        uint256 rewardPerToken = _computeLatestRewardPerToken(
            rewardConfig.rewardRate,
            _computeInterval(lastUpdateTime, rewardConfig.startTime, rewardConfig.endTime),
            totalShares()
        );
        lastRewardPerToken = rewardPerToken;
        lastUpdateTime = block.timestamp;
        emit UpdateLastRewardPerToken(rewardPerToken, lastUpdateTime);
        return rewardPerToken;
    }

    function _updateUserRewardPerToken(address _user, uint256 _rewardPerToken) internal {
        userRewards[_user].lastRewardPerToken = _rewardPerToken;
        emit UpdateUserRewardPerToken(_user, _rewardPerToken, block.timestamp);
    }

    function _claimReward(address _user, address _recipient, uint256 _amount) internal virtual returns (uint256);

    function _computeInterval(
        uint256 _lastUpdateTime,
        uint256 _startTime,
        uint256 _endTime
    )
        internal
        view
        returns (uint256)
    {
        return RewardVaultMath.computeInterval(block.timestamp, _lastUpdateTime, _startTime, _endTime);
    }
}
