// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { FarmConfig, IFarm } from "../../src/core/interfaces/IFarm.sol";
import { MerkleLib } from "../../test/utils/MerkleLib.sol";
import { Script, console } from "forge-std/Script.sol";

import { DstInfo, IFarmManager, LZ_COMPOSE_OPT, LzConfig } from "../../src/core/interfaces/IFarmManager.sol";
import { IRewardToken } from "../../src/core/interfaces/IRewardToken.sol";
import { IOFT, MessagingFee, SendParam } from "../../src/layerzero/IOFT.sol";

import { OFTComposeMsgCodec } from "../../src/layerzero/OFTComposeMsgCodec.sol";
import { ERC20Mock } from "./MockERC20.sol";

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
            depositEndTime: type(uint32).max,
            rewardRate: 28_935_185_185_185_184,
            rewardStartTime: uint32(block.timestamp),
            rewardEndTime: type(uint32).max,
            claimStartTime: uint32(block.timestamp),
            claimEndTime: type(uint32).max,
            claimDelayTime: 20 minutes,
            withdrawFee: 0,
            withdrawEnabled: true,
            forceClaimEnabled: true
        });
    }

    function getMemeFarmConfigWithWhitelist() internal view returns (FarmConfig memory) {
        return FarmConfig({
            depositCap: type(uint256).max,
            depositCapPerUser: type(uint256).max,
            depositStartTime: uint32(block.timestamp),
            depositEndTime: type(uint32).max,
            rewardRate: 28_935_185_185_185_184,
            rewardStartTime: uint32(block.timestamp),
            rewardEndTime: type(uint32).max,
            claimStartTime: uint32(block.timestamp),
            claimEndTime: type(uint32).max,
            claimDelayTime: 20 minutes,
            withdrawFee: 0,
            withdrawEnabled: true,
            forceClaimEnabled: true
        });
    }

    function getMemeFarmConfigWithNoCap() internal view returns (FarmConfig memory) {
        return FarmConfig({
            depositCap: type(uint256).max,
            depositCapPerUser: type(uint256).max,
            depositStartTime: uint32(block.timestamp),
            depositEndTime: type(uint32).max,
            rewardRate: 28_935_185_185_185_184,
            rewardStartTime: uint32(block.timestamp),
            rewardEndTime: type(uint32).max,
            claimStartTime: uint32(block.timestamp),
            claimEndTime: type(uint32).max,
            claimDelayTime: 20 minutes,
            withdrawFee: 0,
            withdrawEnabled: true,
            forceClaimEnabled: true
        });
    }

    function getRewardFarmConfig() internal view returns (FarmConfig memory) {
        return FarmConfig({
            depositCap: type(uint256).max,
            depositCapPerUser: type(uint256).max,
            depositStartTime: uint32(block.timestamp),
            depositEndTime: type(uint32).max,
            rewardRate: 5_208_333_333_333_333,
            rewardStartTime: uint32(block.timestamp),
            rewardEndTime: type(uint32).max,
            claimStartTime: uint32(block.timestamp),
            claimEndTime: type(uint32).max,
            claimDelayTime: 20 minutes,
            withdrawFee: 0,
            withdrawEnabled: false,
            forceClaimEnabled: false
        });
    }
}

abstract contract ArbSepTestnetConfig {
    address constant REWARD_TOKEN_ADDRESS = address(0x677a4016F631fEDcfC49495998A2d646C9E61943);
    string constant MEME_TOKEN_SYMBOL = "TRX";

    address constant FEE_RECEIVER = 0xC7a072bE57f3370BE7148d4F67442dAC26DB3D6F;

    DstInfo DST_INFO = DstInfo({
        dstEid: 40_245,
        dstRewardFarm: IFarm(address(0x132aCdCffCF924c792945B93DE2c27f367F2B081)),
        dstFarmManagerBytes32: bytes32(0x0000000000000000000000005dcd7d96792e10ad32f4862dc9d7d57a378a0f35)
    });

    LzConfig LZ_CONFIG = LzConfig({
        eid: 40_231, // Arbitrum Sepolia chain
        endpoint: address(0x6EDCE65403992e310A62460808c4b910D972f10f),
        refundAddress: 0xb031931f4A6AB97302F2b931bfCf5C81A505E4c2
    });
}

abstract contract BaseSepTestnetConfig {
    address constant REWARD_TOKEN_ADDRESS = address(0x8d86D4D688c0584c5C13D66cc85199EC1c587B4c);
    string constant MEME_TOKEN_SYMBOL = "CRV";

    address constant FEE_RECEIVER = 0xC7a072bE57f3370BE7148d4F67442dAC26DB3D6F;

    DstInfo DST_INFO = DstInfo({
        dstEid: 40_245,
        dstRewardFarm: IFarm(address(0x132aCdCffCF924c792945B93DE2c27f367F2B081)),
        dstFarmManagerBytes32: bytes32(0x0000000000000000000000005dcd7d96792e10ad32f4862dc9d7d57a378a0f35)
    });

    LzConfig LZ_CONFIG = LzConfig({
        eid: 40_245, // BASE Sepolia chain
        endpoint: address(0x6EDCE65403992e310A62460808c4b910D972f10f),
        refundAddress: 0xb031931f4A6AB97302F2b931bfCf5C81A505E4c2
    });
}

