// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { FarmConfig, IFarm } from "../src/core/interfaces/IFarm.sol";
import { DstInfo, LzConfig } from "../src/core/interfaces/IFarmManager.sol";

address constant REWARD_TOKEN_ADDRESS = 0x44621f077464a41849E2e3E972e07CBF6999c508;
address constant FEE_RECEIVER = 0xC7a072bE57f3370BE7148d4F67442dAC26DB3D6F;

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
        withdrawFee: 0,
        withdrawEnabled: false,
        forceClaimEnabled: false
    });

    DstInfo internal DST_INFO = DstInfo({
        dstEid: 40_231,
        dstRewardFarm: IFarm(address(0xa2e432153Ce62663c6d97C66c1fc368F47d1dbF6)),
        dstFarmManagerBytes32: bytes32(uint256(uint160(0x2c00119162518D7C137257782022AebD4B79f64d)))
    });

    LzConfig internal LZ_CONFIG = LzConfig({
        eid: 40_161,
        endpoint: address(0x6EDCE65403992e310A62460808c4b910D972f10f),
        refundAddress: address(0xf13d1D93563c27b8C7ca4fCA1fcD9114d36139bb)
    });
}
