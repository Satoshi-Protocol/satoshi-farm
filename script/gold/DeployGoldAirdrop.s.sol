// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { GoldAirdrop } from "../../src/Gold/GoldAirdrop.sol";
import { IGold } from "../../src/Gold/interfaces/IGold.sol";
import { IGoldAirdrop } from "../../src/Gold/interfaces/IGoldAirdrop.sol";
import { END_TIME, GOLD_ADDRESS, MERKLE_ROOT, START_TIME } from "./DeployGoldAirdropConfig.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Script, console } from "forge-std/Script.sol";

contract DeployGoldAirdropScript is Script {
    uint256 internal DEPLOYER_PRIVATE_KEY;
    IGold gold;
    IGoldAirdrop goldAirdrop;

    function setUp() public {
        DEPLOYER_PRIVATE_KEY = uint256(vm.envBytes32("DEPLOYER_PRIVATE_KEY"));
        gold = IGold(GOLD_ADDRESS);
    }

    function run() public {
        vm.startBroadcast(DEPLOYER_PRIVATE_KEY);

        // deploy gold airdrop contract
        address goldAirdropImplAddr = address(new GoldAirdrop());
        bytes memory data = abi.encodeCall(GoldAirdrop.initialize, (GOLD_ADDRESS, START_TIME, END_TIME, MERKLE_ROOT));
        goldAirdrop = IGoldAirdrop(address(new ERC1967Proxy(goldAirdropImplAddr, data)));

        gold.rely(address(goldAirdrop));

        vm.stopBroadcast();

        console.log("Deployed gold airdrop:");
        console.log("gold airdrop address:", address(goldAirdrop));
    }
}
