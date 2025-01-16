// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { FarmConfig } from "../../src/interfaces/IFarm.sol";
import { Test } from "forge-std/Test.sol";

address constant DEPLOYER = 0x1234567890123456789012345678901234567890;
address constant OWNER = 0x1111111111111111111111111111111111111111;

abstract contract TestConfig {
    FarmConfig internal DEFAULT_REWARD_FARM_CONFIG = FarmConfig({
        depositCap: 0,
        depositCapPerUser: 0,
        depositStartTime: 0,
        depositEndTime: type(uint256).max,
        rewardRate: 1000,
        rewardStartTime: 0,
        rewardEndTime: type(uint256).max,
        claimStartTime: type(uint256).max,
        claimEndTime: type(uint256).max,
        claimDelayTime: 0,
        instantClaimEnabled: false
    });
}
