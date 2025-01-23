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
import { DepositParams, DstInfo, IFarmManager, LzConfig } from "../src/core/interfaces/IFarmManager.sol";
import { IRewardToken } from "../src/core/interfaces/IRewardToken.sol";

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

    function setUp() public {
        DEPLOYER_PRIVATE_KEY = uint256(vm.envBytes32("DEPLOYER_PRIVATE_KEY"));
        deployer = vm.addr(DEPLOYER_PRIVATE_KEY);
        OWNER_PRIVATE_KEY = uint256(vm.envBytes32("OWNER_PRIVATE_KEY"));
        owner = vm.addr(OWNER_PRIVATE_KEY);

        // ARB
        rewardToken = IRewardToken(address(0x1e1d7C76Bd273d60E756322A8Ea9A1914327fa13));
        farmManager = IFarmManager(address(0x6df05337F818be2cd87A0E8ee63c5e55D7632B56));
        memeAsset = ERC20Mock(address(0x2B9EF421A58762568cd2547284C4b8C9650ED0Fe));
        memeFarm = IFarm(address(0xF31c8Ca92beC723af97839b181E36b2B2B514256));
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

        uint256 rewardTokenBlance = rewardToken.balanceOf(deployer);
        console.log("Reward token balance: %d", rewardTokenBlance);
        // rewardToken.mint(deployer, 1000e18);
        // uint256 rewardAmt = 1e18;

        showRewardFarmInfo();

        // uint256 claimAmt = 1e18;
        // ClaimAndStakeParams memory claimAndStakeParams = ClaimAndStakeParams({
        //   farm: memeFarm,
        //   amount: 10e18,
        //   receiver: deployer
        // });
        // farmManager.claimAndStake(claimAndStakeParams);

        // ClaimAndStakeCrossChainParams memory claimAndStakeParamsCrossChain = ClaimAndStakeCrossChainParams({
        //   farm: memeFarm,
        //   amount: claimAmt,
        //   receiver: deployer,
        //   extraOptions: hex"00030100110100000000000000000000000000030d40010013030000000000000000000000000000002dc6c0"
        // });
        // farmManager.claimAndStakeCrossChain{
        //   value: 455661193185754
        // }(claimAndStakeParamsCrossChain);

        vm.stopBroadcast();
    }

    function showRewardFarmInfo() public {
        (, IFarm rewardFarm,) = farmManager.dstInfo();
        console.log("====== Reward farm ======");
        console.log("Preview reward: %d", rewardFarm.previewReward(deployer));
        console.log("Total shares: %d", rewardFarm.totalShares());
        console.log("Shares: %d", rewardFarm.shares(deployer));
        console.log("Last reward per token: %d", rewardFarm.lastRewardPerToken());
        console.log("Pending reward: %d", farmManager.getPendingReward(rewardFarm, deployer));
        console.log("Is claimable: %d", farmManager.isClaimable(rewardFarm));
    }
}
