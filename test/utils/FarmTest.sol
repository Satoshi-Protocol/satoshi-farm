// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { FarmConfig } from "../../src/core/interfaces/IFarm.sol";

import { DEFAULT_NATIVE_ASSET_ADDRESS, IFarm } from "../../src/core/interfaces/IFarm.sol";
import {
    DepositParams,
    DepositWithProofParams,
    ExecuteClaimParams,
    IFarmManager,
    RequestClaimParams,
    WithdrawParams
} from "../../src/core/interfaces/IFarmManager.sol";

import { MerkleLib } from "./MerkleLib.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Test } from "forge-std/Test.sol";

contract FarmTest is Test {
    IFarmManager public farmManager;
    IERC20 public reward;

    constructor(IFarmManager _farmManager) {
        farmManager = _farmManager;
        reward = farmManager.rewardToken();
    }

    function depositERC20(
        address user,
        DepositParams memory params
    )
        public
        checkBalanceChange(
            CheckBalanceChangeParams({
                token: params.farm.underlyingAsset(),
                user: user,
                amount: params.amount,
                isIncrease: false
            })
        )
        checkBalanceChange(
            CheckBalanceChangeParams({
                token: params.farm.underlyingAsset(),
                user: address(params.farm),
                amount: params.amount,
                isIncrease: true
            })
        )
        checkShareChange(CheckShareChangeParams({ farm: params.farm, user: user, amount: params.amount, isIncrease: true }))
    {
        vm.startPrank(user);

        params.farm.underlyingAsset().approve(address(farmManager), params.amount);

        vm.expectEmit(true, true, true, true);
        emit IFarmManager.Deposit(params.farm, params.amount, user, params.receiver);

        farmManager.depositERC20(params);

        vm.stopPrank();
    }

    function depositERC20WithProof(
        address user,
        DepositWithProofParams memory params
    )
        public
        checkBalanceChange(
            CheckBalanceChangeParams({
                token: params.farm.underlyingAsset(),
                user: user,
                amount: params.amount,
                isIncrease: false
            })
        )
        checkBalanceChange(
            CheckBalanceChangeParams({
                token: params.farm.underlyingAsset(),
                user: address(params.farm),
                amount: params.amount,
                isIncrease: true
            })
        )
        checkShareChange(CheckShareChangeParams({ farm: params.farm, user: user, amount: params.amount, isIncrease: true }))
    {
        vm.startPrank(user);

        params.farm.underlyingAsset().approve(address(farmManager), params.amount);

        vm.expectEmit(true, true, true, true);
        emit IFarmManager.DepositWithProof(params.farm, params.amount, user, params.receiver, params.merkleProof);

        farmManager.depositERC20WithProof(params);

        vm.stopPrank();
    }

    function depositNativeAsset(
        address user,
        DepositParams memory params
    )
        public
        checkBalanceChange(
            CheckBalanceChangeParams({
                token: params.farm.underlyingAsset(),
                user: user,
                amount: params.amount,
                isIncrease: false
            })
        )
        checkBalanceChange(
            CheckBalanceChangeParams({
                token: params.farm.underlyingAsset(),
                user: address(params.farm),
                amount: params.amount,
                isIncrease: true
            })
        )
        checkShareChange(CheckShareChangeParams({ farm: params.farm, user: user, amount: params.amount, isIncrease: true }))
    {
        vm.startPrank(user);

        vm.expectEmit(true, true, true, true);
        emit IFarmManager.Deposit(params.farm, params.amount, user, params.receiver);

        farmManager.depositNativeAsset{ value: params.amount }(params);

        vm.stopPrank();
    }

    function depositNativeAssetWithProof(
        address user,
        DepositWithProofParams memory params
    )
        public
        checkBalanceChange(
            CheckBalanceChangeParams({
                token: params.farm.underlyingAsset(),
                user: user,
                amount: params.amount,
                isIncrease: false
            })
        )
        checkBalanceChange(
            CheckBalanceChangeParams({
                token: params.farm.underlyingAsset(),
                user: address(params.farm),
                amount: params.amount,
                isIncrease: true
            })
        )
        checkShareChange(CheckShareChangeParams({ farm: params.farm, user: user, amount: params.amount, isIncrease: true }))
    {
        vm.startPrank(user);

        vm.expectEmit(true, true, true, true);
        emit IFarmManager.DepositWithProof(params.farm, params.amount, user, params.receiver, params.merkleProof);

        farmManager.depositNativeAssetWithProof{ value: params.amount }(params);

        vm.stopPrank();
    }

    function withdraw(
        address user,
        WithdrawParams memory params
    )
        public
        checkBalanceChange(
            CheckBalanceChangeParams({
                token: params.farm.underlyingAsset(),
                user: user,
                amount: params.amount,
                isIncrease: true
            })
        )
        checkBalanceChange(
            CheckBalanceChangeParams({
                token: params.farm.underlyingAsset(),
                user: address(params.farm),
                amount: params.amount,
                isIncrease: false
            })
        )
        checkShareChange(
            CheckShareChangeParams({ farm: params.farm, user: user, amount: params.amount, isIncrease: false })
        )
    {
        vm.startPrank(user);

        // Expect Withdraw event
        vm.expectEmit(true, true, true, true);
        emit IFarmManager.Withdraw(params.farm, params.amount, user, params.receiver);

        farmManager.withdraw(params);

        vm.stopPrank();
    }

    function requestClaim(
        address user,
        RequestClaimParams memory params
    )
        public
        returns (uint256, uint256, uint256, bytes32)
    {
        vm.startPrank(user);
        uint256 nonce = params.farm.getNonce(user);
        (uint256 claimableTime, bytes32 claimId) =
            _prepareClaimId(params.farm, params.amount, user, params.receiver, block.timestamp, nonce);

        vm.expectEmit(true, true, true, true);
        emit IFarmManager.ClaimRequested(
            params.farm, params.amount, user, params.receiver, claimableTime, nonce, claimId
        );
        farmManager.requestClaim(params);

        vm.stopPrank();

        return (params.amount, claimableTime, nonce, claimId);
    }

    function executeClaim(address user, ExecuteClaimParams memory params) public {
        vm.startPrank(user);

        vm.expectEmit(true, true, true, true);
        emit IFarmManager.ClaimExecuted(
            params.farm, params.amount, user, params.receiver, params.claimableTime, params.nonce, params.claimId
        );

        farmManager.executeClaim(params);

        vm.stopPrank();
    }

    function prepareWhitelist(address[] memory whitelist) public pure returns (bytes32, bytes32[] memory) {
        bytes32[] memory hashList = new bytes32[](whitelist.length);
        for (uint256 i = 0; i < whitelist.length; i++) {
            hashList[i] = keccak256(abi.encode(whitelist[i]));
        }

        return (MerkleLib.prepareMerkleRoot(hashList), hashList);
    }

    function _prepareClaimId(
        IFarm farm,
        uint256 amount,
        address owner,
        address receiver,
        uint256 currentTime,
        uint256 nonce
    )
        internal
        view
        returns (uint256, bytes32)
    {
        (,,,,,,,,, uint256 claimDelayTime,,) = farm.farmConfig();
        uint256 claimableTime = currentTime + claimDelayTime;
        return (claimableTime, keccak256(abi.encode(amount, owner, receiver, claimableTime, nonce)));
    }

    function _getBalance(IERC20 token, address user) internal view returns (uint256) {
        if (address(token) == address(DEFAULT_NATIVE_ASSET_ADDRESS)) {
            return user.balance;
        }
        return token.balanceOf(user);
    }

    modifier checkBalanceChange(CheckBalanceChangeParams memory params) {
        uint256 initialBalance = _getBalance(params.token, params.user);
        _;
        uint256 finalBalance = _getBalance(params.token, params.user);
        if (params.isIncrease) {
            assertEq(finalBalance, initialBalance + params.amount, "Incorrect balance");
        } else {
            assertEq(finalBalance, initialBalance - params.amount, "Incorrect balance");
        }
    }

    modifier checkShareChange(CheckShareChangeParams memory params) {
        uint256 initialShare = params.farm.shares(params.user);
        uint256 initialTotalShares = params.farm.totalShares();
        _;
        uint256 finalShare = params.farm.shares(params.user);
        uint256 finalTotalShares = params.farm.totalShares();
        if (params.isIncrease) {
            assertEq(finalShare, initialShare + params.amount, "Incorrect remaining shares");
            assertEq(finalTotalShares, initialTotalShares + params.amount, "Incorrect total shares");
        } else {
            assertEq(finalShare, initialShare - params.amount, "Incorrect remaining shares");
            assertEq(finalTotalShares, initialTotalShares - params.amount, "Incorrect total shares");
        }
    }
}

struct CheckBalanceChangeParams {
    IERC20 token;
    address user;
    uint256 amount;
    bool isIncrease;
}

struct CheckShareChangeParams {
    IFarm farm;
    address user;
    uint256 amount;
    bool isIncrease;
}
