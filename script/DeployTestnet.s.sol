// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { Farm } from "../src/Farm.sol";

import { FarmManager } from "../src/FarmManager.sol";
import { FarmConfig, IFarm } from "../src/interfaces/IFarm.sol";
import { DepositParams, DstInfo, IFarmManager, LzConfig } from "../src/interfaces/IFarmManager.sol";
import { IRewardToken } from "../src/interfaces/IRewardToken.sol";

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Script, console } from "forge-std/Script.sol";

import { IBeacon } from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import { ERC20Mock } from "./testnet/MockERC20.sol";
import { BaseSepTestnetConfig } from "./testnet/TestnetConfig.sol";

contract DeployTestnet is Script, BaseSepTestnetConfig {
    uint256 internal DEPLOYER_PRIVATE_KEY;
    uint256 internal OWNER_PRIVATE_KEY;
    address public deployer;
    address public owner;
    IRewardToken rewardToken;

    IFarm farmImpl;
    IFarmManager farmManagerImpl;
    IBeacon farmBeacon;
    IFarmManager farmManager;

    function setUp() public {
        DEPLOYER_PRIVATE_KEY = uint256(vm.envBytes32("DEPLOYER_PRIVATE_KEY"));
        deployer = vm.addr(DEPLOYER_PRIVATE_KEY);
        OWNER_PRIVATE_KEY = uint256(vm.envBytes32("OWNER_PRIVATE_KEY"));
        owner = vm.addr(OWNER_PRIVATE_KEY);
    }

    function run() public {
        vm.startBroadcast(DEPLOYER_PRIVATE_KEY);

        // deploy implementation contracts
        assert(farmImpl == IFarm(address(0)));
        assert(farmManagerImpl == IFarmManager(address(0)));

        farmImpl = new Farm();
        farmManagerImpl = new FarmManager();

        // deploy beacon contract
        assert(farmBeacon == UpgradeableBeacon(address(0))); // check if beacon contract is not deployed
        farmBeacon = new UpgradeableBeacon(address(farmImpl), owner);

        // deploy farm manager proxy
        bytes memory data = abi.encodeCall(
            FarmManager.initialize,
            (farmBeacon, IRewardToken(REWARD_TOKEN_ADDRESS), DST_INFO, LZ_CONFIG, REWARD_FARM_CONFIG)
        );
        farmManager = IFarmManager(address(new ERC1967Proxy(address(farmManagerImpl), data)));

        ERC20Mock memeAsset = new ERC20Mock("ARB_MEME", "ARB_MEME");
        memeAsset.mint(deployer, 10_000_000e18);
        IFarm memeFarm = IFarm(address(farmManager.createFarm(memeAsset, REWARD_FARM_CONFIG)));

        memeAsset.approve(address(farmManager), type(uint256).max);
        farmManager.depositERC20(DepositParams(memeFarm, 1_000_000e18, deployer));

        vm.stopBroadcast();
        console.log("== Deployed contracts ==");
        console.log("rewardToken:", address(REWARD_TOKEN_ADDRESS));
        console.log("farmImpl:", address(farmImpl));
        console.log("farmManagerImpl:", address(farmManagerImpl));
        console.log("farmBeacon:", address(farmBeacon));
        console.log("farmManager:", address(farmManager));
        console.log("== Meme contracts ==");
        console.log("memeAsset:", address(memeAsset));
        console.log("memeFarm:", address(memeFarm));
        if (DST_INFO.dstEid == LZ_CONFIG.eid) {
            (uint32 dstEid, IFarm dstRewardFarm, bytes32 dstRewardFarmBytes32) = farmManager.dstInfo();
            console.log("== DstInfo ==");
            console.log("dstEid:", dstEid);
            console.log("dstRewardFarm:", address(dstRewardFarm));
            console.log("dstRewardFarmBytes32:");
            console.logBytes32(dstRewardFarmBytes32);
        }
    }
}
