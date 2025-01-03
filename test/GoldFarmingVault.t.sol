// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { IFarmingVault } from "../src/interfaces/IFarmingVault.sol";
import { IFarmingVaultManager } from "../src/interfaces/IFarmingVaultManager.sol";

import { IRewardManager } from "../src/interfaces/IRewardManager.sol";
import { IRewardVault } from "../src/interfaces/IRewardVault.sol";
import { ITimeBasedRewardVault } from "../src/interfaces/ITimeBasedRewardVault.sol";
import { IVault } from "../src/interfaces/IVault.sol";
import { IVaultManager } from "../src/interfaces/IVaultManager.sol";
import { RewardVaultMath } from "../src/libraries/RewardVaultMath.sol";
import { Deployers } from "./utils/Deployers.sol";
import { VaultTest } from "./utils/VaultTest.sol";

contract GoldFarmingVaultTest is VaultTest {
    function testFuzz_user_deposit(uint256 amount) public {
        vm.assume(amount <= config.maxAsset);
        vm.assume(amount <= gold.balanceOf(user_1));
        deposit(address(manager), user_1, amount, address(goldFarmingVault), address(gold));
    }

    function testFuzz_user_deposit_exceed_max_asset(uint256 amount) public {
        vm.assume(amount > config.maxAsset);
        vm.assume(amount <= gold.balanceOf(user_1));
        vm.startPrank(user_1);
        gold.approve(address(manager), amount);
        vm.expectPartialRevert(IVault.MaxAssetExceeded.selector);
        IVaultManager(address(manager)).deposit(amount, address(goldFarmingVault), user_1);
        vm.stopPrank();
    }

    function testFuzz_user_withdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        vm.assume(depositAmount <= config.maxAsset);
        vm.assume(withdrawAmount <= depositAmount);
        vm.assume(withdrawAmount < gold.balanceOf(user_1));
        deposit(address(manager), user_1, depositAmount, address(goldFarmingVault), address(gold));
        withdraw(address(manager), user_1, withdrawAmount, address(goldFarmingVault), address(gold));
    }

    function testFuzz_user_claim_reward(uint256 amount) public {
        vm.assume(amount <= config.maxAsset);
        vm.assume(amount <= gold.balanceOf(user_1));
        uint256 depositTime = block.timestamp;
        uint256 secondsPassed = config.claimStartTime - depositTime + 1;

        deposit(address(manager), user_1, amount, address(goldFarmingVault), address(gold));

        vm.warp(depositTime + secondsPassed);

        uint256 expectedReward = computeReward(address(goldFarmingVault), user_1);
        uint256 actualReward = IRewardVault(address(goldFarmingVault)).previewReward(user_1);
        assertEq(actualReward, expectedReward);

        claimReward(address(manager), user_1, address(goldFarmingVault), address(gold));
    }

    function testFuzz_user_claim_reward_before_claim_start_time(uint256 amount, uint256 claimTime) public {
        vm.assume(amount <= config.maxAsset);
        vm.assume(amount <= gold.balanceOf(user_1));

        vm.assume(claimTime > block.timestamp);
        vm.assume(claimTime < config.claimStartTime);

        deposit(address(manager), user_1, amount, address(goldFarmingVault), address(gold));

        vm.warp(claimTime);

        vm.startPrank(user_1);
        vm.expectPartialRevert(ITimeBasedRewardVault.ClaimNotStarted.selector);
        IRewardManager(address(manager)).claimReward(address(goldFarmingVault), user_1, user_1);
        vm.stopPrank();
    }

    function testFuzz_user_claim_and_stake(uint256 amount, uint256 claimTime) public {
        vm.assume(amount <= config.maxAsset);
        vm.assume(amount <= gold.balanceOf(user_1));

        vm.assume(claimTime > block.timestamp);
        vm.assume(claimTime < config.claimStartTime);

        deposit(address(manager), user_1, amount, address(goldFarmingVault), address(gold));

        vm.warp(claimTime);

        vm.startPrank(user_1);
        vm.expectPartialRevert(IFarmingVault.NotSupportClaimAndStake.selector);
        manager.claimAndStake(address(goldFarmingVault), user_1, user_1, amount);
        vm.stopPrank();
    }
}
