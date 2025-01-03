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
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ERC4626Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vault is Initializable, IVault, ERC4626Upgradeable {
    IERC20 public underlyingAsset;
    IVaultManager public vaultManager;
    VaultConfig public vaultConfig;

    function __Vault__init(IERC20 _underlyingAsset, address _vaultManager) internal onlyInitializing {
        __ERC4626_init(_underlyingAsset);
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
        if (totalAssets() + _assets > vaultConfig.maxAsset) {
            revert MaxAssetExceeded(totalAssets() + _assets, vaultConfig.maxAsset);
        }
        uint256 shares = _deposit(_assets, _depositor, _receiver);
        return shares;
    }

    function deposit(
        uint256 _assets,
        address _receiver
    )
        public
        virtual
        override(ERC4626Upgradeable, IERC4626)
        onlyVaultManager
        returns (uint256)
    {
        if (totalAssets() + _assets > vaultConfig.maxAsset) {
            revert MaxAssetExceeded(totalAssets() + _assets, vaultConfig.maxAsset);
        }
        return _deposit(_assets, msg.sender, _receiver);
    }

    function withdraw(
        uint256 _amount,
        address _receiver,
        address _owner
    )
        public
        virtual
        override(ERC4626Upgradeable, IVault)
        onlyVaultManager
        returns (uint256)
    {
        uint256 maxAssets = maxWithdraw(_owner);
        if (_amount > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(_owner, _amount, maxAssets);
        }

        uint256 shares = previewWithdraw(_amount);
        _withdraw(_owner, _receiver, _owner, _amount, shares);
        return shares;
    }

    function updateConfig(VaultConfig memory _config) public override onlyVaultManager {
        vaultConfig = _config;
    }

    // --- public functions ---
    function asset() public view virtual override(ERC4626Upgradeable, IVault) returns (address) {
        return super.asset();
    }

    function totalAssets() public view virtual override(ERC4626Upgradeable, IVault) returns (uint256) {
        return super.totalAssets();
    }

    function config() public view override returns (VaultConfig memory) {
        return vaultConfig;
    }

    // internal functions
    function _deposit(uint256 _assets, address _depositor, address _receiver) internal virtual returns (uint256) {
        uint256 shares = _depositAsset(_depositor, _receiver, _assets);
        return shares;
    }

    function _depositAsset(address _depositor, address _receiver, uint256 _amount) internal returns (uint256) {
        uint256 maxAssets = maxDeposit(_receiver);
        if (_amount > maxAssets) {
            revert ERC4626ExceededMaxDeposit(_receiver, _amount, maxAssets);
        }
        uint256 shares = previewDeposit(_amount);

        uint256 balanceBefore = totalAssets();
        IVaultDepositAssetCallback(address(vaultManager)).vaultDepositAssetCallback(
            address(asset()), _depositor, _amount, ""
        );
        uint256 balanceAfter = totalAssets();
        uint256 balanceChange = balanceAfter - balanceBefore;
        if (balanceChange != _amount) {
            revert AssetBalanceChangedUnexpectedly(_amount, balanceChange);
        }

        _mint(_receiver, shares);

        emit Deposit(_msgSender(), _receiver, _amount, shares);
        return shares;
    }

    modifier onlyVaultManager() {
        if (msg.sender != address(vaultManager)) {
            revert InvalidVaultManager(msg.sender, address(vaultManager));
        }
        _;
    }

    // ---disable functions---
    function transfer(address, uint256) public pure override(ERC20Upgradeable, IERC20) returns (bool) {
        revert("Vault: Not allowed");
    }

    function transferFrom(address, address, uint256) public pure override(ERC20Upgradeable, IERC20) returns (bool) {
        revert("Vault: Not allowed");
    }

    function redeem(uint256, address, address) public pure override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        revert("Vault: Not allowed");
    }

    function mint(uint256, address) public pure override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        revert("Vault: Not allowed");
    }
}
