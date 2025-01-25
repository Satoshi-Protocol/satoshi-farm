// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { FarmConfig, IFarm } from "../src/core/interfaces/IFarm.sol";
import { DstInfo, LzConfig } from "../src/core/interfaces/IFarmManager.sol";

address constant REWARD_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

abstract contract DeploySetupConfig {
    FarmConfig internal REWARD_FARM_CONFIG = FarmConfig({
        depositCap: 0,
        depositCapPerUser: 0,
        depositStartTime: 0,
        depositEndTime: type(uint32).max,
        rewardRate: 1000,
        rewardStartTime: 0,
        rewardEndTime: type(uint32).max,
        claimStartTime: type(uint32).max,
        claimEndTime: type(uint32).max,
        claimDelayTime: 0,
        withdrawEnabled: false,
        forceClaimEnabled: false
    });

    DstInfo internal DST_INFO =
        DstInfo({ dstEid: 0, dstRewardFarm: IFarm(address(0)), dstFarmManagerBytes32: bytes32(0) });

    LzConfig internal LZ_CONFIG = LzConfig({ eid: 0, endpoint: address(0), refundAddress: address(0) });
}
