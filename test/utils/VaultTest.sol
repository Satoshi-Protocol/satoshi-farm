// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { ConfigBase } from "./ConfigBase.sol";
import { Deployers } from "./Deployers.sol";
import { TestBase } from "./TestBase.sol";
import { Config } from "./Types.sol";

import { RewardConfig } from "../../src/interfaces/ITimeBasedRewardVault.sol";
import { VaultConfig } from "../../src/interfaces/IVault.sol";
import { VaultTestBase } from "./VaultTestBase.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract VaultTest is Deployers, ConfigBase, VaultTestBase {
    function setUp() public {
        vm.startPrank(admin);
        asset = deployToken("Asset", "ASSET", config.assetDecimals);
        gold = deployGold();
        manager = deployFarmingVaultManager(gold, config.refundRatio);

        RewardConfig memory rewardConfig = RewardConfig({
            startTime: config.startTime,
            endTime: config.endTime,
            rewardRate: config.rewardRate,
            claimStartTime: config.claimStartTime,
            claimEndTime: config.claimEndTime
        });
        VaultConfig memory vaultConfig = VaultConfig({ maxAsset: config.maxAsset });

        goldFarmingVault = createGoldFarmingVault(gold);
        setupFarmingVault(address(goldFarmingVault), rewardConfig, vaultConfig);
        farmingVault = createFarmingVault(asset, gold, address(goldFarmingVault));
        setupFarmingVault(address(farmingVault), rewardConfig, vaultConfig);
        gold.setAuthorized(address(manager), true);
        deal(address(asset), user_1, 1e5 * 10 ** config.assetDecimals);
        deal(address(asset), user_2, 1e5 * 10 ** config.assetDecimals);
        deal(address(gold), user_1, 1e5 * 10 ** 18);
        deal(address(gold), user_2, 1e5 * 10 ** 18);
        vm.stopPrank();
        vm.warp(200);
    }
}
