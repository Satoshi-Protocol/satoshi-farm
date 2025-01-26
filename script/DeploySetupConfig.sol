// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { FarmConfig, IFarm } from "../src/core/interfaces/IFarm.sol";
import { DstInfo, LzConfig } from "../src/core/interfaces/IFarmManager.sol";

address constant REWARD_TOKEN_ADDRESS = 0x570AAe4E945Dff2F576f7aD2f529E982CD5C4D52;

abstract contract DeploySetupConfig {
    FarmConfig internal REWARD_FARM_CONFIG = FarmConfig({
        depositCap: 0,
        depositCapPerUser: 0,
        depositStartTime: 0,
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
        dstRewardFarm: IFarm(address(0x32198912CF24A0240AE48F46FEDf92ECD3328EaC)),
        dstFarmManagerBytes32: bytes32(uint256(uint160(0xa0CCAc865034E7a8f47297E130FCf117891cA155)))
    });

    LzConfig internal LZ_CONFIG = LzConfig({
        eid: 40_161,
        endpoint: address(0x6EDCE65403992e310A62460808c4b910D972f10f),
        refundAddress: address(0xf13d1D93563c27b8C7ca4fCA1fcD9114d36139bb)
    });
}
