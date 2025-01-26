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
            depositCap: 10_000 ether,
            depositCapPerUser: 500 ether,
            depositStartTime: uint32(block.timestamp),
            depositEndTime: uint32(block.timestamp + 30 days),
            rewardRate: 28935185185185184,
            rewardStartTime: uint32(block.timestamp),
            rewardEndTime: uint32(block.timestamp + 30 days),
            claimStartTime: uint32(block.timestamp),
            claimEndTime: uint32(block.timestamp + 60 days),
            claimDelayTime: 5 minutes,
            withdrawEnabled: true,
            forceClaimEnabled: true
        });
    }

    function getMemeFarmConfigWithWhitelist() internal view returns (FarmConfig memory) {
        return FarmConfig({
            depositCap: type(uint256).max,
            depositCapPerUser: type(uint256).max,
            depositStartTime: uint32(block.timestamp),
            depositEndTime: uint32(block.timestamp + 30 days),
            rewardRate: 28935185185185184,
            rewardStartTime: uint32(block.timestamp),
            rewardEndTime: uint32(block.timestamp + 30 days),
            claimStartTime: uint32(block.timestamp),
            claimEndTime: uint32(block.timestamp + 60 days),
            claimDelayTime: 5 minutes,
            withdrawEnabled: true,
            forceClaimEnabled: true
        });
    }

    function getMemeFarmConfigWithNoCap() internal view returns (FarmConfig memory) {
        return FarmConfig({
            depositCap: type(uint256).max,
            depositCapPerUser: type(uint256).max,
            depositStartTime: uint32(block.timestamp),
            depositEndTime: uint32(block.timestamp + 30 days),
            rewardRate: 28935185185185184,
            rewardStartTime: uint32(block.timestamp),
            rewardEndTime: uint32(block.timestamp + 30 days),
            claimStartTime: uint32(block.timestamp),
            claimEndTime: uint32(block.timestamp + 60 days),
            claimDelayTime: 5 minutes,
            withdrawEnabled: true,
            forceClaimEnabled: true
        });
    }

    function getRewardFarmConfig() internal view returns (FarmConfig memory) {
        return FarmConfig({
            depositCap: type(uint256).max,
            depositCapPerUser: type(uint256).max,
            depositStartTime: uint32(block.timestamp),
            depositEndTime: uint32(block.timestamp + 30 days),
            rewardRate: 5208333333333333,
            rewardStartTime: uint32(block.timestamp),
            rewardEndTime: uint32(block.timestamp + 30 days),
            claimStartTime: uint32(block.timestamp),
            claimEndTime: uint32(block.timestamp + 60 days),
            claimDelayTime: 5 minutes,
            withdrawEnabled: true,
            forceClaimEnabled: true
        });
    }
}

abstract contract ArbSepTestnetConfig {
    address constant REWARD_TOKEN_ADDRESS = address(0x1e1d7C76Bd273d60E756322A8Ea9A1914327fa13);
    string constant MEME_TOKEN_SYMBOL = "Ai16z";

    DstInfo DST_INFO = DstInfo({
        dstEid: 40332, // Arbitrum Sepolia chain
        dstRewardFarm: IFarm(address(0xB90333dDF932D7B1Ea3ea4F4f5C47E5B1ed00213)),
        dstFarmManagerBytes32: bytes32(0x00000000000000000000000029a2e39aee8941e5d59568e9a981c3b21ffce1ee)
    });

    LzConfig LZ_CONFIG = LzConfig({
        eid: 40_231, // Arbitrum Sepolia chain
        endpoint: address(0x6EDCE65403992e310A62460808c4b910D972f10f),
        refundAddress: 0xb031931f4A6AB97302F2b931bfCf5C81A505E4c2
    });
}

abstract contract BaseSepTestnetConfig {
    address constant REWARD_TOKEN_ADDRESS = address(0x819591a4e747212EDA0880DD2F171B582Ce4149B);
    string constant MEME_TOKEN_SYMBOL = "Ai16z";

    DstInfo DST_INFO = DstInfo({
        dstEid: 40332, // Arbitrum Sepolia chain
        dstRewardFarm: IFarm(address(0xB90333dDF932D7B1Ea3ea4F4f5C47E5B1ed00213)),
        dstFarmManagerBytes32: bytes32(0x00000000000000000000000029a2e39aee8941e5d59568e9a981c3b21ffce1ee)
    });

    LzConfig LZ_CONFIG = LzConfig({
        eid: 40_245, // BASE Sepolia chain
        endpoint: address(0x6EDCE65403992e310A62460808c4b910D972f10f),
        refundAddress: 0xb031931f4A6AB97302F2b931bfCf5C81A505E4c2
    });
}


abstract contract HyperliquidTestnetConfig {
    address constant REWARD_TOKEN_ADDRESS = address(0x46Ff6484BeB9B4e368eED4B5bBc5609BE44415eF);
    string constant MEME_TOKEN_SYMBOL = "HYPE";

    DstInfo DST_INFO = DstInfo({
        dstEid: 40332, // Arbitrum Sepolia chain
        dstRewardFarm: IFarm(address(0)),
        dstFarmManagerBytes32: bytes32(0)
    });

    // DstInfo DST_INFO = DstInfo({
    //     dstEid: 40_231, // Arbitrum Sepolia chain
    //     dstRewardFarm: IFarm(address(0x922C00923534415203472Da91F8BbEA5782674E8)),
    //     dstFarmManagerBytes32: bytes32(0x000000000000000000000000b4bb342294fe7d0d2ebdd894498b27bba13d5f1b)
    // });

    LzConfig LZ_CONFIG = LzConfig({
        eid: 40332, // BASE Sepolia chain
        endpoint: address(0x6Ac7bdc07A0583A362F1497252872AE6c0A5F5B8),
        refundAddress: 0xb031931f4A6AB97302F2b931bfCf5C81A505E4c2
    });
}
