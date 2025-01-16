// // SPDX-License-Identifier: MIT
// pragma solidity >=0.8.0 <0.9.0;

// import { Farm } from "../src/Farm.sol";

// import { FarmManager } from "../src/FarmManager.sol";
// import { FarmConfig, IFarm } from "../src/interfaces/IFarm.sol";
// import { IFarmManager, DepositParams, RewardInfo, LzConfig } from "../src/interfaces/IFarmManager.sol";
// import { IRewardToken } from "../src/interfaces/IRewardToken.sol";

// import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
// import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import { Script, console } from "forge-std/Script.sol";

// import { IBeacon } from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
// import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

// import { ArbSepTestnetConfig } from "./testnet/TestnetConfig.sol";
// import { ERC20Mock } from "./testnet/MockERC20.sol";

// contract SyncStateTestnet is Script, ArbSepTestnetConfig {
//     uint256 internal DEPLOYER_PRIVATE_KEY;
//     uint256 internal OWNER_PRIVATE_KEY;
//     address public deployer;
//     address public owner;
//     IRewardToken rewardToken;
//     IFarmManager farmManager;
//     IFarm rewardFarm;

//     function setUp() public {
//         DEPLOYER_PRIVATE_KEY = uint256(vm.envBytes32("DEPLOYER_PRIVATE_KEY"));
//         deployer = vm.addr(DEPLOYER_PRIVATE_KEY);
//         OWNER_PRIVATE_KEY = uint256(vm.envBytes32("OWNER_PRIVATE_KEY"));
//         owner = vm.addr(OWNER_PRIVATE_KEY);
//         rewardToken = REWARD_INFO.rewardToken;
//         farmManager = IFarmManager(FARM_MANAGER_ADDRESS);
//     }

//     function run() public {
//         vm.startBroadcast(DEPLOYER_PRIVATE_KEY);
//         (
//             IRewardToken rewardToken,
//             uint32 dstEid,
//             IFarm dstRewardFarm,
//             bytes32 dstRewardManagerBytes32
//         ) = farmManager.rewardInfo();

//         vm.stopBroadcast();
//     }
// }
