// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Gold } from "../../src/Gold/Gold.sol";
import { IGold } from "../../src/Gold/interfaces/IGold.sol";
import { NAME, SYMBOL } from "./DeployGoldConfig.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Script, console } from "forge-std/Script.sol";

contract DeploySetupScript is Script {
    uint256 internal DEPLOYER_PRIVATE_KEY;
    IGold gold;

    function setUp() public {
        DEPLOYER_PRIVATE_KEY = uint256(vm.envBytes32("DEPLOYER_PRIVATE_KEY"));
    }

    function run() public {
        vm.startBroadcast(DEPLOYER_PRIVATE_KEY);

        // deploy gold token
        address goldImplAddr = address(new Gold());
        bytes memory data = abi.encodeCall(Gold.initialize, (NAME, SYMBOL));
        gold = IGold(address(new ERC1967Proxy(goldImplAddr, data)));

        vm.stopBroadcast();

        console.log("Deployed gold:");
        console.log("gold address:", address(gold));
    }
}
