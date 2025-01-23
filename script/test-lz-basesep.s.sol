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
import { MessagingFee, SendParam } from "../src/layerzero/IOFT.sol";

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Script, console } from "forge-std/Script.sol";

import { IBeacon } from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import { ERC20Mock } from "./testnet/MockERC20.sol";
import { ArbSepTestnetConfig } from "./testnet/TestnetConfig.sol";

// import { BaseSepTestnetConfig } from "./testnet/TestnetConfig.sol";

contract TestScript is Script, ArbSepTestnetConfig {
    uint256 internal DEPLOYER_PRIVATE_KEY;
    uint256 internal OWNER_PRIVATE_KEY;
    address public deployer;
    address public owner;

    ERC20Mock memeAsset;
    IFarm memeFarm;
    IFarmManager farmManager;
    IRewardToken rewardToken;
    // IFarm rewardFarm;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes constant EXTRA_OPTIONS =
        hex"00030100110100000000000000000000000000030d40010013030000000000000000000000000000002dc6c0";
    //   bytes constant EXTRA_OPTIONS_LOW_GAS = hex"00030100110100000000000000000000000000030d4001001303000000000000000000000000000000004e20";

    function setUp() public {
        DEPLOYER_PRIVATE_KEY = uint256(vm.envBytes32("DEPLOYER_PRIVATE_KEY"));
        deployer = vm.addr(DEPLOYER_PRIVATE_KEY);
        OWNER_PRIVATE_KEY = uint256(vm.envBytes32("OWNER_PRIVATE_KEY"));
        owner = vm.addr(OWNER_PRIVATE_KEY);

        // BASE
        rewardToken = IRewardToken(address(0x819591a4e747212EDA0880DD2F171B582Ce4149B));
        farmManager = IFarmManager(address(0xD0B720593fcC19618340F5714693e57bb9a0c31D));
        memeAsset = ERC20Mock(address(0xdb852D7e63F679ABaa8AF75F3EedF5f500Fa6aef));
        memeFarm = IFarm(address(0xC57f6A099b1F89754239dd1737aDB3Cb4450170F));
    }

    function run() public {
        vm.startBroadcast(DEPLOYER_PRIVATE_KEY);
        // memeAsset.approve(address(farmManager), type(uint256).max);
        // DepositParams memory depositParams = DepositParams({
        //   farm: memeFarm,
        //   amount: 1000e18,
        //   receiver: deployer
        // });
        // farmManager.depositERC20(depositParams);
        // uint256 reward = farmManager.previewReward(memeFarm, deployer);

        uint256 reward = memeFarm.previewReward(deployer);
        console.log("Preview reward: %d", reward);

        uint256 totalShares = memeFarm.totalShares();
        console.log("Total shares: %d", totalShares);
        uint256 shares = memeFarm.shares(deployer);
        console.log("Shares: %d", shares);

        uint256 lastRewardPerToken = memeFarm.lastRewardPerToken();
        console.log("Last reward per token: %d", lastRewardPerToken);

        uint256 pendingReward = farmManager.getPendingReward(memeFarm, deployer);
        console.log("Pending reward: %d", pendingReward);

        bool isClaimable = farmManager.isClaimable(memeFarm);
        console.log("Is claimable: %d", isClaimable);

        uint256 rewardTokenBalance = rewardToken.balanceOf(deployer);
        console.log("Reward token balance: %d", rewardTokenBalance);

        uint256 targetAmt = 3e18;
        rewardToken.mint(deployer, targetAmt);

        /**
         * Manaualy cross chain stake
         */
        SendParam memory sendParam = formatDepositLzSendParam(deployer, targetAmt, EXTRA_OPTIONS);
        // console.log("composeMsg");
        // console.logBytes(sendParam.composeMsg);

        MessagingFee memory expectFee = rewardToken.quoteSend(sendParam, false);
        rewardToken.send{ value: expectFee.nativeFee }(sendParam, expectFee, 0xb031931f4A6AB97302F2b931bfCf5C81A505E4c2);

        // uint256 rewardAmt = 1e18;
        // ClaimAndStakeParams memory claimAndStakeParams = ClaimAndStakeParams({
        //   farm: memeFarm,
        //   amount: 10e18,
        //   receiver: deployer
        // });
        // farmManager.claimAndStake(claimAndStakeParams);

        ClaimAndStakeCrossChainParams memory claimAndStakeParamsCrossChain = ClaimAndStakeCrossChainParams({
            farm: memeFarm,
            amount: targetAmt,
            receiver: deployer,
            extraOptions: EXTRA_OPTIONS
        });
        farmManager.claimAndStakeCrossChain{ value: expectFee.nativeFee }(claimAndStakeParamsCrossChain);

        vm.stopBroadcast();
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
}
