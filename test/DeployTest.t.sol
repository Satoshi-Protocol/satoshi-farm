// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { DeployBase } from "./utils/DeployBase.sol";

import { DEPLOYER, OWNER } from "./utils/TestConfig.sol";
import { Test, console } from "forge-std/Test.sol";

import { FarmConfig, IFarm } from "../src/core/interfaces/IFarm.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOwnable {
    function owner() external view returns (address);
}

contract DeployTest is Test, DeployBase {
    function setUp() public override {
        super.setUp();
    }

    function test_deploy_setup() public {
        _deploySetUp();
        assert(address(farmImpl) != address(0));
        assert(address(farmManagerImpl) != address(0));
        assert(address(farmBeacon) != address(0));
        assert(address(rewardToken) != address(0));
        assert(address(farmManager) != address(0));
        assert(address(rewardFarm) != address(0));

        IERC20 asset = _deployMockUnderlyingAsset(DEPLOYER);

        IFarm farm = _createFarm(DEPLOYER, asset, DEFAULT_FARM_CONFIG);

        // check the farm config
        FarmConfig memory config = farm.getFarmConfig();

        assertEq(config.depositCap, DEFAULT_FARM_CONFIG.depositCap);
        assertEq(config.depositCapPerUser, DEFAULT_FARM_CONFIG.depositCapPerUser);
        assertEq(config.rewardRate, DEFAULT_FARM_CONFIG.rewardRate);
        assertEq(config.depositStartTime, DEFAULT_FARM_CONFIG.depositStartTime);
        assertEq(config.depositEndTime, DEFAULT_FARM_CONFIG.depositEndTime);
        assertEq(config.rewardStartTime, DEFAULT_FARM_CONFIG.rewardStartTime);
        assertEq(config.rewardEndTime, DEFAULT_FARM_CONFIG.rewardEndTime);
        assertEq(config.claimStartTime, DEFAULT_FARM_CONFIG.claimStartTime);
        assertEq(config.claimEndTime, DEFAULT_FARM_CONFIG.claimEndTime);
        assertEq(config.claimDelayTime, DEFAULT_FARM_CONFIG.claimDelayTime);
        assertEq(config.withdrawFee, DEFAULT_FARM_CONFIG.withdrawFee);
        assertEq(config.withdrawEnabled, DEFAULT_FARM_CONFIG.withdrawEnabled);
        assertEq(config.forceClaimEnabled, DEFAULT_FARM_CONFIG.forceClaimEnabled);

        assertEq(address(asset), address(farm.underlyingAsset()));
        assertEq(address(farmManager), address(farm.farmManager()));
        assertEq(farm.totalShares(), 0);
        assertEq(farm.lastRewardPerToken(), 0);
        assertEq(farm.lastUpdateTime(), 0);

        // check the owner
        assertEq(IOwnable(address(farmManager)).owner(), DEPLOYER);
    }
}
