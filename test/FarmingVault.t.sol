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
import { FarmingVaultDeployers } from "./utils/FarmingVaultDeployers.sol";
import { TestBase } from "./utils/TestBase.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FarmingVaultTest is TestBase, FarmingVaultDeployers {
    struct Config {
        // vault config
        uint256 startTime;
        uint256 endTime;
        uint256 rewardRate;
        uint256 claimStartTime;
        uint256 maxAsset;
        // asset config
        uint8 assetDecimals;
        // farming vault manager config
        uint256 refundRatio;
    }

    Config public config;

    function setUp() public {
        config = defaultConfig();
        vm.startPrank(admin);
        asset = deployToken("Asset", "ASSET", config.assetDecimals);
        gold = deployGold();
        manager = deployFarmingVaultManager(gold, config.refundRatio);
        goldFarmingVault = createGoldFarmingVault(gold);
        setupFarmingVault(address(goldFarmingVault), config.rewardRate, config.claimStartTime, config.maxAsset);
        farmingVault = createFarmingVault(asset, gold, address(goldFarmingVault));
        setupFarmingVault(address(farmingVault), config.rewardRate, config.claimStartTime, config.maxAsset);
        gold.setAuthorized(address(manager), true);
        deal(address(asset), user_1, 1e5 * 10 ** config.assetDecimals);
        deal(address(asset), user_2, 1e5 * 10 ** config.assetDecimals);
        deal(address(gold), user_1, 1e5 * 10 ** 18);
        deal(address(gold), user_2, 1e5 * 10 ** 18);
        vm.stopPrank();
        vm.warp(200);
    }

    function test_user_deposit() public {
        uint256 amount = 100;
        uint256 balanceBefore = asset.balanceOf(user_1);
        vm.startPrank(user_1);
        asset.approve(address(manager), amount);
        uint256 shares = IVaultManager(address(manager)).deposit(amount, address(farmingVault), user_1);
        vm.stopPrank();
        assertEq(shares, amount);
        checkBalance(asset, user_1, balanceBefore - amount);
        checkBalance(asset, address(farmingVault), amount);
    }

    function test_user_claim_reward() public {
        uint256 amount = 100;
        uint256 depositTime = block.timestamp;
        uint256 secondsPassed = config.claimStartTime - depositTime + 1;

        vm.startPrank(user_1);
        asset.approve(address(manager), amount);
        IVaultManager(address(manager)).deposit(amount, address(farmingVault), user_1);
        vm.stopPrank();

        vm.warp(depositTime + secondsPassed);

        ITimeBasedRewardVault timeBasedRewardVault = ITimeBasedRewardVault(address(farmingVault));
        uint256 lastRewardPerToken = timeBasedRewardVault.getLastRewardPerToken();
        uint256 totalShares = timeBasedRewardVault.totalShares();
        uint256 lastUpdateTime = timeBasedRewardVault.getLastUpdateTime();
        uint256 pendingReward = IRewardVault(address(farmingVault)).getPendingReward(user_1);
        uint256 interval =
            RewardVaultMath.computeInterval(block.timestamp, lastUpdateTime, config.startTime, config.endTime);
        uint256 latestRewardPerToken = RewardVaultMath.computeRewardPerToken(config.rewardRate, interval, totalShares);
        uint256 expectedReward =
            pendingReward + RewardVaultMath.computeReward(amount, latestRewardPerToken, lastRewardPerToken);
        uint256 actualReward = IRewardVault(address(farmingVault)).previewReward(user_1);

        assertEq(actualReward, expectedReward);

        uint256 balanceBefore = gold.balanceOf(user_1);
        vm.startPrank(user_1);
        IRewardManager(address(manager)).claimReward(address(farmingVault), user_1, user_1);
        vm.stopPrank();
        // checkBalance(gold, user_1, balanceBefore);
    }

    function test_user_withdraw() public {
        uint256 amount = 100;
        uint256 balanceBefore = asset.balanceOf(user_1);
        vm.startPrank(user_1);
        asset.approve(address(manager), amount);
        IVaultManager(address(manager)).deposit(amount, address(farmingVault), user_1);
        uint256 pendingReward = IRewardVault(address(farmingVault)).getPendingReward(user_1);
        assertEq(pendingReward, 0);
        vm.warp(400);
        uint256 shares = IVaultManager(address(manager)).withdraw(amount, address(farmingVault), user_1, user_1);
        vm.stopPrank();
        assertEq(shares, amount);
        // checkBalance(asset, user_1, balanceBefore);
        // checkBalance(gold, address(farmingVault), 0);
    }

    function test_user_deposit_exceed_max_asset() public {
        uint256 amount = 1e20 + 1;
        vm.startPrank(user_1);
        asset.approve(address(manager), amount);
        vm.expectPartialRevert(IVault.MaxAssetExceeded.selector);
        IVaultManager(address(manager)).deposit(amount, address(farmingVault), user_1);
        vm.stopPrank();
    }

    function test_user_claim_reward_before_claim_start_time() public {
        uint256 amount = 100;
        uint256 claimTime = block.timestamp + 100;
        assertEq(claimTime < config.claimStartTime, true);
        vm.startPrank(user_1);
        asset.approve(address(manager), amount);
        IVaultManager(address(manager)).deposit(amount, address(farmingVault), user_1);
        vm.warp(claimTime);
        vm.expectPartialRevert(ITimeBasedRewardVault.ClaimNotStarted.selector);
        IRewardManager(address(manager)).claimReward(address(farmingVault), user_1, user_1);
        vm.stopPrank();
    }

    function test_user_claim_and_stake() public {
        uint256 amount = 100;
        uint256 depositTime = block.timestamp;
        uint256 secondsPassed = config.claimStartTime - depositTime - 1;

        vm.startPrank(user_1);
        asset.approve(address(manager), amount);
        IVaultManager(address(manager)).deposit(amount, address(farmingVault), user_1);
        vm.stopPrank();

        vm.warp(depositTime + secondsPassed);

        vm.startPrank(user_1);
        manager.claimAndStake(address(farmingVault), user_1, user_1, amount);
        vm.stopPrank();
    }

    function defaultConfig() public pure returns (Config memory) {
        return Config({
            startTime: 100,
            endTime: 1000,
            rewardRate: 1e10,
            claimStartTime: 500,
            maxAsset: 1e20,
            assetDecimals: 18,
            refundRatio: 50 * 1_000_000 / 100
        });
    }
}
