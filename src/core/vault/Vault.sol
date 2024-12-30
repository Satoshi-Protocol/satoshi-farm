// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IVault } from "../../interfaces/IVault.sol";
import { IVaultManager } from "../../interfaces/IVaultManager.sol";
import { IVaultDepositAssetCallback } from "../../interfaces/callbacks/IVaultDepositAssetCallback.sol";

import { IRewardManager } from "../../interfaces/IRewardManager.sol";

import { IRewardVault } from "../../interfaces/IRewardVault.sol";
import { IRewardVaultMintCallback } from "../../interfaces/callbacks/IRewardVaultMintCallback.sol";
import { RewardVault } from "../reward-vault/RewardVault.sol";
import { TimeBasedRewardVault } from "../reward-vault/TimeBasedRewardVault.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC4626Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vault is IVault, TimeBasedRewardVault, ERC4626Upgradeable, UUPSUpgradeable {
    IERC20 public immutable UNDERLYING_ASSET;
    IVaultManager public vaultManager;

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }

    constructor(IERC20 _underlyingAsset, IERC20 _reward) RewardVault(_reward) {
        UNDERLYING_ASSET = _underlyingAsset;
        _disableInitializers();
    }

    function initialize(address _vaultManager) public initializer {
        __ERC4626_init(UNDERLYING_ASSET);
        __UUPSUpgradeable_init();
        vaultManager = IVaultManager(_vaultManager);
        rewardManager = IRewardManager(_vaultManager);
    }

    function deposit(uint256 _assets, address _depositor, address _receiver) public onlyManager returns (uint256) {
        claimReward(_depositor, _receiver);
        uint256 shares = _deposit(_assets, _depositor, _receiver);
        return shares;
    }

    function deposit(
        uint256 _assets,
        address _receiver
    )
        public
        override(ERC4626Upgradeable, IERC4626)
        onlyManager
        returns (uint256)
    {
        return _deposit(_assets, msg.sender, _receiver);
    }

    function withdraw(
        uint256 _amount,
        address _receiver,
        address _owner
    )
        public
        override(ERC4626Upgradeable, IVault)
        onlyManager
        returns (uint256)
    {
        uint256 maxAssets = maxWithdraw(_owner);
        if (_amount > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(_owner, _amount, maxAssets);
        }
        uint256 reward = claimReward(_owner, _receiver);

        uint256 shares = previewWithdraw(_amount);
        if (_msgSender() != address(vaultManager)) {
            _withdraw(_msgSender(), _receiver, _owner, _amount, shares);
        } else {
            _withdraw(_owner, _receiver, _owner, _amount, shares);
        }
        userRewards[_owner].amount -= _amount;
        return shares;
    }

    function asset() public view override(ERC4626Upgradeable, IVault) returns (address) {
        return super.asset();
    }

    function totalAssets() public view override(ERC4626Upgradeable, IVault) returns (uint256) {
        return super.totalAssets();
    }

    function allocateReward(address, address, uint256) external pure returns (uint256) {
        revert("Not implemented");
    }

    // internal functions
    function _deposit(uint256 _assets, address _depositor, address _receiver) internal returns (uint256) {
        uint256 shares = _depositAsset(_depositor, _receiver, _assets);
        userRewards[_depositor].amount += _assets;
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

    function owner() public view returns (address) {
        return Ownable(address(vaultManager)).owner();
    }

    function totalShares() public view override(RewardVault, IRewardVault) returns (uint256) {
        return totalSupply();
    }

    function _claimReward(address, address _recipient, uint256 _amount) internal override returns (uint256) {
        IERC20 token = IERC20(reward());
        uint256 balanceBefore = token.balanceOf(_recipient);
        IRewardVaultMintCallback(address(vaultManager)).rewardVaultMintCallback(address(token), _recipient, _amount, "");
        uint256 balanceAfter = token.balanceOf(_recipient);
        uint256 balanceChange = balanceAfter - balanceBefore;
        if (balanceChange != _amount) {
            revert RewardBalanceChangedUnexpectedly(_amount, balanceChange);
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner(), "Only owner can call this function");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == address(vaultManager), "Only manager can call this function");
        _;
    }
}
