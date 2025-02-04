// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ERC20Mock } from "./MockERC20.sol";

contract DeployMockERC20Script is Script {
    uint256 internal DEPLOYER_PRIVATE_KEY;
    IERC20 mockERC20;

    function setUp() public {
        DEPLOYER_PRIVATE_KEY = uint256(vm.envBytes32("DEPLOYER_PRIVATE_KEY"));
    }

    function run() public {
        vm.startBroadcast(DEPLOYER_PRIVATE_KEY);

        // deploy mock ERC20
        mockERC20 = new ERC20Mock("Mock ERC20", "MERC");

        vm.stopBroadcast();

        console.log("Deployed mock ERC20:");
        console.log("mockERC20:", address(mockERC20));
    }
}
