// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { FarmConfig } from "../../src/core/interfaces/IFarm.sol";

import { IFarm } from "../../src/core/interfaces/IFarm.sol";
import { DstInfo, LzConfig } from "../../src/core/interfaces/IFarmManager.sol";
import { Test } from "forge-std/Test.sol";

address constant DEPLOYER = 0x1234567890123456789012345678901234567890;
address constant OWNER = 0x1111111111111111111111111111111111111111;

abstract contract TestConfig {
    FarmConfig internal DEFAULT_REWARD_FARM_CONFIG = FarmConfig({
        depositCap: 0,
        depositCapPerUser: 0,
        rewardRate: 1000,
        depositStartTime: 0,
        depositEndTime: type(uint32).max,
        rewardStartTime: 0, //TODO: cannot be 0
        rewardEndTime: type(uint32).max,
        claimStartTime: type(uint32).max,
        claimEndTime: type(uint32).max,
        claimDelayTime: 0,
        withdrawEnabled: false,
        instantClaimEnabled: false
    });

    FarmConfig internal DEFAULT_FARM_CONFIG = FarmConfig({
        depositCap: 10_000e18,
        depositCapPerUser: 1000e18,
        rewardRate: 1000,
        depositStartTime: uint32(block.timestamp),
        depositEndTime: uint32(block.timestamp + 60 days),
        rewardStartTime: uint32(block.timestamp + 30 days),
        rewardEndTime: uint32(block.timestamp + 40 days),
        claimStartTime: uint32(block.timestamp + 30 days),
        claimEndTime: uint32(block.timestamp + 60 days),
        claimDelayTime: uint32(1 days),
        withdrawEnabled: true,
        instantClaimEnabled: true
    });

    LzConfig internal DEFAULT_LZ_CONFIG = LzConfig({ eid: 0, endpoint: address(0), refundAddress: address(0) });

    DstInfo internal DEFAULT_DST_INFO =
        DstInfo({ dstEid: 0, dstRewardFarm: IFarm(address(0)), dstRewardManagerBytes32: bytes32(0) });
}
