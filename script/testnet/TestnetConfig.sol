// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { FarmConfig, IFarm } from "../../src/core/interfaces/IFarm.sol";
import { MerkleLib } from "../../test/utils/MerkleLib.sol";

import { DstInfo, IFarmManager, LzConfig } from "../../src/core/interfaces/IFarmManager.sol";
import { IRewardToken } from "../../src/core/interfaces/IRewardToken.sol";


library TestnetConfigHelper {
    function prepareMerkleProof(bytes32[] memory whitelist, uint256 index) public pure returns (bytes32[] memory) {
        bytes32[] memory proof = MerkleLib.prepareMerkleProof(whitelist, index);
        return proof;
    }

    function prepareWhitelist(address[] memory whitelist) public pure returns (bytes32, bytes32[] memory) {
        bytes32[] memory hashList = new bytes32[](whitelist.length);
        for (uint256 i = 0; i < whitelist.length; i++) {
            hashList[i] = keccak256(abi.encode(whitelist[i]));
        }

        return (MerkleLib.prepareMerkleRoot(hashList), hashList);
    }

    function getMemeFarmConfigWith10000Cap500per() internal view returns (FarmConfig memory) {
        return FarmConfig({
            depositCap: 10000 ether,
            depositCapPerUser: 500 ether,
            depositStartTime: uint32(block.timestamp),
            depositEndTime: uint32(block.timestamp + 30 days),
            rewardRate: 10_000 * 10**18,
            rewardStartTime: uint32(block.timestamp),
            rewardEndTime: uint32(block.timestamp + 30 days),
            claimStartTime: uint32(block.timestamp),
            claimEndTime: uint32(block.timestamp + 60 days),
            claimDelayTime: 5 minutes,
            withdrawEnabled: true,
            instantClaimEnabled: true
        });
    }

    function getMemeFarmConfigWithWhitelist() internal view returns (FarmConfig memory) {
        return FarmConfig({
            depositCap: 100_000 ether,
            depositCapPerUser: 10_000 ether,
            depositStartTime: uint32(block.timestamp),
            depositEndTime: uint32(block.timestamp + 30 days),
            rewardRate: 10_000 * 10**18,
            rewardStartTime: uint32(block.timestamp),
            rewardEndTime: uint32(block.timestamp + 30 days),
            claimStartTime: uint32(block.timestamp),
            claimEndTime: uint32(block.timestamp + 60 days),
            claimDelayTime: 5 minutes,
            withdrawEnabled: true,
            instantClaimEnabled: true
        });
    }

    function getMemeFarmConfigWithNoCap() internal view returns (FarmConfig memory) {
        return FarmConfig({
            depositCap: type(uint256).max,
            depositCapPerUser:type(uint256).max,
            depositStartTime: uint32(block.timestamp),
            depositEndTime: uint32(block.timestamp + 30 days),
            rewardRate: 10_000 * 10**18,
            rewardStartTime: uint32(block.timestamp),
            rewardEndTime: uint32(block.timestamp + 30 days),
            claimStartTime: uint32(block.timestamp),
            claimEndTime: uint32(block.timestamp + 60 days),
            claimDelayTime: 5 minutes,
            withdrawEnabled: true,
            instantClaimEnabled: true
        });
    }
}
abstract contract ArbSepTestnetConfig {
    bool constant IS_DEPLOY_MEME_FARM = true;
    address constant REWARD_TOKEN_ADDRESS = address(0x1e1d7C76Bd273d60E756322A8Ea9A1914327fa13);

    /**
     * DstInfo
     */
    DstInfo DST_INFO = DstInfo({
        dstEid: 40_231, // Arbitrum Sepolia chain
        dstRewardFarm: IFarm(address(0xEe8fc63B31AA5810aF99A37360AcA2C5A61c2973)),
        dstRewardManagerBytes32: bytes32(0x0000000000000000000000004955d2b83a5a46ee41a38db4ea1c333838dc6046)
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
        dstRewardFarm: IFarm(address(0xEe8fc63B31AA5810aF99A37360AcA2C5A61c2973)),
        dstRewardManagerBytes32: bytes32(0x0000000000000000000000004955d2b83a5a46ee41a38db4ea1c333838dc6046)
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
