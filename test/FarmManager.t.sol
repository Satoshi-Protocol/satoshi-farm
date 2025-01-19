// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IFarm } from "../src/interfaces/IFarm.sol";
import { DstInfo, IFarmManager, LzConfig, WhitelistConfig } from "../src/interfaces/IFarmManager.sol";
import { BaseTest } from "./utils/BaseTest.sol";
import { DeployBase } from "./utils/DeployBase.sol";
import { DEPLOYER, OWNER, TestConfig } from "./utils/TestConfig.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FarmManagerTest is BaseTest {
    IFarm farm;
    IERC20 asset;

    function setUp() public override {
        super.setUp();
        _deploySetUp();
        asset = _deployMockUnderlyingAsset(DEPLOYER);
        farm = _createFarm(DEPLOYER, asset, DEFAULT_FARM_CONFIG);
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
        // deposit asset, reward rate is 1000

        // after 1 days, update reward rate to 2000

        // after 2 days, check the reward is correct
    }
}
