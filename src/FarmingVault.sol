// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { RewardVault } from "./core/reward-vault/RewardVault.sol";
import { TimeBasedRewardVault } from "./core/reward-vault/TimeBasedRewardVault.sol";
import { Vault } from "./core/vault/Vault.sol";
import { FarmingVaultConfig, IFarmingVault } from "./interfaces/IFarmingVault.sol";

import { IFarmingVaultManager } from "./interfaces/IFarmingVaultManager.sol";
import { IPointToken } from "./interfaces/IPointToken.sol";
import { IRewardManager } from "./interfaces/IRewardManager.sol";
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
        __ERC4626_init(_asset);
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
        VaultConfig memory _config,
        RewardConfig memory _rewardConfig
    )
        public
        override
        onlyFarmingVaultManager
    {
        updateConfig(_config);
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
        uint256 refundAmount = _refundReward(rewardAmount - _stakeAmount, _owner);
        return (refundAmount, _stakeAmount);
    }

    // --- public functions ---
    function totalShares() public view override(RewardVault, IRewardVault) returns (uint256) {
        return totalSupply();
    }

    function userShares(address user) public view override(RewardVault, IRewardVault) returns (uint256) {
        return balanceOf(user);
    }

    function owner() public view returns (address) {
        return Ownable(address(vaultManager)).owner();
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

    function _refundReward(uint256 _amount, address _receiver) internal returns (uint256) {
        uint256 refundRatio = farmingVaultManager.getGlobalConfig().refundRatio;
        uint256 refundAmount = FarmingVaultMath.computeRefundAmount(refundRatio, _amount);
        IERC20(reward()).safeTransfer(_receiver, refundAmount);
        emit RewardRefunded(reward(), _receiver, refundAmount);
        _burnReward(_amount - refundAmount);
        emit RewardBurned(reward(), _receiver, _amount - refundAmount);
        return refundAmount;
    }

    function _burnReward(uint256 _amount) internal returns (uint256) {
        IPointToken(reward()).burn(address(this), _amount);
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
