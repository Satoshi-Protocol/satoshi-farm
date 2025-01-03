// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { IFarmingVaultManager } from "../../src/interfaces/IFarmingVaultManager.sol";
import { IRewardManager } from "../../src/interfaces/IRewardManager.sol";
import { ITimeBasedRewardVault, RewardConfig } from "../../src/interfaces/ITimeBasedRewardVault.sol";
import { IVaultManager } from "../../src/interfaces/IVaultManager.sol";
import { FarmingVaultMath } from "../../src/libraries/FarmingVaultMath.sol";
import { RewardVaultMath } from "../../src/libraries/RewardVaultMath.sol";

import { TestBase } from "./TestBase.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract VaultTestBase is TestBase {
    function deposit(
        address manager,
        address user,
        uint256 amount,
        address vault,
        address asset
    )
        public
        returns (uint256)
    {
        uint256 balanceBefore = IERC20(asset).balanceOf(user);
        vm.startPrank(user);
        IERC20(asset).approve(manager, amount);
        uint256 shares = IVaultManager(manager).deposit(amount, vault, user);
        vm.stopPrank();
        checkBalance(IERC20(asset), user, balanceBefore - amount);
        return shares;
    }

    function withdraw(
        address manager,
        address user,
        uint256 amount,
        address vault,
        address asset
    )
        public
        returns (uint256)
    {
        uint256 balanceBefore = IERC20(asset).balanceOf(user);
        vm.startPrank(user);
        uint256 assets = IVaultManager(manager).withdraw(amount, vault, user, user);
        vm.stopPrank();
        checkBalance(IERC20(asset), user, balanceBefore + assets);
        return assets;
    }

    function claimReward(address manager, address user, address vault, address asset) public returns (uint256) {
        uint256 balanceBefore = IERC20(asset).balanceOf(user);
        vm.startPrank(user);
        uint256 reward = IRewardManager(manager).claimReward(vault, user, user);
        vm.stopPrank();
        checkBalance(IERC20(asset), user, balanceBefore + reward);
        return reward;
    }

    function claimAndStake(
        address manager,
        address user,
        address vault,
        address reward,
        uint256 stakeAmount
    )
        public
        returns (uint256, uint256)
    {
        IFarmingVaultManager farmingVaultManager = IFarmingVaultManager(manager);

        uint256 rewardAmount = computeReward(vault, user);
        uint256 refundAmount =
            computeRefundAmount(farmingVaultManager.getGlobalConfig().refundRatio, stakeAmount, rewardAmount);
        uint256 balanceBefore = IERC20(reward).balanceOf(user);
        vm.startPrank(user);
        (uint256 claimed, uint256 staked) = IFarmingVaultManager(manager).claimAndStake(vault, user, user, stakeAmount);
        vm.stopPrank();
        checkBalance(IERC20(reward), user, balanceBefore + claimed);
        assertEq(staked, stakeAmount);
        assertEq(claimed, refundAmount);
        return (claimed, staked);
    }

    function computeReward(address vault, address user) public view returns (uint256) {
        ITimeBasedRewardVault timeBasedRewardVault = ITimeBasedRewardVault(address(vault));
        uint256 lastRewardPerToken = timeBasedRewardVault.getLastRewardPerToken();
        uint256 totalShares = timeBasedRewardVault.totalShares();
        uint256 lastUpdateTime = timeBasedRewardVault.getLastUpdateTime();
        uint256 pendingReward = timeBasedRewardVault.getPendingReward(user);
        uint256 userShares = timeBasedRewardVault.userShares(user);
        RewardConfig memory rewardConfig = timeBasedRewardVault.getRewardConfig();
        uint256 interval = RewardVaultMath.computeInterval(
            block.timestamp, lastUpdateTime, rewardConfig.startTime, rewardConfig.endTime
        );
        uint256 latestRewardPerToken =
            RewardVaultMath.computeRewardPerToken(rewardConfig.rewardRate, interval, totalShares);
        uint256 expectedReward =
            pendingReward + RewardVaultMath.computeReward(userShares, latestRewardPerToken, lastRewardPerToken);
        return expectedReward;
    }

    function computeRefundAmount(
        uint256 refundRatio,
        uint256 stakeAmount,
        uint256 rewardAmount
    )
        public
        pure
        returns (uint256)
    {
        uint256 toClaimAmount = rewardAmount - stakeAmount;
        return FarmingVaultMath.computeRefundAmount(refundRatio, toClaimAmount);
    }
}
