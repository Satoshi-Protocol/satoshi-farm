// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IRewardManager } from "../../interfaces/IRewardManager.sol";
import { IRewardVault } from "../../interfaces/IRewardVault.sol";
import { IVault, VaultConfig } from "../../interfaces/IVault.sol";
import { IVaultManager } from "../../interfaces/IVaultManager.sol";
import { IRewardVaultMintCallback } from "../../interfaces/callbacks/IRewardVaultMintCallback.sol";
import { IVaultDepositAssetCallback } from "../../interfaces/callbacks/IVaultDepositAssetCallback.sol";
import { RewardVault } from "../reward-vault/RewardVault.sol";
import { TimeBasedRewardVault } from "../reward-vault/TimeBasedRewardVault.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Vault is Initializable, IVault {
    using SafeERC20 for IERC20;

    IERC20 public underlyingAsset;
    IVaultManager public vaultManager;
    VaultConfig public vaultConfig;

    mapping(address => uint256) public assets;
    uint256 public totalAssets;

    function __Vault__init(IERC20 _underlyingAsset, address _vaultManager) internal onlyInitializing {
        underlyingAsset = _underlyingAsset;
        vaultManager = IVaultManager(_vaultManager);
    }

    // --- manager functions ---
    function deposit(
        uint256 _assets,
        address _depositor,
        address _receiver
    )
        public
        onlyVaultManager
        returns (uint256)
    {
        if (_assets > maxDeposit(_depositor)) {
            revert MaxDeposit(_assets, maxDeposit(_depositor));
        }
        uint256 shares = _deposit(_assets, _depositor, _receiver);
        return shares;
    }

    function withdraw(
        uint256 _amount,
        address _receiver,
        address _owner
    )
        public
        virtual
        onlyVaultManager
        returns (uint256)
    {
        if (_amount > maxWithdraw(_owner)) {
            revert MaxWithdraw(_amount, maxWithdraw(_owner));
        }

        return _withdraw(_owner, _receiver, _amount);
    }

    function updateConfig(VaultConfig memory _config) public override onlyVaultManager {
        vaultConfig = _config;
    }

    // --- public functions ---
    function asset() public view virtual override returns (address) {
        return address(underlyingAsset);
    }

    function config() public view override returns (VaultConfig memory) {
        return vaultConfig;
    }

    function maxDeposit(address) public view returns (uint256) {
        return vaultConfig.maxAsset - totalAssets;
    }

    function maxWithdraw(address _owner) public view returns (uint256) {
        return assets[_owner];
    }

    function assetBalance() public view returns (uint256) {
        return underlyingAsset.balanceOf(address(this));
    }

    // internal functions
    function _deposit(uint256 _assets, address _depositor, address _receiver) internal virtual returns (uint256) {
        uint256 shares = _depositAsset(_depositor, _receiver, _assets);
        return shares;
    }

    function _withdraw(address _owner, address _receiver, uint256 _amount) internal virtual returns (uint256) {
        _withdrawAsset(_owner, _receiver, _amount);
        return _amount;
    }

    function _depositAsset(address _depositor, address _receiver, uint256 _amount) internal returns (uint256) {
        uint256 balanceBefore = assetBalance();
        IVaultDepositAssetCallback(address(vaultManager)).vaultDepositAssetCallback(
            address(asset()), _depositor, _amount, ""
        );
        uint256 balanceAfter = assetBalance();
        uint256 balanceChange = balanceAfter - balanceBefore;
        if (balanceChange != _amount) {
            revert AssetBalanceChangedUnexpectedly(_amount, balanceChange);
        }

        _updateAsset(_depositor, _amount, true);

        emit Deposit(_amount, _receiver, _depositor);
        return _amount;
    }

    function _withdrawAsset(address _owner, address _receiver, uint256 _amount) internal {
        underlyingAsset.safeTransfer(_receiver, _amount);
        _updateAsset(_owner, _amount, false);
        emit Withdraw(_amount, _receiver, _owner);
    }

    function _updateAsset(address _owner, uint256 _amount, bool _add) internal {
        if (_add) {
            assets[_owner] += _amount;
            totalAssets += _amount;
        } else {
            assets[_owner] -= _amount;
            totalAssets -= _amount;
        }
    }

    modifier onlyVaultManager() {
        if (msg.sender != address(vaultManager)) {
            revert InvalidVaultManager(msg.sender, address(vaultManager));
        }
        _;
    }
}
