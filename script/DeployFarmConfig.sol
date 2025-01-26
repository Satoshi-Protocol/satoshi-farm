// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { FarmConfig } from "../src/core/interfaces/IFarm.sol";

address constant FARM_MANAGER_ADDRESS = 0x86B9c300d65CcC8Bd9284f5000D69df0EF0fb05E;
address constant UNDERLYING_ASSET_ADDRESS = 0x59fdaB9956C5Dc85f2b9ceC31551cAb6f9C3897D;

abstract contract DeployFarmConfig {
    FarmConfig internal FARM_CONFIG = FarmConfig({
        depositCap: type(uint256).max,
        depositCapPerUser: type(uint256).max,
        depositStartTime: uint32(block.timestamp),
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
