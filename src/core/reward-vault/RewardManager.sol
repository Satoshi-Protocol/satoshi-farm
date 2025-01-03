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

    // --- admin functions ---
    function updateRewardConfig(address _vault, RewardConfig memory _config) external onlyAdmin {
        if (!isValidVault(_vault)) {
            revert InvalidRewardVault(_vault);
        }
        ITimeBasedRewardVault(_vault).updateRewardConfig(_config);
    }

    function previewReward(address _vault, address _owner) external view returns (uint256) {
        if (!isValidVault(_vault)) {
            revert InvalidRewardVault(_vault);
        }
        return IRewardVault(_vault).previewReward(_owner);
    }

    function claimReward(address _vault, address _recipient) external returns (uint256) {
        if (!isValidVault(_vault)) {
            revert InvalidRewardVault(_vault);
        }
        uint256 amount = IRewardVault(_vault).claimReward(msg.sender, _recipient);
        emit ClaimReward(_vault, msg.sender, _recipient);
        return amount;
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

    function isValidVault(address vault) public view virtual returns (bool);

    function admin() public view virtual returns (address);

    modifier onlyAdmin() virtual {
        if (msg.sender != admin()) {
            revert("InvalidAdmin");
        }
        _;
    }
}
