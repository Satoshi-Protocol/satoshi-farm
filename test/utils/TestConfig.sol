// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { FarmConfig } from "../../src/core/interfaces/IFarm.sol";
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
}
