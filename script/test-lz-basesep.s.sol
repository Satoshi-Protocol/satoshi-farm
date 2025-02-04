// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Farm } from "../src/core/Farm.sol";

import {
    ClaimAndStakeCrossChainParams,
    ClaimAndStakeParams,
    FarmManager,
    RequestClaimParams
} from "../src/core/FarmManager.sol";
import { FarmConfig, IFarm } from "../src/core/interfaces/IFarm.sol";
import { DepositParams, DstInfo, IFarmManager, LZ_COMPOSE_OPT, LzConfig } from "../src/core/interfaces/IFarmManager.sol";
import { IRewardToken } from "../src/core/interfaces/IRewardToken.sol";
import { IOFT, MessagingFee, SendParam } from "../src/layerzero/IOFT.sol";

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Script, console } from "forge-std/Script.sol";

import { IBeacon } from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import { OFTComposeMsgCodec } from "../src/layerzero/OFTComposeMsgCodec.sol";
import { ERC20Mock } from "./testnet/MockERC20.sol";
import { TestScriptConfig } from "./testnet/TestnetConfig.sol";
// import { BaseSepTestnetConfig } from "./testnet/TestnetConfig.sol";

contract TestScript is Script, TestScriptConfig {
    uint256 internal OWNER_PRIVATE_KEY;

    function setUp() public {
        OWNER_PRIVATE_KEY = 0x1a978a4c18fa639d73c8aa9a289ac9a30eeadc1b7ccdfa7ddf128f280686e1c0; // uint256(vm.envBytes32("OWNER_PRIVATE_KEY"));
        owner = vm.addr(OWNER_PRIVATE_KEY);

        // BASE
        rewardToken = IRewardToken(address(0xC0AF63f4E6aC37F0f7Ff584fDc471a6E4979a12F));
        farmManager = IFarmManager(address(0x6809D58D6Be5a5bE44b43E8270F1AE9C21AE0F4f));
        memeAsset = ERC20Mock(address(0x96eb59D09174Efbb1f1A5cF8a522b3AEC64A52E7));
        memeFarm = IFarm(address(0xd3e3bb7e30a169B9D2F1831d705B0c067628FbD2));
    }

    function run() public {
        vm.startBroadcast(OWNER_PRIVATE_KEY);
        // memeAsset.approve(address(farmManager), type(uint256).max);
        // DepositParams memory depositParams = DepositParams({
        //   farm: memeFarm,
        //   amount: 200e18,
        //   receiver: owner
        // });
        // farmManager.depositERC20(depositParams);
        // uint256 reward = farmManager.previewReward(memeFarm, owner);

        // uint256 reward = memeFarm.previewReward(owner);
        // console.log("Preview reward: %d", reward);

        // uint256 totalShares = memeFarm.totalShares();
        // console.log("Total shares: %d", totalShares);
        // uint256 shares = memeFarm.shares(owner);
        // console.log("Shares: %d", shares);

        // uint256 lastRewardPerToken = memeFarm.lastRewardPerToken();
        // console.log("Last reward per token: %d", lastRewardPerToken);

        // uint256 pendingReward = farmManager.getPendingReward(memeFarm, owner);
        // console.log("Pending reward: %d", pendingReward);

        // bool isClaimable = farmManager.isClaimable(memeFarm);
        // console.log("Is claimable: %d", isClaimable);

        // uint256 rewardTokenBalance = rewardToken.balanceOf(owner);
        // console.log("Reward token balance: %d", rewardTokenBalance);

        // uint256 memeAssetBalance = memeAsset.balanceOf(owner);
        // console.log("memeAsset balance: %d", memeAssetBalance);

        // uint256 targetAmt = 2e18;
        // // rewardToken.mint(owner, targetAmt);

        // SendParam memory sendParam = formatDepositLzSendParam(owner, targetAmt, EXTRA_OPTIONS);
        // console.log("dstEid: %d", sendParam.dstEid);
        // MessagingFee memory expectFee = rewardToken.quoteSend(sendParam, false);

        // console.log("Expect fee:");
        // console.log("  - nativeFee: %d", expectFee.nativeFee);
        // console.log("  - lzTokenFee: %d", expectFee.lzTokenFee);
        // console.log("RefundAddress: %s", address(0xb031931f4A6AB97302F2b931bfCf5C81A505E4c2));
        // rewardToken.send{ value: expectFee.nativeFee }(sendParam, expectFee, 0xb031931f4A6AB97302F2b931bfCf5C81A505E4c2);

        // SendParam memory sendParam2 = formatDepositLzSendParam(owner, targetAmt, EXTRA_OPTIONS);
        // MessagingFee memory expectFee2 = rewardToken.quoteSend(sendParam2, false);
        // rewardToken.send{ value: expectFee2.nativeFee }(sendParam2, expectFee2, 0xb031931f4A6AB97302F2b931bfCf5C81A505E4c2);
        // uint256 rewardAmt = 1e18;

        // ClaimAndStakeParams memory claimAndStakeParams = ClaimAndStakeParams({
        //   farm: memeFarm,
        //   amount: 10e18,
        //   receiver: owner
        // });
        // farmManager.claimAndStake(claimAndStakeParams);

        // ClaimAndStakeCrossChainParams memory claimAndStakeParamsCrossChain = ClaimAndStakeCrossChainParams({
        //     farm: memeFarm,
        //     amount: targetAmt,
        //     receiver: owner,
        //     extraOptions: EXTRA_OPTIONS
        // });
        // farmManager.claimAndStakeCrossChain{ value: 418001915871002 }(claimAndStakeParamsCrossChain);
        // uint256 balance = rewardToken.balanceOf(owner);
        // console.log("Reward token balance: %d", balance);
        // rewardToken.mint(owner, 1000e18);

        // uint32 dstEid = 40_231;
        // uint256 targetAmt = 1e18;
        // SendParam memory sendParam = formatSimpleSendParam(dstEid, owner, targetAmt, hex"00030100110100000000000000000000000000030d40");
        // MessagingFee memory expectFee = rewardToken.quoteSend(sendParam, false);
        // rewardToken.send{ value: expectFee.nativeFee }(sendParam, expectFee, address(0x000000000000000000000000b4bb342294fe7d0d2ebdd894498b27bba13d5f1b));

        vm.stopBroadcast();
    }
}
