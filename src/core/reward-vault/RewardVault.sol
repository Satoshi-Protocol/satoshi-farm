// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IRewardManager } from "../../interfaces/IRewardManager.sol";
import { IRewardVault } from "../../interfaces/IRewardVault.sol";

import { IRewardVaultMintCallback } from "../../interfaces/callbacks/IRewardVaultMintCallback.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

abstract contract RewardVault is IRewardVault {
    error InvalidReward(address reward);

    event RewardClaimed(address indexed reward, address indexed owner, address indexed recipient, uint256 amount);

    IERC20 public immutable UNDERLYING_REWARD;
    IRewardManager public rewardManager;

    constructor(IERC20 _reward) {
        UNDERLYING_REWARD = _reward;
    }

    function rewardBalance() public view returns (uint256) {
        return UNDERLYING_REWARD.balanceOf(address(this));
    }

    function reward() public view returns (address) {
        return address(UNDERLYING_REWARD);
    }

    function totalShares() public view virtual returns (uint256);
}
