// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Farm } from "../src/core/Farm.sol";
import { FarmManager } from "../src/core/FarmManager.sol";
import { DEFAULT_NATIVE_ASSET_ADDRESS, FarmConfig, IFarm, WhitelistConfig } from "../src/core/interfaces/IFarm.sol";
import {
    DepositParams,
    DepositWithProofParams,
    ExecuteClaimParams,
    IFarmManager,
    RequestClaimParams,
    WithdrawParams
} from "../src/core/interfaces/IFarmManager.sol";
import { DeployBase } from "./utils/DeployBase.sol";

import { FarmTest } from "./utils/FarmTest.sol";

import { MerkleLib } from "./utils/MerkleLib.sol";
import { TestConfig } from "./utils/TestConfig.sol";
import { DEPLOYER, OWNER, TestConfig } from "./utils/TestConfig.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Test } from "forge-std/Test.sol";
import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";

contract FarmManagerERC20FuzzTest is Test, DeployBase {
    IFarm public farm;
    IERC20 public asset;
    address public user;
    uint256 public constant INITIAL_BALANCE = 100 ether;

    FarmTest public farmTest;

    function setUp() public override {
        // Deploy base contracts
        _deploySetUp();

        asset = IERC20(address(new MockERC20("Mock Asset", "MAT", 18)));

        // Create test Farm with default config
        FarmConfig memory config = _getDefaultFarmConfig();
        farm = _createFarm(DEPLOYER, asset, config);

        // Setup test user with initial balance
        user = makeAddr("user");
        deal(address(asset), user, INITIAL_BALANCE);

        farmTest = new FarmTest(farmManager);
    }

    // Fuzz test: Deposit amounts
    function testFuzz_deposit(uint256 amount) public {
        // Assume: amount is within reasonable bounds
        vm.assume(amount > 0 && amount <= INITIAL_BALANCE);

        // Deposit native tokens
        farmTest.depositERC20(user, DepositParams({ farm: farm, amount: amount, receiver: user }));
    }

    // Fuzz test: Withdraw amounts
    function testFuzz_withdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        // Assume: deposit and withdraw amounts are within valid ranges
        vm.assume(depositAmount > 0 && depositAmount <= INITIAL_BALANCE);
        vm.assume(withdrawAmount > 0 && withdrawAmount <= depositAmount);

        // First deposit
        farmTest.depositERC20(user, DepositParams({ farm: farm, amount: depositAmount, receiver: user }));

        // Then withdraw
        farmTest.withdraw(user, WithdrawParams({ farm: farm, amount: withdrawAmount, receiver: user }));
    }

    // Fuzz test: Request claim rewards
    function testFuzz_requestClaim(uint256 depositAmount) public {
        // Assume: deposit and claim amounts are within valid ranges
        vm.assume(depositAmount > 0 && depositAmount <= INITIAL_BALANCE);

        // First deposit
        farmTest.depositERC20(user, DepositParams({ farm: farm, amount: depositAmount, receiver: user }));

        // Wait for reward accrual
        vm.warp(block.timestamp + 1 days);

        // Request claim
        farmTest.requestClaim(user, RequestClaimParams({ farm: farm, amount: depositAmount, receiver: user }));
    }

    // Fuzz test: Execute claim rewards
    function testFuzz_executeClaim(uint256 depositAmount, uint256 intervalInDays) public {
        // Assume: parameters are within valid ranges
        vm.assume(depositAmount > 0 && depositAmount <= INITIAL_BALANCE);

        (,,,,,,,,, uint256 claimDelayTime,,) = farm.farmConfig();

        vm.assume(intervalInDays > (claimDelayTime / 1 days) && intervalInDays < 59);

        uint256 interval = intervalInDays * 1 days;

        // First deposit
        farmTest.depositERC20(user, DepositParams({ farm: farm, amount: depositAmount, receiver: user }));

        vm.warp(block.timestamp + 1 days);

        // Request claim
        (uint256 claimAmt, uint256 claimableTime, bytes32 claimId) =
            farmTest.requestClaim(user, RequestClaimParams({ farm: farm, amount: depositAmount, receiver: user }));

        // Wait for delay period
        vm.warp(block.timestamp + interval);

        // Execute claim
        farmTest.executeClaim(
            user,
            ExecuteClaimParams({
                farm: farm,
                amount: claimAmt,
                owner: user,
                receiver: user,
                claimableTime: claimableTime,
                claimId: claimId
            })
        );
    }

    // Fuzz test: Deposit amounts with whitelist
    function testFuzz_deposit_whitelist(uint256 amount) public {
        address[] memory whitelistAddresses = new address[](3);
        whitelistAddresses[0] = user;
        whitelistAddresses[1] = makeAddr("user2");
        whitelistAddresses[2] = makeAddr("user3");

        (bytes32 whitelistRoot, bytes32[] memory whitelist) = farmTest.prepareWhitelist(whitelistAddresses);

        // Update whitelist config
        vm.startPrank(DEPLOYER);
        farmManager.updateWhitelistConfig(farm, WhitelistConfig({ enabled: true, merkleRoot: whitelistRoot }));
        vm.stopPrank();

        // Update whitelist config
        vm.startPrank(DEPLOYER);
        farmManager.updateWhitelistConfig(farm, WhitelistConfig({ enabled: true, merkleRoot: whitelistRoot }));
        vm.stopPrank();

        // Assume: amount is within reasonable bounds
        vm.assume(amount > 0 && amount <= INITIAL_BALANCE);

        // Get merkle proof for user
        bytes32[] memory proof = MerkleLib.prepareMerkleProof(whitelist, 0);

        // Deposit native tokens
        farmTest.depositERC20WithProof(
            user, DepositWithProofParams({ farm: farm, amount: amount, receiver: user, merkleProof: proof })
        );
    }

    // Helper function: Get default farm configuration
    function _getDefaultFarmConfig() internal view returns (FarmConfig memory) {
        return FarmConfig({
            depositCap: 1000 ether,
            depositCapPerUser: 100 ether,
            depositStartTime: uint32(block.timestamp),
            depositEndTime: uint32(block.timestamp + 30 days),
            rewardRate: 1e18,
            rewardStartTime: uint32(block.timestamp),
            rewardEndTime: uint32(block.timestamp + 30 days),
            claimStartTime: uint32(block.timestamp),
            claimEndTime: uint32(block.timestamp + 60 days),
            claimDelayTime: 1 days,
            withdrawEnabled: true,
            instantClaimEnabled: true
        });
    }
}