abstract contract SepoliaTestnetConfig {
    address constant REWARD_TOKEN_ADDRESS = address(0xEb655511b444d0f9eb78ABc6fb7EdFc238d0c7F1);
    string constant MEME_TOKEN_SYMBOL = "HYPE";

    address constant FEE_RECEIVER = 0xC7a072bE57f3370BE7148d4F67442dAC26DB3D6F;

    DstInfo DST_INFO = DstInfo({
        dstEid: 40_245,
        dstRewardFarm: IFarm(address(0x132aCdCffCF924c792945B93DE2c27f367F2B081)),
        dstFarmManagerBytes32: bytes32(0x0000000000000000000000005dcd7d96792e10ad32f4862dc9d7d57a378a0f35)
    });

    LzConfig LZ_CONFIG = LzConfig({
        eid: 40_161, // BASE Sepolia chain
        endpoint: address(0x6EDCE65403992e310A62460808c4b910D972f10f),
        refundAddress: 0xb031931f4A6AB97302F2b931bfCf5C81A505E4c2
    });
}

abstract contract HyperliquidTestnetConfig {
    address constant REWARD_TOKEN_ADDRESS = address(0x46Ff6484BeB9B4e368eED4B5bBc5609BE44415eF);
    string constant MEME_TOKEN_SYMBOL = "HYPE";

    address constant FEE_RECEIVER = 0xC7a072bE57f3370BE7148d4F67442dAC26DB3D6F;

    DstInfo DST_INFO = DstInfo({
        dstEid: 40_245, // Arbitrum Sepolia chain
        dstRewardFarm: IFarm(address(0)),
        dstFarmManagerBytes32: bytes32(0)
    });

    // DstInfo DST_INFO = DstInfo({
    //     dstEid: 40_231, // Arbitrum Sepolia chain
    //     dstRewardFarm: IFarm(address(0x922C00923534415203472Da91F8BbEA5782674E8)),
    //     dstFarmManagerBytes32: bytes32(0x000000000000000000000000b4bb342294fe7d0d2ebdd894498b27bba13d5f1b)
    // });

    LzConfig LZ_CONFIG = LzConfig({
        eid: 40_332, // BASE Sepolia chain
        endpoint: address(0x6Ac7bdc07A0583A362F1497252872AE6c0A5F5B8),
        refundAddress: 0xb031931f4A6AB97302F2b931bfCf5C81A505E4c2
    });
}

abstract contract TestScriptConfig {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address constant FEE_RECEIVER = 0xC7a072bE57f3370BE7148d4F67442dAC26DB3D6F;

    ERC20Mock memeAsset;
    IFarm memeFarm;
    IFarmManager farmManager;
    IRewardToken rewardToken;
    address public owner;

    bytes constant EXTRA_OPTIONS =
        hex"00030100110100000000000000000000000000030d40010013030000000000000000000000000000002dc6c0";
    //   bytes constant EXTRA_OPTIONS_LOW_GAS = hex"00030100110100000000000000000000000000030d4001001303000000000000000000000000000000004e20";

    function showRewardFarmInfo() public view {
        (, IFarm rewardFarm,) = farmManager.dstInfo();
        console.log("====== Reward farm ======");
        console.log("Preview reward: %d", rewardFarm.previewReward(owner));
        console.log("Total shares: %d", rewardFarm.totalShares());
        console.log("Shares: %d", rewardFarm.shares(owner));
        console.log("Last reward per token: %d", rewardFarm.lastRewardPerToken());
        console.log("Preview reward: %d", farmManager.previewReward(rewardFarm, owner));
        console.log("Is claimable: %d", farmManager.isClaimable(rewardFarm));
    }

    function formatDepositLzSendParam(
        address receiver,
        uint256 amount,
        bytes memory extraOptions
    )
        public
        view
        returns (SendParam memory)
    {
        (uint32 dstEid,, bytes32 dstFarmManagerBytes32) = farmManager.dstInfo();
        bytes memory composeMsg = abi.encode(LZ_COMPOSE_OPT.DEPOSIT_REWARD_TOKEN, abi.encode(amount, receiver));

        return SendParam(
            dstEid,
            dstFarmManagerBytes32,
            amount,
            amount,
            extraOptions,
            composeMsg,
            "" // oftCmd
        );
    }

    function formatSimpleSendParam(
        uint32 dstEid,
        address receiver,
        uint256 amount,
        bytes memory extraOptions
    )
        public
        pure
        returns (SendParam memory)
    {
        return SendParam(
            dstEid,
            OFTComposeMsgCodec.addressToBytes32(receiver),
            amount,
            amount,
            extraOptions,
            "",
            "" // oftCmd
        );
    }
}
