// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { IRewardVault } from "./IRewardVault.sol";

import { RewardConfig } from "./ITimeBasedRewardVault.sol";
import { IVault, VaultConfig } from "./IVault.sol";

struct FarmingVaultConfig {
    uint256 penaltyRatio;
}

interface IFarmingVault {
    error InvalidFarmingVaultManager(address caller, address manager);
    error InvalidStakeTime(uint256 currentTime, uint256 stakeEndTime);
    error NotSupportClaimAndStake();

    event RewardStaked(address indexed rewardToken, address indexed owner, uint256 amount);
    event RewardPenalised(address indexed rewardToken, address indexed owner, uint256 amount);
    event RewardClaimed(address indexed rewardToken, address indexed owner, uint256 amount);

    function updateFarmingVaultConfig(
        FarmingVaultConfig memory _config,
        VaultConfig memory _vaultConfig,
        RewardConfig memory _rewardConfig
    )
        external;

    function claimAndStake(
        address _owner,
        address _receiver,
        uint256 _stakeAmount
    )
        external
        returns (uint256, uint256);

    function getFarmingVaultConfig() external view returns (FarmingVaultConfig memory);
}
