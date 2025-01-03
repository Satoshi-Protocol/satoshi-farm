// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { IFarmingVault } from "../src/interfaces/IFarmingVault.sol";
import { FarmingVaultGlobalConfig, IFarmingVaultManager } from "../src/interfaces/IFarmingVaultManager.sol";

import { IRewardManager } from "../src/interfaces/IRewardManager.sol";
import { IRewardVault } from "../src/interfaces/IRewardVault.sol";
import { ITimeBasedRewardVault, RewardConfig } from "../src/interfaces/ITimeBasedRewardVault.sol";
import { IVault, VaultConfig } from "../src/interfaces/IVault.sol";
import { IVaultManager } from "../src/interfaces/IVaultManager.sol";

import { FarmingVaultMath } from "../src/libraries/FarmingVaultMath.sol";
import { RewardVaultMath } from "../src/libraries/RewardVaultMath.sol";
import { Deployers } from "./utils/Deployers.sol";
import { VaultTest } from "./utils/VaultTest.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract FarmingVaultTest is VaultTest {
    function test_disable_functions() public {
        IVault vault = IVault(address(farmingVault));
        vm.expectRevert("Vault: Not allowed");
        vault.transfer(user_1, 100);
        vm.expectRevert("Vault: Not allowed");
        vault.transferFrom(user_1, user_2, 100);
        vm.expectRevert("Vault: Not allowed");
        vault.redeem(100, user_1, user_1);
        vm.expectRevert("Vault: Not allowed");
        vault.mint(100, user_1);
    }

    function test_only_manager_can_call_functions() public {
        vm.expectPartialRevert(IFarmingVault.InvalidFarmingVaultManager.selector);
        farmingVault.claimAndStake(user_1, user_1, 1000);
        vm.expectPartialRevert(IFarmingVault.InvalidFarmingVaultManager.selector);
        farmingVault.updateFarmingVaultConfig(
            VaultConfig({ maxAsset: 1000 }),
            RewardConfig({ claimStartTime: 1000, claimEndTime: 1000, rewardRate: 1000, startTime: 1000, endTime: 1000 })
        );

        IRewardVault rewardVault = IRewardVault(address(farmingVault));
        vm.expectPartialRevert(IRewardVault.InvalidRewardManager.selector);
        rewardVault.claimReward(user_1, user_1);

        IVault vault = IVault(address(farmingVault));
        vm.expectPartialRevert(IVault.InvalidVaultManager.selector);
        vault.deposit(100, user_1, user_1);
        vm.expectPartialRevert(IVault.InvalidVaultManager.selector);
        vault.deposit(100, user_1);
        vm.expectPartialRevert(IVault.InvalidVaultManager.selector);
        vault.withdraw(100, user_1, user_1);
        vm.expectPartialRevert(IVault.InvalidVaultManager.selector);
        vault.updateConfig(VaultConfig({ maxAsset: 1000 }));
    }

    function test_only_admin_can_call_functions() public {
        FarmingVaultGlobalConfig memory globalConfig = FarmingVaultGlobalConfig({ refundRatio: 1000 });
        VaultConfig memory config = VaultConfig({ maxAsset: 1000 });
        RewardConfig memory rewardConfig =
            RewardConfig({ claimStartTime: 1000, claimEndTime: 1000, rewardRate: 1000, startTime: 1000, endTime: 1000 });

        vm.expectPartialRevert(IFarmingVaultManager.InvalidAdmin.selector);
        manager.setGlobalConfig(globalConfig);

        vm.expectPartialRevert(IFarmingVaultManager.InvalidAdmin.selector);
        manager.updateFarmingVaultConfig(address(farmingVault), config, rewardConfig);

        IVaultManager vaultManager = IVaultManager(address(manager));
        vm.expectPartialRevert(IFarmingVaultManager.InvalidAdmin.selector);
        vaultManager.updateConfig(address(farmingVault), config);

        IRewardManager rewardManager = IRewardManager(address(manager));
        vm.expectPartialRevert(IFarmingVaultManager.InvalidAdmin.selector);
        rewardManager.updateRewardConfig(address(farmingVault), rewardConfig);
    }

    function testFuzz_user_deposit(uint256 amount) public {
        vm.assume(amount <= config.maxAsset);
        vm.assume(amount <= asset.balanceOf(user_1));
        deposit(address(manager), user_1, amount, address(farmingVault), address(asset));
    }

    function testFuzz_users_deposit(uint256 amount0, uint256 amount1, uint256 claimTime) public {
        vm.assume(amount0 <= config.maxAsset);
        vm.assume(amount1 <= config.maxAsset);
        vm.assume(amount0 + amount1 <= config.maxAsset);
        vm.assume(amount0 <= asset.balanceOf(user_1));
        vm.assume(amount1 <= asset.balanceOf(user_2));

        vm.assume(claimTime > block.timestamp);
        vm.assume(claimTime > config.claimStartTime);

        deposit(address(manager), user_1, amount0, address(farmingVault), address(asset));
        deposit(address(manager), user_2, amount1, address(farmingVault), address(asset));

        vm.warp(claimTime);

        uint256 expectedReward = computeReward(address(farmingVault), user_1);
        uint256 actualReward = IRewardVault(address(farmingVault)).previewReward(user_1);
        assertEq(actualReward, expectedReward);

        uint256 expectedReward2 = computeReward(address(farmingVault), user_2);
        uint256 actualReward2 = IRewardVault(address(farmingVault)).previewReward(user_2);
        assertEq(actualReward2, expectedReward2);
    }

    function testFuzz_user_deposit_exceed_max_asset(uint256 amount) public {
        vm.assume(amount > config.maxAsset);
        vm.assume(amount <= asset.balanceOf(user_1));
        vm.startPrank(user_1);
        asset.approve(address(manager), amount);
        vm.expectPartialRevert(IVault.MaxAssetExceeded.selector);
        IVaultManager(address(manager)).deposit(amount, address(farmingVault), user_1);
        vm.stopPrank();
    }

    function testFuzz_user_withdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        vm.assume(depositAmount <= config.maxAsset);
        vm.assume(withdrawAmount <= depositAmount);
        vm.assume(withdrawAmount < asset.balanceOf(user_1));
        deposit(address(manager), user_1, depositAmount, address(farmingVault), address(asset));
        withdraw(address(manager), user_1, withdrawAmount, address(farmingVault), address(asset));
    }

    function testFuzz_user_claim_reward(uint256 amount, uint256 claimTime) public {
        vm.assume(amount <= config.maxAsset);
        vm.assume(amount <= asset.balanceOf(user_1));
        vm.assume(claimTime > block.timestamp);
        vm.assume(claimTime > config.claimStartTime);

        deposit(address(manager), user_1, amount, address(farmingVault), address(asset));

        vm.warp(claimTime);

        uint256 expectedReward = computeReward(address(farmingVault), user_1);
        uint256 actualReward = IRewardVault(address(farmingVault)).previewReward(user_1);
        assertEq(actualReward, expectedReward);

        claimReward(address(manager), user_1, address(farmingVault), address(gold));
    }

    function testFuzz_user_claim_reward_before_claim_start_time(uint256 amount, uint256 claimTime) public {
        vm.assume(amount <= config.maxAsset);
        vm.assume(amount <= asset.balanceOf(user_1));

        vm.assume(claimTime > block.timestamp);
        vm.assume(claimTime < config.claimStartTime);

        deposit(address(manager), user_1, amount, address(farmingVault), address(asset));

        vm.warp(claimTime);

        vm.startPrank(user_1);
        vm.expectPartialRevert(ITimeBasedRewardVault.ClaimNotStarted.selector);
        IRewardManager(address(manager)).claimReward(address(farmingVault), user_1);
        vm.stopPrank();
    }

    function testFuzz_user_claim_and_stake(uint256 depoistAmount, uint256 stakeAmount, uint256 claimTime) public {
        vm.assume(depoistAmount <= config.maxAsset);
        vm.assume(depoistAmount <= asset.balanceOf(user_1));

        vm.assume(claimTime > block.timestamp);
        vm.assume(claimTime < config.claimStartTime);

        deposit(address(manager), user_1, depoistAmount, address(farmingVault), address(asset));

        vm.warp(claimTime);

        uint256 rewardAmount = IRewardVault(address(farmingVault)).previewReward(user_1);

        vm.assume(stakeAmount <= rewardAmount);

        claimAndStake(address(manager), user_1, address(farmingVault), address(gold), stakeAmount);
    }
}
