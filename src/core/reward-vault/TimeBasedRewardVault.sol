// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IRewardVault } from "../../interfaces/IRewardVault.sol";
import { ITimeBasedRewardVault, RewardConfig } from "../../interfaces/ITimeBasedRewardVault.sol";
import { IRewardVaultMintCallback } from "../../interfaces/callbacks/IRewardVaultMintCallback.sol";

import { RewardVaultMath } from "../../libraries/RewardVaultMath.sol";
import { RewardVault } from "./RewardVault.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

abstract contract TimeBasedRewardVault is Initializable, ITimeBasedRewardVault, RewardVault {
    RewardConfig public rewardConfig;
    uint256 public lastRewardPerToken;
    uint256 public lastUpdateTime;
    mapping(address => uint256) public userLastRewardPerToken;
    mapping(address => uint256) public pendingRewards;

    function __TimeBasedRewardVault__init(IERC20 _reward, address _rewardManager) internal onlyInitializing {
        __RewardVault__init(_reward, _rewardManager);
    }

    // RewardManager
    function updateRewardConfig(RewardConfig memory _config) public override onlyRewardManager {
        rewardConfig = _config;
        emit UpdateRewardConfig(_config);
    }

    function claimReward(
        address _owner,
        address _recipient
    )
        public
        virtual
        override
        onlyRewardManager
        returns (uint256)
    {
        if (block.timestamp < rewardConfig.claimStartTime) {
            revert ClaimNotStarted(block.timestamp, rewardConfig.claimStartTime);
        }
        _updateReward(_owner);
        uint256 pendingReward = pendingRewards[_owner];
        if (pendingReward > 0) {
            _claimReward(_owner, _recipient, pendingReward);
            emit RewardClaimed(reward(), _owner, _recipient, pendingReward);
            pendingRewards[_owner] = 0;
        }
        return pendingReward;
    }

    // Public
    function previewReward(address _user) public view override returns (uint256) {
        uint256 rewardPerToken = _computeLatestRewardPerToken(
            rewardConfig.rewardRate,
            _computeInterval(lastUpdateTime, rewardConfig.startTime, rewardConfig.endTime),
            totalShares()
        );
        uint256 rewardAmount =
            _computeReward(rewardConfig, userShares(_user), rewardPerToken, userLastRewardPerToken[_user]);
        return rewardAmount + pendingRewards[_user];
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

    function getUserLastRewardPerToken(address _user) public view returns (uint256) {
        return userLastRewardPerToken[_user];
    }

    function getPendingReward(address _user) public view returns (uint256) {
        return pendingRewards[_user];
    }

    // Internal
    function _updateReward(address _user) internal returns (uint256) {
        uint256 rewardPerToken = _updateRewardPerToken();
        uint256 rewardAmount =
            _computeReward(rewardConfig, userShares(_user), rewardPerToken, userLastRewardPerToken[_user]);
        _updateUserRewardPerToken(_user, rewardPerToken);
        pendingRewards[_user] += rewardAmount;
        emit UpdatePendingReward(_user, rewardAmount, block.timestamp);
        return rewardAmount;
    }

    function _computeReward(
        RewardConfig memory _config,
        uint256 _amount,
        uint256 _rewardPerToken,
        uint256 _lastRewardPerToken
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
        uint256 rewardAmount = RewardVaultMath.computeReward(_amount, _rewardPerToken, _lastRewardPerToken);
        return rewardAmount;
    }

    function _computeLatestRewardPerToken(
        uint256 _rewardRate,
        uint256 _interval,
        uint256 _totalShares
    )
        internal
        view
        returns (uint256)
    {
        return lastRewardPerToken + RewardVaultMath.computeRewardPerToken(_rewardRate, _interval, _totalShares);
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
        userLastRewardPerToken[_user] = _rewardPerToken;
        emit UpdateUserRewardPerToken(_user, _rewardPerToken, block.timestamp);
    }

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
