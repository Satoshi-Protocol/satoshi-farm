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
import { ArbSepTestnetConfig, TestScriptConfig } from "./testnet/TestnetConfig.sol";

// import { BaseSepTestnetConfig } from "./testnet/TestnetConfig.sol";
contract TestArbScript is Script, TestScriptConfig {
    uint256 internal OWNER_PRIVATE_KEY;

    function setUp() public {
        OWNER_PRIVATE_KEY = 0x1a978a4c18fa639d73c8aa9a289ac9a30eeadc1b7ccdfa7ddf128f280686e1c0; // uint256(vm.envBytes32("DEPLOYER_PRIVATE_KEY"));
        owner = vm.addr(OWNER_PRIVATE_KEY);

        // ARB
        rewardToken = IRewardToken(address(0x59fdaB9956C5Dc85f2b9ceC31551cAb6f9C3897D));
        farmManager = IFarmManager(address(0x575BEFDE27d08364078eb5409ACdCeAfEaB92e3A));
        memeAsset = ERC20Mock(address(0x2B9EF421A58762568cd2547284C4b8C9650ED0Fe));
        memeFarm = IFarm(address(0x2D5B46D9F85Bcd14AF4376D9D1472151A85427a5));
    }

    function run() public {
        vm.startBroadcast(OWNER_PRIVATE_KEY);
        console.log("owner: %s", owner);
        memeAsset.mint(owner, 100_000_000e18);
        uint256 memeAssetBalance = memeAsset.balanceOf(owner);
        console.log("memeAsset balance: %d", memeAssetBalance);

        memeAsset.approve(address(farmManager), type(uint256).max);
        DepositParams memory depositParams = DepositParams({ farm: memeFarm, amount: 10e18, receiver: owner });
        farmManager.depositERC20(depositParams);

        // uint256 reward = farmManager.previewReward(memeFarm, owner);
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

        // uint256 rewardTokenBlance = rewardToken.balanceOf(owner);
        // console.log("Reward token balance: %d", rewardTokenBlance);

        // uint256 targetAmt = 1490162000000000001 / 10**12 * 10**12;
        // console.log("targetAmt: %d", targetAmt);
        // SendParam memory sendParam = formatDepositLzSendParam(owner, targetAmt, EXTRA_OPTIONS);
        // console.log("dstEid: %d", sendParam.dstEid);
        // console.log("amount: %s", sendParam.amountLD);
        // console.log("dstFarmManagerBytes32: %s");
        // console.logBytes32(sendParam.to);

        // console.log("dstEid: %d", sendParam.dstEid);
        // MessagingFee memory expectFee = rewardToken.quoteSend(sendParam, false);
        // console.log("expectFee: %s", expectFee.nativeFee);
        // rewardToken.mint(owner, 1000e18);
        // uint32 dstEid = 40_245;
        // uint256 targetAmt = 1e18;
        // SendParam memory sendParam = formatSimpleSendParam(dstEid, owner, targetAmt, hex"00030100110100000000000000000000000000030d40");
        // MessagingFee memory expectFee = rewardToken.quoteSend(sendParam, false);
        // rewardToken.send{ value: expectFee.nativeFee }(sendParam, expectFee, address(0x000000000000000000000000b4bb342294fe7d0d2ebdd894498b27bba13d5f1b));

        // ERC20Mock ai16z = new ERC20Mock("AI16Z", "AI16Z");
        // ai16z.mint(owner, 1000e18);
        // console.log("AI16Z balance: %d", ai16z.balanceOf(owner));
        // console.log("AI16Z Address: %s", address(ai16z));

        // DstInfo memory dstInfo = DstInfo({
        //     dstEid: 40_245,
        //     dstFarmManagerBytes32: bytes32(0x000000000000000000000000b4bb342294fe7d0d2ebdd894498b27bba13d5f1b)
        // });
        // farmManager.updateDstInfo()

        // rewardToken.mint(owner, 1000e18);
        // uint256 rewardAmt = 1e18;

        // showRewardFarmInfo();

        // ClaimAndStakeParams memory claimAndStakeParams = ClaimAndStakeParams({
        //   farm: memeFarm,
        //   amount: 10e18,
        //   receiver: owner
        // });
        // farmManager.claimAndStake(claimAndStakeParams);

        // ClaimAndStakeCrossChainParams memory claimAndStakeParamsCrossChain = ClaimAndStakeCrossChainParams({
        //   farm: memeFarm,
        //   amount: targetAmt,
        //   receiver: owner,
        //   extraOptions: EXTRA_OPTIONS
        // });
        // farmManager.claimAndStakeCrossChain{
        //   value: expectFee.nativeFee
        // }(claimAndStakeParamsCrossChain);

        vm.stopBroadcast();
    }
}
