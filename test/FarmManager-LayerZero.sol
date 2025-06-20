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
    LZ_COMPOSE_OPT,
    RequestClaimParams,
    WithdrawParams
} from "../src/core/interfaces/IFarmManager.sol";
import { DeployBase } from "./utils/DeployBase.sol";

import { FarmTest } from "./utils/FarmTest.sol";

import { OFTComposeMsgCodec } from "../src/layerzero/OFTComposeMsgCodec.sol";
import { MerkleLib } from "./utils/MerkleLib.sol";
import { MOCK_LZ_ENDPOINT, MOCK_REFUND_ADDR, TestConfig } from "./utils/TestConfig.sol";
import { DEPLOYER, OWNER, TestConfig } from "./utils/TestConfig.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Test, console } from "forge-std/Test.sol";
import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";

contract FarmManagerLayerZeroTest is Test, DeployBase {
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

    function test_lzCompose() public {
        // address oApp = address(rewardToken);
        // bytes32 guid = bytes32(0);
        // address executor = address(0);
        // bytes memory executorData = new bytes(0);
        // uint256 amount = 1e18;

        // bytes memory bytesData = abi.encode(amount, user);
        // bytes memory composeMsgHalf = abi.encode(LZ_COMPOSE_OPT.DEPOSIT_REWARD_TOKEN, bytesData);

        // fromChain's from Address
        // bytes32 composeFromMock = bytes32(0x000000000000000000000000f5709175a984f36d3b6d2603944d570968fab40b);
        // bytes memory composeMsg = abi.encode(composeFromMock, composeMsgHalf);
        // bytes memory message = OFTComposeMsgCodec.encode(0, 0, amount, composeMsg);

        // vm.startPrank(MOCK_LZ_ENDPOINT);
        // deal(address(rewardToken), MOCK_LZ_ENDPOINT, 100 ether);
        // rewardToken.transfer(address(farmManager), amount);
        // farmManager.lzCompose(
        //     oApp,
        //     guid,
        //     message,
        //     executor,
        //     executorData
        // );
        // vm.stopPrank();
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
            withdrawFee: 0,
            withdrawEnabled: true,
            forceClaimEnabled: true
        });
    }
}
