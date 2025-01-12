// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { FarmConfig } from "../src/interfaces/IFarm.sol";

address constant REWARD_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

abstract contract DeploySetupConfig {
    FarmConfig internal REWARD_FARM_CONFIG = FarmConfig({
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
        claimAndStakeEnabled: false
    });
}
