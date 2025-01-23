// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ClaimStatus, IFarm } from "../src/core/interfaces/IFarm.sol";

import { FarmConfig } from "../src/core/interfaces/IFarm.sol";
import {
    ClaimAndStakeParams,
    DepositParams,
    DstInfo,
    ExecuteClaimParams,
    IFarmManager,
    IFarmManager,
    InstantClaimParams,
    LzConfig,
    RequestClaimParams,
    StakePendingClaimParams,
    WhitelistConfig,
    WithdrawParams
} from "../src/core/interfaces/IFarmManager.sol";
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

        vm.label(address(farm), "Farm");
        vm.label(address(asset), "Asset");

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

    function test_previewRewardAmountCorrect() public {
        deal(address(asset), user1, 100e18);
        deal(address(asset), user2, 100e18);
        deal(address(asset), user3, 100e18);

        uint256 amount = 1e18;

        // deposit asset, reward rate is 1000

        depositERC20(user1, farm, amount, user1);
        depositERC20(user2, farm, amount, user2);
        depositERC20(user3, farm, amount, user3);

        FarmConfig memory farmConfig = farmManager.getFarmConfig(farm);

        vm.warp(farmConfig.rewardStartTime + 1 days);

        uint256 expectedReward = 1000 * 1 days / 3;

        assertEq(farmManager.previewReward(farm, user1), expectedReward);
        assertEq(farmManager.previewReward(farm, user2), expectedReward);
        assertEq(farmManager.previewReward(farm, user3), expectedReward);

        vm.warp(farmConfig.rewardEndTime + 100 days);

        uint32 duration = farmConfig.rewardEndTime - farmConfig.rewardStartTime;
        expectedReward = 1000 * duration / 3;

        assertEq(farmManager.previewReward(farm, user1), expectedReward);
        assertEq(farmManager.previewReward(farm, user2), expectedReward);
        assertEq(farmManager.previewReward(farm, user3), expectedReward);
    }

    function test_depositAndRequestClaim() public {
        FarmConfig memory farmConfig = farmManager.getFarmConfig(farm);

        deal(address(asset), user1, 100e18);

        uint256 amount = 1e18;

        // deposit and check the share is correct
        depositERC20(user1, farm, amount, user1);
        assertEq(farmManager.shares(farm, user1), amount, "Share is not correct");

        vm.warp(farmConfig.claimStartTime + 1 days);

        uint256 previewReward = farmManager.previewReward(farm, user1);

        // request claim
        (uint256 claimAmount, uint256 claimableTime, bytes32 claimId) = requestClaim(user1, farm, user1);
        assertEq(claimAmount, previewReward, "Claim amount is not correct");
        assertEq(claimableTime, block.timestamp + farmConfig.claimDelayTime, "Claimable time is not correct");

        // try to claim before the claimable time, should revert
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(IFarm.ClaimIsNotReady.selector, claimableTime, block.timestamp));
        farmManager.executeClaim(
            ExecuteClaimParams({
                farm: farm,
                amount: claimAmount,
                owner: user1,
                receiver: user1,
                claimableTime: claimableTime,
                claimId: claimId
            })
        );
        vm.stopPrank();

        // try to claim other user's reward, should revert
        vm.startPrank(user2);
        vm.expectRevert();
        farmManager.executeClaim(
            ExecuteClaimParams({
                farm: farm,
                amount: claimAmount,
                owner: user1,
                receiver: user1,
                claimableTime: claimableTime,
                claimId: claimId
            })
        );
        vm.stopPrank();

        // claim at the claimable time
        vm.warp(claimableTime);
        executeClaim(user1, farm, claimAmount, user1, claimableTime, claimId);
        // check the claim balance is correct
        assertEq(rewardToken.balanceOf(user1), claimAmount, "Claim balance is not correct");

        // try to execute the claim again, should revert
        vm.startPrank(user1);
        vm.expectRevert(IFarm.AlreadyClaimed.selector);
        farmManager.executeClaim(
            ExecuteClaimParams({
                farm: farm,
                amount: claimAmount,
                owner: user1,
                receiver: user1,
                claimableTime: claimableTime,
                claimId: claimId
            })
        );
        vm.stopPrank();
    }

    function test_depositCap() public {
        FarmConfig memory farmConfig = farmManager.getFarmConfig(farm);
        uint256 depositCap = farmConfig.depositCap;
        uint256 depositCapPerUser = farmConfig.depositCapPerUser;

        deal(address(asset), user1, depositCap + 1e18);
        deal(address(asset), user2, depositCap + 1e18);
        deal(address(asset), user3, depositCap + 1e18);

        // check deposit exceed user deposit cap
        vm.startPrank(user1);
        asset.approve(address(farmManager), depositCap);
        vm.expectRevert(abi.encodeWithSelector(IFarm.DepositCapPerUserExceeded.selector, depositCap, depositCapPerUser));
        farmManager.depositERC20(DepositParams({ farm: farm, amount: depositCap, receiver: user1 }));
        vm.stopPrank();

        // user1 and user2 deposit asset, reach the farm deposit cap
        depositERC20(user1, farm, depositCapPerUser, user1);
        depositERC20(user2, farm, depositCapPerUser, user2);

        // check deposit exceed farm deposit cap
        vm.startPrank(user3);
        asset.approve(address(farmManager), depositCapPerUser);
        vm.expectRevert(abi.encodeWithSelector(IFarm.DepositCapExceeded.selector, depositCapPerUser, depositCap));
        farmManager.depositERC20(DepositParams({ farm: farm, amount: depositCapPerUser, receiver: user3 }));
        vm.stopPrank();
    }

    function test_claimTime() public {
        FarmConfig memory farmConfig = farmManager.getFarmConfig(farm);

        deal(address(asset), user1, 100e18);

        uint256 amount = 1e18;

        depositERC20(user1, farm, amount, user1);

        // claim at invalid time
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(IFarm.InvalidClaimTime.selector, block.timestamp));
        farmManager.requestClaim(RequestClaimParams({ farm: farm, amount: amount, receiver: user1 }));
        vm.stopPrank();

        vm.warp(farmConfig.claimStartTime);

        // no pending rewards, request claim should revert
        vm.expectRevert(IFarm.ZeroPendingRewards.selector);
        farmManager.requestClaim(RequestClaimParams({ farm: farm, amount: amount, receiver: user1 }));

        vm.warp(farmConfig.claimEndTime + 1 days);
        // claim at invalid time
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(IFarm.InvalidClaimTime.selector, block.timestamp));
        farmManager.requestClaim(RequestClaimParams({ farm: farm, amount: amount, receiver: user1 }));
        vm.stopPrank();

        // claim at valid time
        vm.warp(farmConfig.claimStartTime + 1 days);
        requestClaim(user1, farm, user1);
    }

    function test_claimAndStake() public {
        FarmConfig memory farmConfig = farmManager.getFarmConfig(farm);

        deal(address(asset), user1, 100e18);

        uint256 amount = 1e18;

        // deposit and check the share is correct
        depositERC20(user1, farm, amount, user1);

        vm.warp(farmConfig.claimStartTime + 3 days);

        uint256 pendingReward = farmManager.previewReward(farm, user1);

        vm.startPrank(user1);
        uint256 claimAmt = 10_000;
        ClaimAndStakeParams memory claimAndStakeParams =
            ClaimAndStakeParams({ farm: farm, amount: claimAmt, receiver: user1 });
        farmManager.claimAndStake(claimAndStakeParams);

        // check the shares in reward farm is correct
        assertEq(farmManager.shares(rewardFarm, user1), claimAmt, "Share is not correct");

        assertEq(farmManager.previewReward(farm, user1), pendingReward - claimAmt, "Preview reward is not correct");
        vm.stopPrank();
    }

    function test_stakePendingClaim() public {
        FarmConfig memory farmConfig = farmManager.getFarmConfig(farm);

        deal(address(asset), user1, 100e18);

        uint256 amount = 1e18;

        // deposit and check the share is correct
        depositERC20(user1, farm, amount, user1);

        vm.warp(farmConfig.claimStartTime + 3 days);

        uint256 pendingReward = farmManager.previewReward(farm, user1);

        // request claim
        (uint256 claimAmount, uint256 claimableTime, bytes32 claimId) = requestClaim(user1, farm, user1);

        assertEq(claimAmount, pendingReward, "Claim amount is not correct");

        StakePendingClaimParams memory stakePendingClaimParams = StakePendingClaimParams({
            farm: farm,
            amount: claimAmount,
            receiver: user1,
            claimableTime: claimableTime,
            claimId: claimId
        });
        stakePendingClaim(user1, stakePendingClaimParams);

        // check the shares in reward farm is correct
        assertEq(farmManager.shares(rewardFarm, user1), claimAmount, "Share is not correct");

        assertEq(farmManager.previewReward(farm, user1), 0, "Preview reward is not correct");

        ClaimStatus claimStatus = farm.getClaimStatus(claimId);

        // cannot stake twice
        vm.expectRevert(abi.encodeWithSelector(IFarm.InvalidStatusToForceExecuteClaim.selector, claimStatus));
        stakePendingClaim(user1, stakePendingClaimParams);

        // check the claimId status
        assert(claimStatus == ClaimStatus.CLAIMED);
    }

    function test_instantClaim() public {
        FarmConfig memory farmConfig = farmManager.getFarmConfig(farm);

        deal(address(asset), user1, 100e18);

        uint256 amount = 1e18;

        // deposit and check the share is correct
        depositERC20(user1, farm, amount, user1);

        uint256 previewReward = farmManager.previewReward(farm, user1);

        vm.warp(farmConfig.claimStartTime + 3 days);

        // try instant claim, should revert
        InstantClaimParams memory instantClaimParams =
            InstantClaimParams({ farm: farm, amount: previewReward, receiver: user1 });
        vm.expectRevert(IFarm.DelayTimeIsNotZero.selector);
        instantClaim(user1, instantClaimParams);

        // set the delay time to 0
        vm.startPrank(DEPLOYER);
        farmConfig = FarmConfig({
            depositCap: 2000e18,
            depositCapPerUser: 1000e18,
            rewardRate: 1000,
            depositStartTime: uint32(block.timestamp),
            depositEndTime: uint32(block.timestamp + 60 days),
            rewardStartTime: uint32(block.timestamp),
            rewardEndTime: uint32(block.timestamp + 40 days),
            claimStartTime: uint32(block.timestamp),
            claimEndTime: uint32(block.timestamp + 60 days),
            claimDelayTime: 0,
            withdrawEnabled: true,
            forceClaimEnabled: true
        });
        farmManager.updateFarmConfig(farm, farmConfig);
        vm.stopPrank();

        // instant claim
        instantClaim(user1, instantClaimParams);

        // check the balance
        assertEq(rewardToken.balanceOf(user1), previewReward, "Reward amount is not match");

        // claim twice, claim 0 token
        instantClaim(user1, instantClaimParams);
        assertEq(rewardToken.balanceOf(user1), previewReward, "Reward amount is not match");
    }

    function test_withdraw() public {
        FarmConfig memory farmConfig = farmManager.getFarmConfig(farm);

        deal(address(asset), user1, 100e18);
        deal(address(asset), user2, 100e18);

        uint256 amount = 2e18;
        uint256 withdrawAmount = 1e18;

        // deposit and check the share is correct
        depositERC20(user1, farm, amount, user1);

        vm.warp(farmConfig.claimStartTime + 1 days);

        // withdraw
        withdraw(user1, farm, withdrawAmount, user1);
        assertEq(asset.balanceOf(user1), 100e18 - amount + withdrawAmount, "Reward amount is not match");

        uint256 pendingReward = farmManager.previewReward(farm, user1);
        uint256 expectedReward = farmConfig.rewardRate * 1 days;
        assertEq(pendingReward, expectedReward, "Pending reward is not correct");

        // user2 deposits asset
        depositERC20(user2, farm, amount, user2);

        vm.warp(block.timestamp + 1 days);

        pendingReward = farmManager.previewReward(farm, user1);
        expectedReward = farmConfig.rewardRate * 1 days + farmConfig.rewardRate * 1 days / 3;
        assertEq(pendingReward, expectedReward, "Pending reward is not correct");

        // withdraw amount exceeds the shares
        uint256 shares = farmManager.shares(farm, user1);
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(IFarm.AmountExceedsShares.selector, amount, shares));
        farmManager.withdraw(WithdrawParams({ farm: farm, amount: amount, receiver: user1 }));
        vm.stopPrank();
    }
}
