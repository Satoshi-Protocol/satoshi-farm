// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { FarmConfig } from "../src/core/interfaces/IFarm.sol";

address constant FARM_MANAGER_ADDRESS = 0x1538b8A949e9a396B377F2607516E4852d475936;
address constant UNDERLYING_ASSET_ADDRESS = 0x59fdaB9956C5Dc85f2b9ceC31551cAb6f9C3897D;

abstract contract DeployFarmConfig {
    FarmConfig internal FARM_CONFIG = FarmConfig({
        depositCap: 1000e18,
        depositCapPerUser: 10e18,
        depositStartTime: uint32(block.timestamp),
        depositEndTime: type(uint32).max,
        rewardRate: 28_935_185_185_185_184,
        rewardStartTime: uint32(block.timestamp),
        rewardEndTime: type(uint32).max,
        claimStartTime: uint32(block.timestamp),
        claimEndTime: type(uint32).max,
        claimDelayTime: 1 days,
        withdrawFee: 0,
        withdrawEnabled: true,
        forceClaimEnabled: true
    });
}
