// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { FarmConfig, IFarm } from "../../src/core/interfaces/IFarm.sol";

import { DstInfo, IFarmManager, LzConfig } from "../../src/core/interfaces/IFarmManager.sol";
import { IRewardToken } from "../../src/core/interfaces/IRewardToken.sol";

abstract contract ArbSepTestnetConfig {
    bool constant IS_DEPLOY_MEME_FARM = true;
    address constant REWARD_TOKEN_ADDRESS = address(0x1e1d7C76Bd273d60E756322A8Ea9A1914327fa13);

    /**
     * DstInfo
     */
    DstInfo DST_INFO = DstInfo({
        dstEid: 40_231, // Arbitrum Sepolia chain
        dstRewardFarm: IFarm(address(0)),
        dstRewardManagerBytes32: bytes32(0)
    });

    /**
     * LzConfig
     */
    LzConfig LZ_CONFIG = LzConfig({
        eid: 40_231, // Arbitrum Sepolia chain
        endpoint: address(0x6EDCE65403992e310A62460808c4b910D972f10f),
        refundAddress: 0xD26C9387F92EEa2cD030440A0799E403B225B8dD
    });

    FarmConfig REWARD_FARM_CONFIG = FarmConfig({
        depositCap: 10_000_000e18,
        depositCapPerUser: 10_000_000e18,
        depositStartTime: 0,
        depositEndTime: type(uint32).max,
        rewardRate: 10_000e18,
        rewardStartTime: 0,
        rewardEndTime: type(uint32).max,
        claimStartTime: type(uint32).max,
        claimEndTime: type(uint32).max,
        claimDelayTime: 0,
        withdrawEnabled: false,
        instantClaimEnabled: true
    });
}

abstract contract BaseSepTestnetConfig {
    bool constant IS_DEPLOY_MEME_FARM = true;
    address constant REWARD_TOKEN_ADDRESS = address(0x1e1d7C76Bd273d60E756322A8Ea9A1914327fa13);

    /**
     * DstInfo
     */
    DstInfo DST_INFO = DstInfo({
        dstEid: 40_231, // Arbitrum Sepolia chain
        dstRewardFarm: IFarm(address(0x3233ec018b2C1fB23FCd2291E43B873D9A6bdfAB)),
        dstRewardManagerBytes32: bytes32(0x0000000000000000000000006001345f8513a1954570e5b6a0d214a2b2df239d)
    });

    /**
     * LzConfig
     */
    LzConfig LZ_CONFIG = LzConfig({
        eid: 40_245, // BASE Sepolia chain
        endpoint: address(0x6EDCE65403992e310A62460808c4b910D972f10f),
        refundAddress: 0xD26C9387F92EEa2cD030440A0799E403B225B8dD
    });

    FarmConfig REWARD_FARM_CONFIG = FarmConfig({
        depositCap: 10_000_000e18,
        depositCapPerUser: 10_000_000e18,
        depositStartTime: 0,
        depositEndTime: type(uint32).max,
        rewardRate: 10_000e18,
        rewardStartTime: 0,
        rewardEndTime: type(uint32).max,
        claimStartTime: type(uint32).max,
        claimEndTime: type(uint32).max,
        claimDelayTime: 0,
        withdrawEnabled: false,
        instantClaimEnabled: true
    });
}
