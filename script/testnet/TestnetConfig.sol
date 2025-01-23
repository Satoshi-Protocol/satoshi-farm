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
            rewardRate: 10_000 * 10 ** 18,
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
            rewardRate: 10_000 * 10 ** 18,
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
            rewardRate: 10_000 * 10 ** 18,
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
            rewardRate: 10_000 * 10 ** 18,
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

    DstInfo DST_INFO = DstInfo({
        dstEid: 40_231, // Arbitrum Sepolia chain
        dstRewardFarm: IFarm(address(0xa140F9E1d45eb7107Fa9665BA975B3601007B61E)),
        dstFarmManagerBytes32: bytes32(0x000000000000000000000000d7ee27a2f5a52643bb10c524211808163aff7bd3)
    });

    LzConfig LZ_CONFIG = LzConfig({
        eid: 40_231, // Arbitrum Sepolia chain
        endpoint: address(0x6EDCE65403992e310A62460808c4b910D972f10f),
        refundAddress: 0xb031931f4A6AB97302F2b931bfCf5C81A505E4c2
    });
}

abstract contract BaseSepTestnetConfig {
    address constant REWARD_TOKEN_ADDRESS = address(0x819591a4e747212EDA0880DD2F171B582Ce4149B);

    DstInfo DST_INFO = DstInfo({
        dstEid: 40_231, // Arbitrum Sepolia chain
        dstRewardFarm: IFarm(address(0xa140F9E1d45eb7107Fa9665BA975B3601007B61E)),
        dstFarmManagerBytes32: bytes32(0x000000000000000000000000d7ee27a2f5a52643bb10c524211808163aff7bd3)
    });

    LzConfig LZ_CONFIG = LzConfig({
        eid: 40_245, // BASE Sepolia chain
        endpoint: address(0x6EDCE65403992e310A62460808c4b910D972f10f),
        refundAddress: 0xb031931f4A6AB97302F2b931bfCf5C81A505E4c2
    });
}
