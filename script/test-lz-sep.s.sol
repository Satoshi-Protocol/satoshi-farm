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

import { ERC20Mock } from "./testnet/MockERC20.sol";
import { TestScriptConfig, ArbSepTestnetConfig } from "./testnet/TestnetConfig.sol";
import { OFTComposeMsgCodec } from "../src/layerzero/OFTComposeMsgCodec.sol";

// import { BaseSepTestnetConfig } from "./testnet/TestnetConfig.sol";
contract TestSepScript is Script, TestScriptConfig {
    uint256 internal OWNER_PRIVATE_KEY;

    function setUp() public {
        OWNER_PRIVATE_KEY = 0x1a978a4c18fa639d73c8aa9a289ac9a30eeadc1b7ccdfa7ddf128f280686e1c0; // uint256(vm.envBytes32("DEPLOYER_PRIVATE_KEY"));
        owner = vm.addr(OWNER_PRIVATE_KEY);

        // SEP
        rewardToken = IRewardToken(address(0x44621f077464a41849E2e3E972e07CBF6999c508));
        farmManager = IFarmManager(address(0xefd8C52b3aF1b142FBCEb7EA0d3cddc82058e3F8));
        memeAsset = ERC20Mock(address(0x59fdaB9956C5Dc85f2b9ceC31551cAb6f9C3897D));
        memeFarm = IFarm(address(0xC345EbACd0bc349B2d1D05Cd40c774fdeE6524F6));
    }

    function run() public {
        vm.startBroadcast(OWNER_PRIVATE_KEY);
        console.log("owner: %s", owner);
        // memeAsset.mint(owner, 100000000e18);
        // uint256 memeAssetBalance = memeAsset.balanceOf(owner);
        // console.log("memeAsset balance: %d", memeAssetBalance);
        // bool valid = farmManager.isValidFarm(memeFarm);
        // console.log("Is valid farm: %d", valid);
        // memeAsset.approve(address(farmManager), type(uint256).max);
        // DepositParams memory depositParams = DepositParams({
        //   farm: memeFarm,
        //   amount: 100e18,
        //   receiver: owner
        // });
        // farmManager.depositERC20(depositParams);

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

        // uint256 targetAmt = 149016000000000000 / 10**12 * 10**12;
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
        // uint32 dstEid = 40_231;
        // uint256 targetAmt = 1e18;
        // SendParam memory sendParam = formatSimpleSendParam(dstEid, owner, targetAmt, hex"00030100110100000000000000000000000000030d40");
        // MessagingFee memory expectFee = rewardToken.quoteSend(sendParam, false);
        // rewardToken.send{ value: expectFee.nativeFee }(sendParam, expectFee, address(0x000000000000000000000000b4bb342294fe7d0d2ebdd894498b27bba13d5f1b));
        
        
        
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


        ERC20Mock PEPE = new ERC20Mock("PEPE", "PEPE");
        PEPE.mint(owner, 1000e18);
        console.log("PEPE balance: %d", PEPE.balanceOf(owner));
        console.log("PEPE Address: %s", address(PEPE));

        vm.stopBroadcast();
    }

}
