// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IFarm } from "../src/core/interfaces/IFarm.sol";
import { DstInfo, IFarmManager, LzConfig, WhitelistConfig } from "../src/core/interfaces/IFarmManager.sol";
import { BaseTest } from "./utils/BaseTest.sol";
import { DeployBase } from "./utils/DeployBase.sol";
import { DEPLOYER, OWNER, TestConfig } from "./utils/TestConfig.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

contract FarmManagerTest is BaseTest {
    IFarm farm;
    IERC20 asset;

    address payable user1;
    address payable user2;
    address payable user3;

    function setUp() public override {
        super.setUp();
        _deploySetUp();
        asset = _deployMockUnderlyingAsset(DEPLOYER);
        farm = _createFarm(DEPLOYER, asset, DEFAULT_FARM_CONFIG);

        user1 = _createUser("user1");
        user2 = _createUser("user2");
        user3 = _createUser("user3");
    }

    function test_pause() public {
        vm.startPrank(DEPLOYER);
        farmManager.pause();
        assertEq(farmManager.paused(), true);

        farmManager.resume();
        assertEq(farmManager.paused(), false);
        vm.stopPrank();
    }

    function test_OwnableUnauthorizedAccount() public {
        vm.startPrank(address(1));

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(1)));
        farmManager.pause();

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(1)));
        farmManager.resume();

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(1)));
        LzConfig memory lzConfig = LzConfig({ eid: 0, endpoint: address(0), refundAddress: address(0) });
        farmManager.updateLzConfig(lzConfig);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(1)));
        DstInfo memory dstInfo =
            DstInfo({ dstEid: 0, dstRewardFarm: IFarm(address(0)), dstRewardManagerBytes32: bytes32(0) });
        farmManager.updateDstInfo(dstInfo);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(1)));
        farmManager.updateRewardRate(farm, 0);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(1)));
        WhitelistConfig memory whitelistConfig = WhitelistConfig({ enabled: false, merkleRoot: bytes32(0) });
        farmManager.updateWhitelistConfig(farm, whitelistConfig);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(1)));
        farmManager.updateFarmConfig(farm, DEFAULT_FARM_CONFIG);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(1)));
        farmManager.createFarm(asset, DEFAULT_FARM_CONFIG);
    }

    function test_updateRewardRate() public {
        vm.warp(block.timestamp + 30 days);
        // deposit asset, reward rate is 1000
        deal(address(asset), user1, 100e18);
        depositERC20(user1, farm, 1e18, user1);
        assertEq(farmManager.shares(farm, user1), 1e18, "Share is not correct");

        // after 1 days, update reward rate to 2000
        vm.warp(block.timestamp + 1 days);
        uint256 expectedReward = 1000 * 1 days;
        assertEq(farmManager.previewReward(farm, user1), expectedReward, "Reward is not correct");
        vm.startPrank(DEPLOYER);
        farmManager.updateRewardRate(farm, 2000);
        vm.stopPrank();

        // after 2 days, check the reward is correct
        vm.warp(block.timestamp + 2 days);
        expectedReward = 1000 * 1 days + 2000 * 2 days;
        assertEq(farmManager.previewReward(farm, user1), expectedReward);

        // update reward rate to 3000
        vm.startPrank(DEPLOYER);
        farmManager.updateRewardRate(farm, 3000);
        vm.stopPrank();

        // after 3 days, check the reward is correct
        vm.warp(block.timestamp + 3 days);
        expectedReward = 1000 * 1 days + 2000 * 2 days + 3000 * 3 days;
        assertEq(farmManager.previewReward(farm, user1), expectedReward);

        // update reward rate to 0
        vm.startPrank(DEPLOYER);
        farmManager.updateRewardRate(farm, 0);
        vm.stopPrank();

        // after 4 days, check the reward is correct
        vm.warp(block.timestamp + 4 days);
        assertEq(farmManager.previewReward(farm, user1), expectedReward);
    }
}
