// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Farm } from "../src/core/Farm.sol";

import { FarmManager } from "../src/core/FarmManager.sol";
import { FarmConfig, IFarm } from "../src/core/interfaces/IFarm.sol";
import { DstInfo, IFarmManager, LzConfig } from "../src/core/interfaces/IFarmManager.sol";
import { IRewardToken } from "../src/core/interfaces/IRewardToken.sol";

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Script, console } from "forge-std/Script.sol";

import { IBeacon } from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import { DeploySetupConfig, REWARD_TOKEN_ADDRESS } from "./DeploySetupConfig.sol";

contract DeploySetupScript is Script, DeploySetupConfig {
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

        rewardToken = IRewardToken(REWARD_TOKEN_ADDRESS);
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
        bytes memory data =
            abi.encodeCall(FarmManager.initialize, (farmBeacon, rewardToken, DST_INFO, LZ_CONFIG, REWARD_FARM_CONFIG));
        farmManager = IFarmManager(address(new ERC1967Proxy(address(farmManagerImpl), data)));

        vm.stopBroadcast();

        console.log("Deployed contracts:");
        console.log("farmImpl:", address(farmImpl));
        console.log("farmManagerImpl:", address(farmManagerImpl));
        console.log("farmBeacon:", address(farmBeacon));
        console.log("farmManager:", address(farmManager));
        if (DST_INFO.dstEid == LZ_CONFIG.eid) {
            (, IFarm rewardFarm,) = farmManager.dstInfo();
            console.log("deploy on primary chain");
            console.log("rewardFarm:", address(rewardFarm));
        }
    }
}
