// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IRewardManager } from "../../interfaces/IRewardManager.sol";
import { IRewardVault } from "../../interfaces/IRewardVault.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract RewardManager is IRewardManager {
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
        return IRewardVault(vault).claimReward(owner, recipient);
    }

    function isValidVault(address vault) public view virtual returns (bool);
}
