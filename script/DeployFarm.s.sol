// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IFarm } from "../src/core/interfaces/IFarm.sol";
import { IFarmManager } from "../src/core/interfaces/IFarmManager.sol";

import { Script, console } from "forge-std/Script.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {
    DeployFarmConfig,
    FARM_MANAGER_ADDRESS,
    REWARD_FARM_ADDRESS,
    UNDERLYING_ASSET_ADDRESS
} from "./DeployFarmConfig.sol";

contract DeploySetupScript is Script, DeployFarmConfig {
    uint256 internal OWNER_PRIVATE_KEY;
    IFarmManager farmManager;
    IFarm rewardFarm;
    IERC20 underlyingAsset;

    function setUp() public {
        OWNER_PRIVATE_KEY = uint256(vm.envBytes32("OWNER_PRIVATE_KEY"));
        farmManager = IFarmManager(FARM_MANAGER_ADDRESS);
        rewardFarm = IFarm(REWARD_FARM_ADDRESS);
        underlyingAsset = IERC20(UNDERLYING_ASSET_ADDRESS);
    }

    function run() public {
        vm.startBroadcast(OWNER_PRIVATE_KEY);

        // deploy farm
        IFarm farm = IFarm(address(farmManager.createFarm(underlyingAsset, FARM_CONFIG)));

        vm.stopBroadcast();

        console.log("Deployed contracts:");
        console.log("farm:", address(farm));
    }
}
