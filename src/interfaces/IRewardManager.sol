// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { RewardConfig } from "./ITimeBasedRewardVault.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardManager {
    error InvalidRewardVault(address vault);
    error InvalidReward(address expected, address actual);
    error InvalidRewardOwner(address expected, address actual);

    event ClaimRewards(address rewardVault, address owner, address recipient);
    event AllocateReward(address rewardVault, address token, uint256 amount);

    function previewReward(address vault, address owner) external view returns (uint256);

    function claimReward(address vault, address owner, address recipient) external returns (uint256);

    function updateRewardConfig(address vault, RewardConfig memory config) external;
}
