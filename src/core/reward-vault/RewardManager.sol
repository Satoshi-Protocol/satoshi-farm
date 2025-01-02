// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IPointToken } from "../../interfaces/IPointToken.sol";
import { IRewardManager } from "../../interfaces/IRewardManager.sol";
import { IRewardVault } from "../../interfaces/IRewardVault.sol";
import { ITimeBasedRewardVault, RewardConfig } from "../../interfaces/ITimeBasedRewardVault.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract RewardManager is IRewardManager, Initializable {
    IPointToken public underlyingReward;

    function __RewardManager__init(IPointToken _underlyingReward) internal onlyInitializing {
        underlyingReward = _underlyingReward;
    }

    function previewReward(address vault, address owner) external view returns (uint256) {
        if (!isValidVault(vault)) {
            revert InvalidRewardVault(vault);
        }
        return IRewardVault(vault).previewReward(owner);
    }

    function claimReward(address vault, address owner, address recipient) external returns (uint256) {
        if (!isValidVault(vault)) {
            revert InvalidRewardVault(vault);
        }
        if (msg.sender != owner) {
            revert InvalidOwner(msg.sender);
        }
        return IRewardVault(vault).claimReward(owner, recipient);
    }

    function rewardVaultMintCallback(address reward, address recipient, uint256 amount, bytes calldata) external {
        if (!isValidVault(msg.sender)) {
            revert InvalidRewardVault(msg.sender);
        }
        if (reward != address(underlyingReward)) {
            revert InvalidReward(address(underlyingReward), reward);
        }
        underlyingReward.mint(recipient, amount);
    }

    function updateRewardConfig(address vault, RewardConfig memory config) external {
        if (!isValidVault(vault)) {
            revert InvalidRewardVault(vault);
        }
        ITimeBasedRewardVault(vault).updateRewardConfig(config);
    }

    function isValidVault(address vault) public view virtual returns (bool);
}
