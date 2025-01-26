// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { FarmConfig } from "../src/core/interfaces/IFarm.sol";

address constant FARM_MANAGER_ADDRESS = 0xEC4A8A4b9E09aE963D5FAbA4D3d8BA5D4C412b6B;
address constant UNDERLYING_ASSET_ADDRESS = 0x59fdaB9956C5Dc85f2b9ceC31551cAb6f9C3897D;

abstract contract DeployFarmConfig {
    FarmConfig internal FARM_CONFIG = FarmConfig({
        depositCap: 0,
        depositCapPerUser: 0,
        depositStartTime: 0,
        depositEndTime: type(uint32).max,
        rewardRate: 28_935_185_185_185_184,
        rewardStartTime: uint32(block.timestamp),
        rewardEndTime: type(uint32).max,
        claimStartTime: uint32(block.timestamp),
        claimEndTime: type(uint32).max,
        claimDelayTime: 1 days,
        withdrawEnabled: true,
        forceClaimEnabled: false
    });
}
