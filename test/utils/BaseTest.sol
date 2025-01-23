// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { FarmConfig } from "../../src/core/interfaces/IFarm.sol";
import { DEFAULT_NATIVE_ASSET_ADDRESS, IFarm } from "../../src/core/interfaces/IFarm.sol";
import {
    ClaimAndStakeParams,
    DepositParams,
    ExecuteClaimParams,
    IFarmManager,
    InstantClaimParams,
    RequestClaimParams,
    StakePendingClaimParams,
    WithdrawParams
} from "../../src/core/interfaces/IFarmManager.sol";
import { DeployBase } from "./DeployBase.sol";

import { IRewardToken } from "../../src/core/interfaces/IRewardToken.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Test } from "forge-std/Test.sol";
import "forge-std/console2.sol";

abstract contract BaseTest is DeployBase {
    function depositERC20(address user, IFarm farm, uint256 amount, address receiver) public {
        vm.startPrank(user);

        farm.underlyingAsset().approve(address(farmManager), amount);

        vm.expectEmit(true, true, true, true);
        emit IFarmManager.Deposit(farm, amount, user, receiver);

        farmManager.depositERC20(DepositParams({ farm: farm, amount: amount, receiver: receiver }));

        vm.stopPrank();
    }

    function depositNativeAsset(address user, IFarm farm, uint256 amount, address receiver) public {
        vm.startPrank(user);

        vm.expectEmit(true, true, true, true);
        emit IFarmManager.Deposit(farm, amount, user, receiver);

        farmManager.depositNativeAsset{ value: amount }(
            DepositParams({ farm: farm, amount: amount, receiver: receiver })
        );

        vm.stopPrank();
    }

    function withdraw(address user, IFarm farm, uint256 amount, address receiver) public {
        vm.startPrank(user);

        // Expect Withdraw event
        vm.expectEmit(true, true, true, true);
        emit IFarmManager.Withdraw(farm, amount, user, receiver);

        farmManager.withdraw(WithdrawParams({ farm: farm, amount: amount, receiver: receiver }));

        vm.stopPrank();
    }

    function requestClaim(address user, IFarm farm, address receiver) public returns (uint256, uint256, bytes32) {
        vm.startPrank(user);
        uint256 claimAmt = farm.previewReward(user);
        (uint256 claimableTime, bytes32 claimId) = _prepareClaimId(farm, claimAmt, user, receiver, block.timestamp);

        vm.expectEmit(true, true, true, true);
        emit IFarmManager.ClaimRequested(farm, claimAmt, user, receiver, claimableTime, claimId);
        farmManager.requestClaim(RequestClaimParams({ farm: farm, amount: claimAmt, receiver: receiver }));

        vm.stopPrank();

        return (claimAmt, claimableTime, claimId);
    }

    function executeClaim(
        address user,
        IFarm farm,
        uint256 amount,
        address receiver,
        uint256 claimableTime,
        bytes32 claimId
    )
        public
    {
        vm.startPrank(user);

        vm.expectEmit(true, true, true, true);
        emit IFarmManager.ClaimExecuted(farm, amount, user, receiver, claimableTime, claimId);

        farmManager.executeClaim(
            ExecuteClaimParams({
                farm: farm,
                amount: amount,
                owner: user,
                receiver: user,
                claimableTime: claimableTime,
                claimId: claimId
            })
        );

        vm.stopPrank();
    }

    function stakePendingClaim(address user, StakePendingClaimParams memory stakePendingClaimParams) public {
        vm.startPrank(user);

        farmManager.stakePendingClaim(stakePendingClaimParams);

        vm.stopPrank();
    }

    function claimAndStake(address user, ClaimAndStakeParams memory claimAndStakeParams) public {
        vm.startPrank(user);

        farmManager.claimAndStake(claimAndStakeParams);

        vm.stopPrank();
    }

    function instantClaim(address user, InstantClaimParams memory instantClaimParams) public {
        vm.startPrank(user);
        farmManager.instantClaim(instantClaimParams);
        vm.stopPrank();
    }

    function _prepareClaimId(
        IFarm farm,
        uint256 amount,
        address owner,
        address receiver,
        uint256 currentTime
    )
        internal
        view
        returns (uint256, bytes32)
    {
        (,,,,,,,,, uint256 claimDelayTime,,) = farm.farmConfig();
        uint256 claimableTime = currentTime + claimDelayTime;
        return (claimableTime, keccak256(abi.encode(amount, owner, receiver, claimableTime)));
    }

    function _getBalance(IERC20 token, address user) internal view returns (uint256) {
        if (address(token) == address(DEFAULT_NATIVE_ASSET_ADDRESS)) {
            return user.balance;
        }
        return token.balanceOf(user);
    }

    modifier checkBalanceChange(IERC20 token, address user, uint256 amount, bool isIncrease) {
        uint256 initialBalance = _getBalance(token, user);
        _;
        uint256 finalBalance = _getBalance(token, user);
        if (isIncrease) {
            assertEq(finalBalance, initialBalance + amount, "Incorrect balance");
        } else {
            assertEq(finalBalance, initialBalance - amount, "Incorrect balance");
        }
    }

    modifier checkShareChange(IFarm farm, address user, uint256 amount, bool isIncrease) {
        uint256 initialShare = farm.shares(user);
        uint256 initialTotalShares = farm.totalShares();
        _;
        uint256 finalShare = farm.shares(user);
        uint256 finalTotalShares = farm.totalShares();
        if (isIncrease) {
            assertEq(finalShare, initialShare + amount, "Incorrect remaining shares");
            assertEq(finalTotalShares, initialTotalShares + amount, "Incorrect total shares");
        } else {
            assertEq(finalShare, initialShare - amount, "Incorrect remaining shares");
            assertEq(finalTotalShares, initialTotalShares - amount, "Incorrect total shares");
        }
    }
}
