// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { FarmConfig, IFarm } from "../src/core/interfaces/IFarm.sol";
import { DstInfo, LzConfig } from "../src/core/interfaces/IFarmManager.sol";

address constant REWARD_TOKEN_ADDRESS = 0x44621f077464a41849E2e3E972e07CBF6999c508;

abstract contract DeploySetupConfig {
    FarmConfig internal REWARD_FARM_CONFIG = FarmConfig({
        depositCap: type(uint256).max,
        depositCapPerUser: type(uint256).max,
        depositStartTime: uint32(block.timestamp),
        depositEndTime: type(uint32).max,
        rewardRate: 5_208_333_333_333_333,
        rewardStartTime: uint32(block.timestamp),
        rewardEndTime: type(uint32).max,
        claimStartTime: type(uint32).max,
        claimEndTime: type(uint32).max,
        claimDelayTime: 0,
        withdrawEnabled: false,
        forceClaimEnabled: false
    });

    DstInfo internal DST_INFO = DstInfo({
        dstEid: 40_245,
        dstRewardFarm: IFarm(address(0x589c06a481427E8Dfeb6a6066F9a9441e6Ac3965)),
        dstFarmManagerBytes32: bytes32(uint256(uint160(0x43Ae83295a09117D82835302019159DfAAB6C640)))
    });

    LzConfig internal LZ_CONFIG = LzConfig({
        eid: 40161,
        endpoint: address(0x6EDCE65403992e310A62460808c4b910D972f10f),
        refundAddress: address(0xf13d1D93563c27b8C7ca4fCA1fcD9114d36139bb)
    });
}
