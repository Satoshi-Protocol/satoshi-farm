// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardManager {
    error InvalidRewardVault(address vault);

    event ClaimRewards(address rewardVault, address owner, address recipient);
    event AllocateReward(address rewardVault, address token, uint256 amount);

    function previewReward(address vault, address owner) external view returns (uint256);

    function claimReward(address vault, address owner, address recipient) external returns (uint256);

    function allocateReward(
        address token,
        address[] memory rewardVaults,
        uint256[] memory amounts
    )
        external
        returns (uint256[] memory);
}
