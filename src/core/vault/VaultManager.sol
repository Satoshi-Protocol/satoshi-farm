// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IVault, VaultConfig } from "../../interfaces/IVault.sol";
import { IVaultManager } from "../../interfaces/IVaultManager.sol";

import { IVaultDepositAssetCallback } from "../../interfaces/callbacks/IVaultDepositAssetCallback.sol";

import { IPointToken } from "../../interfaces/IPointToken.sol";
import { RewardManager } from "../reward-vault/RewardManager.sol";
import { Vault } from "./Vault.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract VaultManager is Initializable, IVaultManager {
    using SafeERC20 for IERC20;

    IPointToken public underlyingPointToken;

    function __VaultManager__init(IPointToken _underlyingPointToken) internal onlyInitializing {
        underlyingPointToken = _underlyingPointToken;
    }

    // --- admin functions ---
    function updateConfig(address _vault, VaultConfig memory _config) public onlyAdmin {
        if (!isValidVault(_vault)) {
            revert VaultNotValid();
        }
        IVault(_vault).updateConfig(_config);
    }

    // --- public functions ---
    function deposit(uint256 _assets, address _vault, address _receiver) public returns (uint256) {
        if (!isValidVault(_vault)) {
            revert VaultNotValid();
        }
        uint256 shares = IVault(_vault).deposit(_assets, msg.sender, _receiver);
        emit Deposit(_vault, _assets, _receiver);
        return shares;
    }

    function withdraw(uint256 _amount, address _vault, address _receiver) public returns (uint256) {
        if (!isValidVault(_vault)) {
            revert VaultNotValid();
        }

        uint256 assets = IVault(_vault).withdraw(_amount, _receiver, msg.sender);
        emit Withdraw(_vault, _amount, _receiver, msg.sender);
        return assets;
    }

    function vaultDepositAssetCallback(address _asset, address _depositor, uint256 _amount, bytes calldata) external {
        if (!verifyCallback()) {
            revert InvalidCallbackCaller(msg.sender);
        }
        // TODO: use safeTransferFrom
        IERC20(_asset).safeTransferFrom(_depositor, address(msg.sender), _amount);
    }

    function verifyCallback() public view returns (bool) {
        if (isValidVault(msg.sender)) {
            return true;
        }
        return false;
    }

    function isValidVault(address _vault) public view virtual returns (bool);

    function admin() public view virtual returns (address);

    modifier onlyAdmin() virtual {
        if (msg.sender != admin()) {
            revert("InvalidAdmin");
        }
        _;
    }
}
