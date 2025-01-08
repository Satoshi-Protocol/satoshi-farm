// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { RewardVault } from "./core/reward-vault/RewardVault.sol";
import { TimeBasedRewardVault } from "./core/reward-vault/TimeBasedRewardVault.sol";
import { Vault } from "./core/vault/Vault.sol";
import { FarmingVaultConfig, IFarmingVault } from "./interfaces/IFarmingVault.sol";

import { IFarmingVaultManager } from "./interfaces/IFarmingVaultManager.sol";

import { IRewardManager } from "./interfaces/IRewardManager.sol";
import { IRewardToken } from "./interfaces/IRewardToken.sol";
import { IRewardVault } from "./interfaces/IRewardVault.sol";
import { RewardConfig } from "./interfaces/ITimeBasedRewardVault.sol";
import { IVault, VaultConfig } from "./interfaces/IVault.sol";
import { IVaultManager } from "./interfaces/IVaultManager.sol";
import { FarmingVaultMath } from "./libraries/FarmingVaultMath.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FarmingVault is Vault, TimeBasedRewardVault, IFarmingVault, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    // --- state variables ---
    IVault public goldFarmingVault;
    FarmingVaultConfig public farmingVaultConfig;
    IFarmingVaultManager public farmingVaultManager;

    // only owner can upgrade
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }

    function initialize(
        IERC20 _asset,
        IERC20 _reward,
        address _vaultManager,
        address _goldFarmingVault
    )
        public
        initializer
    {
        __TimeBasedRewardVault__init(_reward, _vaultManager);
        __Vault__init(_asset, _vaultManager);
        __UUPSUpgradeable_init();
        vaultManager = IVaultManager(_vaultManager);
        rewardManager = IRewardManager(_vaultManager);
        goldFarmingVault = IVault(_goldFarmingVault);
        farmingVaultManager = IFarmingVaultManager(_vaultManager);
    }

    // --- manager functions ---
    function updateFarmingVaultConfig(
        FarmingVaultConfig memory _config,
        VaultConfig memory _vaultConfig,
        RewardConfig memory _rewardConfig
    )
        public
        onlyFarmingVaultManager
    {
        farmingVaultConfig = _config;
        updateConfig(_vaultConfig);
        updateRewardConfig(_rewardConfig);
    }

    function claimAndStake(
        address _owner,
        address _receiver,
        uint256 _stakeAmount
    )
        public
        onlyFarmingVaultManager
        returns (uint256, uint256)
    {
        if (_isGoldFarmingVault()) {
            revert NotSupportClaimAndStake();
        }

        if (block.timestamp >= rewardConfig.claimStartTime) {
            revert InvalidStakeTime(block.timestamp, rewardConfig.claimStartTime);
        }

        _updateReward(_owner);
        uint256 pendingReward = pendingRewards[_owner];

        if (pendingReward == 0) {
            return (0, 0);
        }
        uint256 rewardAmount = _claimReward(_owner, address(this), pendingReward);
        emit RewardClaimed(reward(), _owner, address(this), pendingReward);
        pendingRewards[_owner] = 0;
        if (rewardAmount < _stakeAmount) {
            _stakeReward(rewardAmount, _receiver);
            return (0, rewardAmount);
        }
        _stakeReward(_stakeAmount, _receiver);
        (uint256 claimAmount,) = _penalise(rewardAmount - _stakeAmount, _owner);
        return (claimAmount, _stakeAmount);
    }

    // --- public functions ---
    function totalShares() public view override(RewardVault, IRewardVault) returns (uint256) {
        return totalAssets;
    }

    function userShares(address user) public view override(RewardVault, IRewardVault) returns (uint256) {
        return assets[user];
    }

    function owner() public view returns (address) {
        return Ownable(address(vaultManager)).owner();
    }

    function getFarmingVaultConfig() public view returns (FarmingVaultConfig memory) {
        return farmingVaultConfig;
    }

    // --- internal functions ---
    function _isGoldFarmingVault() internal view returns (bool) {
        return address(goldFarmingVault) == address(0);
    }

    function _stakeReward(uint256 _amount, address _receiver) internal returns (uint256) {
        IERC20(reward()).approve(address(vaultManager), _amount);
        uint256 shares = IVaultManager(vaultManager).deposit(_amount, address(goldFarmingVault), _receiver);
        emit RewardStaked(reward(), _receiver, _amount);
        return shares;
    }

    function _penalise(uint256 _amount, address _receiver) internal returns (uint256, uint256) {
        uint256 penaltyRatio = farmingVaultConfig.penaltyRatio;
        uint256 penaltyAmount = FarmingVaultMath.computePenaltyAmount(penaltyRatio, _amount);
        uint256 claimAmount = _amount - penaltyAmount;
        IERC20(reward()).safeTransfer(_receiver, claimAmount);
        emit RewardClaimed(reward(), _receiver, claimAmount);
        _burnReward(penaltyAmount);
        emit RewardPenalised(reward(), _receiver, penaltyAmount);
        return (claimAmount, penaltyAmount);
    }

    function _burnReward(uint256 _amount) internal returns (uint256) {
        IRewardToken(reward()).burn(address(this), _amount);
        return _amount;
    }

    modifier onlyOwner() {
        if (msg.sender != owner()) {
            revert InvalidOwner(msg.sender, owner());
        }
        _;
    }

    modifier onlyFarmingVaultManager() {
        if (msg.sender != address(farmingVaultManager)) {
            revert InvalidFarmingVaultManager(msg.sender, address(farmingVaultManager));
        }
        _;
    }
}
