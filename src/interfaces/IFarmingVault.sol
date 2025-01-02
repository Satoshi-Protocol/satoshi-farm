// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { IRewardVault } from "./IRewardVault.sol";

import { RewardConfig } from "./ITimeBasedRewardVault.sol";
import { IVault, VaultConfig } from "./IVault.sol";

struct FarmingVaultConfig {
    uint256 claimStartTime;
    uint256 maxAsset;
}

interface IFarmingVault {
    error InvalidFarmingVaultManager(address caller, address manager);
    error InvalidStakeTime(uint256 currentTime, uint256 stakeEndTime);
    error NotSupportClaimAndStake();

    event RewardStaked(address indexed rewardToken, address indexed owner, uint256 amount);
    event RewardRefunded(address indexed rewardToken, address indexed owner, uint256 amount);
    event RewardBurned(address indexed rewardToken, address indexed owner, uint256 amount);

    function updateFarmingVaultConfig(VaultConfig memory _config, RewardConfig memory _rewardConfig) external;

    function claimAndStake(
        address _owner,
        address _receiver,
        uint256 _stakeAmount
    )
        external
        returns (uint256, uint256);
}
