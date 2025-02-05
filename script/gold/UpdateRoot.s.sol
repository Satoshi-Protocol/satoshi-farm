// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IGoldAirdrop } from "../../src/Gold/interfaces/IGoldAirdrop.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Script, console } from "forge-std/Script.sol";

address constant GOLD_AIRDROP_ADDRESS = 0x633deE93C7bFD49757F806f73338DAEF4BF59De9;
bytes32 constant MERKLE_ROOT = 0x0;

contract UpdateRootScript is Script {
    uint256 internal OWNER_PRIVATE_KEY;
    IGoldAirdrop goldAirdrop;

    function setUp() public {
        OWNER_PRIVATE_KEY = uint256(vm.envBytes32("OWNER_PRIVATE_KEY"));
        goldAirdrop = IGoldAirdrop(GOLD_AIRDROP_ADDRESS);
    }

    function run() public {
        vm.startBroadcast(OWNER_PRIVATE_KEY);

        // update merkle root
        goldAirdrop.setMerkleRoot(MERKLE_ROOT);

        vm.stopBroadcast();
    }
}
