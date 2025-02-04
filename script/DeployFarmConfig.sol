// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { FarmConfig } from "../src/core/interfaces/IFarm.sol";

address constant FARM_MANAGER_ADDRESS = 0xefd8C52b3aF1b142FBCEb7EA0d3cddc82058e3F8;
address constant UNDERLYING_ASSET_ADDRESS = 0xA5f4422532a06e51f899D74D03b0507184141FCA;

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
        forceClaimEnabled: true
    });
}
