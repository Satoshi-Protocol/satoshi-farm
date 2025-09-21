// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Farm } from "../src/core/Farm.sol";
import { FarmManager } from "../src/core/FarmManager.sol";
import { FarmConfig, IFarm } from "../src/core/interfaces/IFarm.sol";
import { DstInfo, IFarmManager } from "../src/core/interfaces/IFarmManager.sol";
import { IRewardToken } from "../src/core/interfaces/IRewardToken.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Script, console2 } from "forge-std/Script.sol";

contract UpdateFarmConfigScript is Script {
    address constant FARM_MANAGER_ADDRESS = 0x19B4Dd214775c415af2e178e89ccD9d7A3F21941;
    address constant REWARD_FARM_ADDRESS = 0x2963eD8a43fD199B1aAdB1B1E36A10dfDbf416E4;
    uint32 constant TGE_TIMESTAMP = 1_758_531_600;
    FarmConfig internal rewardFarmConfig = FarmConfig({
        depositCap: type(uint256).max,
        depositCapPerUser: type(uint256).max,
        depositStartTime: 1_748_440_800,
        depositEndTime: type(uint32).max,
        rewardRate: 5_067_708_333_333_333_333,
        rewardStartTime: 1_748_440_800,
        rewardEndTime: type(uint32).max,
        claimStartTime: TGE_TIMESTAMP,
        claimEndTime: type(uint32).max,
        claimDelayTime: 0,
        withdrawFee: 0,
        withdrawEnabled: false,
        forceClaimEnabled: false
    });
    uint256 internal OWNER_PRIVATE_KEY;
    address public owner;

    IFarmManager farmManager;
    IFarm public farm;

    function setUp() public {
        OWNER_PRIVATE_KEY = uint256(vm.envBytes32("OWNER_PRIVATE_KEY"));
        owner = vm.addr(OWNER_PRIVATE_KEY);

        farmManager = IFarmManager(FARM_MANAGER_ADDRESS);
        farm = IFarm(REWARD_FARM_ADDRESS);
    }

    function run() public {
        vm.startBroadcast(OWNER_PRIVATE_KEY);

        farmManager.updateFarmConfig(farm, rewardFarmConfig);

        // check updated config
        FarmConfig memory updatedConfig = farmManager.getFarmConfig(farm);
        require(updatedConfig.depositStartTime == rewardFarmConfig.depositStartTime, "Deposit start time mismatch");
        require(updatedConfig.rewardRate == rewardFarmConfig.rewardRate, "Reward rate mismatch");
        require(updatedConfig.claimStartTime == rewardFarmConfig.claimStartTime, "Claim start time mismatch");
        require(updatedConfig.forceClaimEnabled == rewardFarmConfig.forceClaimEnabled, "Force claim enabled mismatch");
        require(updatedConfig.withdrawEnabled == rewardFarmConfig.withdrawEnabled, "Withdraw enabled mismatch");
        require(updatedConfig.withdrawFee == rewardFarmConfig.withdrawFee, "Withdraw fee mismatch");
        require(updatedConfig.claimDelayTime == rewardFarmConfig.claimDelayTime, "Claim delay time mismatch");
        require(updatedConfig.depositEndTime == rewardFarmConfig.depositEndTime, "Deposit end time mismatch");
        require(updatedConfig.rewardEndTime == rewardFarmConfig.rewardEndTime, "Reward end time mismatch");
        require(updatedConfig.claimEndTime == rewardFarmConfig.claimEndTime, "Claim end time mismatch");
        require(updatedConfig.depositCap == rewardFarmConfig.depositCap, "Deposit cap mismatch");
        require(updatedConfig.depositCapPerUser == rewardFarmConfig.depositCapPerUser, "Deposit cap per user mismatch");
        vm.stopBroadcast();
    }
}
