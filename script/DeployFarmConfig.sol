// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { FarmConfig } from "../src/interfaces/IFarm.sol";

address constant FARM_MANAGER_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
address constant UNDERLYING_ASSET_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
address constant REWARD_FARM_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

abstract contract DeployFarmConfig {
    FarmConfig internal FARM_CONFIG = FarmConfig({
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
