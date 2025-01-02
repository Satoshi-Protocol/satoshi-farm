// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IRewardManager } from "../../interfaces/IRewardManager.sol";
import { IRewardVault } from "../../interfaces/IRewardVault.sol";

import { IRewardVaultMintCallback } from "../../interfaces/callbacks/IRewardVaultMintCallback.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

abstract contract RewardVault is IRewardVault, Initializable {
    IERC20 public underlyingReward;
    IRewardManager public rewardManager;

    function __RewardVault__init(IERC20 _reward, address _rewardManager) internal onlyInitializing {
        underlyingReward = _reward;
        rewardManager = IRewardManager(_rewardManager);
    }

    function rewardBalance() public view returns (uint256) {
        return underlyingReward.balanceOf(address(this));
    }

    function reward() public view returns (address) {
        return address(underlyingReward);
    }

    function totalShares() public view virtual returns (uint256);

    function userShares(address user) public view virtual returns (uint256);

    function _claimReward(address, address _recipient, uint256 _amount) internal virtual returns (uint256) {
        IERC20 token = IERC20(reward());
        uint256 balanceBefore = token.balanceOf(_recipient);
        IRewardVaultMintCallback(address(rewardManager)).rewardVaultMintCallback(
            address(token), _recipient, _amount, ""
        );
        uint256 balanceAfter = token.balanceOf(_recipient);
        uint256 balanceChange = balanceAfter - balanceBefore;
        if (balanceChange != _amount) {
            revert RewardBalanceChangedUnexpectedly(_amount, balanceChange);
        }
        return _amount;
    }

    modifier onlyRewardManager() {
        if (msg.sender != address(rewardManager)) {
            revert InvalidRewardManager(msg.sender, address(rewardManager));
        }
        _;
    }
}
