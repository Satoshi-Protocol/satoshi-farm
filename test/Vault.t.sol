// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { IRewardManager } from "../src/interfaces/IRewardManager.sol";

import { ITimeBasedRewardVault } from "../src/interfaces/ITimeBasedRewardVault.sol";
import { IVault } from "../src/interfaces/IVault.sol";

import { RewardVaultMath } from "../src/libraries/RewardVaultMath.sol";
import { Deployers } from "./utils/Deployers.sol";

import { TestBase } from "./utils/TestBase.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VaultTest is TestBase, Deployers {
    struct Config {
        // vault config
        uint256 startTime;
        uint256 endTime;
        uint256 rewardRate;
        // asset config
        uint8 assetDecimals;
    }

    Config public config;

    function setUp() public {
        config = defaultConfig();
        vm.startPrank(admin);
        asset = deployToken("Asset", "ASSET", config.assetDecimals);
        gold = deployGold();
        vaultManager = deployVaultManager(gold);
        createVault(asset, gold);
        setupRewardVault(config.rewardRate);
        gold.setAuthorized(address(vaultManager), true);
        deal(address(asset), user_1, 1e5 * 10 ** config.assetDecimals);
        deal(address(asset), user_2, 1e5 * 10 ** config.assetDecimals);
        vm.stopPrank();
        vm.warp(200);
    }

    function test_user_deposit() public {
        uint256 amount = 100;
        uint256 balanceBefore = asset.balanceOf(user_1);
        vm.startPrank(user_1);
        asset.approve(address(vaultManager), amount);
        uint256 shares = vaultManager.deposit(amount, address(vault), user_1);
        vm.stopPrank();
        assertEq(shares, amount);
        checkBalance(asset, user_1, balanceBefore - amount);
        checkBalance(asset, address(vault), amount);
    }

    function test_user_claim_reward() public {
        uint256 amount = 100;
        uint256 depositTime = block.timestamp;
        uint256 secondsPassed = 100;

        vm.startPrank(user_1);
        asset.approve(address(vaultManager), amount);
        vaultManager.deposit(amount, address(vault), user_1);
        vm.stopPrank();

        vm.startPrank(user_2);
        asset.approve(address(vaultManager), amount);
        vaultManager.deposit(amount, address(vault), user_2);
        vm.stopPrank();

        vm.warp(depositTime + secondsPassed);

        ITimeBasedRewardVault timeBasedRewardVault = ITimeBasedRewardVault(address(vault));
        uint256 lastRewardPerToken = timeBasedRewardVault.getLastRewardPerToken();
        uint256 totalShares = timeBasedRewardVault.totalShares();
        uint256 lastUpdateTime = timeBasedRewardVault.getLastUpdateTime();
        uint256 pendingReward = vault.getPendingReward(user_1);

        uint256 interval =
            RewardVaultMath.computeInterval(block.timestamp, lastUpdateTime, config.startTime, config.endTime);
        uint256 latestRewardPerToken = RewardVaultMath.computeRewardPerToken(1e10, interval, totalShares);
        uint256 expectedReward =
            pendingReward + RewardVaultMath.computeReward(amount, latestRewardPerToken, lastRewardPerToken);
        uint256 actualReward = vault.previewReward(user_1);

        assertEq(actualReward, expectedReward);

        checkBalance(gold, user_1, 0);
        vm.startPrank(user_1);
        vault.claimReward(user_1, user_1);
        vm.stopPrank();
        checkBalance(gold, user_1, expectedReward);
    }

    function test_user_withdraw() public {
        uint256 amount = 100;
        uint256 balanceBefore = asset.balanceOf(user_1);
        vm.startPrank(user_1);
        asset.approve(address(vaultManager), amount);
        vaultManager.deposit(amount, address(vault), user_1);
        uint256 pendingReward = vault.getPendingReward(user_1);
        assertEq(pendingReward, 0);
        vm.warp(400);
        uint256 shares = vaultManager.withdraw(amount, address(vault), user_1, user_1);
        vm.stopPrank();
        assertEq(shares, amount);
        checkBalance(asset, user_1, balanceBefore);
        checkBalance(asset, address(vault), 0);
    }

    function defaultConfig() public pure returns (Config memory) {
        return Config({ startTime: 100, endTime: 400, rewardRate: 1e10, assetDecimals: 18 });
    }
}
