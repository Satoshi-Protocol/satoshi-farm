// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library RewardVaultMath {
    uint256 internal constant REWARD_PER_TOKEN_PRECISION = 1e18;

    function computeRewardPerToken(
        uint256 _rewardRate,
        uint256 _interval,
        uint256 _totalShares
    )
        internal
        pure
        returns (uint256)
    {
        if (_totalShares == 0) {
            return 0;
        }
        uint256 rewardPerToken = (_rewardRate * _interval * REWARD_PER_TOKEN_PRECISION) / _totalShares;
        return rewardPerToken;
    }

    function computeReward(
        uint256 _userAmount,
        uint256 _latestRewardPerToken,
        uint256 _rewardPerToken
    )
        internal
        pure
        returns (uint256)
    {
        uint256 rewardAmount = (_userAmount * (_latestRewardPerToken - _rewardPerToken)) / REWARD_PER_TOKEN_PRECISION;
        return rewardAmount;
    }

    function computeInterval(
        uint256 _currentTime,
        uint256 _lastUpdateTime,
        uint256 _startTime,
        uint256 _endTime
    )
        internal
        pure
        returns (uint256)
    {
        if (_currentTime < _startTime) {
            return 0;
        }
        if (_currentTime > _endTime) {
            return _endTime - _lastUpdateTime;
        }
        return _currentTime - _lastUpdateTime;
    }
}
