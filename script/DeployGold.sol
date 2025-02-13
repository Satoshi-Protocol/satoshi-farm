// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IGold } from "../src/Gold/interfaces/IGold.sol";
import { IGoldAirdrop } from "../src/Gold/interfaces/IGoldAirdrop.sol";
import { Gold } from "../src/Gold/Gold.sol";
import { GoldAirdrop } from "../src/Gold/GoldAirdrop.sol";

import { Script, console } from "forge-std/Script.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployFarmConfig, FARM_MANAGER_ADDRESS, UNDERLYING_ASSET_ADDRESS } from "./DeployFarmConfig.sol";

contract DeployGoldScript is Script {
    uint256 internal OWNER_PRIVATE_KEY;
    string internal GOLD_NAME = "Test Gold";
    string internal GOLD_SYMBOL = "GOLD.t";
    uint256 internal GOLD_AIRDROP_START_TIME = block.timestamp;
    uint256 internal GOLD_AIRDROP_END_TIME = type(uint256).max;

    function setUp() public {
        OWNER_PRIVATE_KEY = uint256(vm.envBytes32("OWNER_PRIVATE_KEY"));
    }

    function run() public {
        (address goldImpl, IGold _gold, address goldAirdropImpl, IGoldAirdrop _goldAirdrop) = _deployGold(OWNER_PRIVATE_KEY);

        console.log("Deployer address:", vm.addr(OWNER_PRIVATE_KEY));
        console.log("GoldImpl deployed at:", goldImpl);
        console.log("Gold deployed at:", address(_gold));
        console.log("GoldAirdropImpl deployed at:", goldAirdropImpl);
        console.log("GoldAirdrop deployed at:", address(_goldAirdrop));
    }


    function _deployGold(uint256 deployerPriv) internal returns (address goldImpl, IGold _gold, address goldAirdropImpl, IGoldAirdrop _goldAirdrop) {
        vm.startBroadcast(deployerPriv);

        goldImpl = address(new Gold());
        bytes memory goldData =
            abi.encodeCall(Gold.initialize, (GOLD_NAME, GOLD_SYMBOL));
        _gold = IGold(address(new ERC1967Proxy(goldImpl, goldData)));

        goldAirdropImpl = address(new GoldAirdrop());
        bytes memory goldAirdropData =
            abi.encodeCall(GoldAirdrop.initialize, (address(_gold), GOLD_AIRDROP_START_TIME, GOLD_AIRDROP_END_TIME, bytes32(0)));
        _goldAirdrop = IGoldAirdrop(address(new ERC1967Proxy(goldAirdropImpl, goldAirdropData)));

        _gold.rely(address(_goldAirdrop));
        vm.stopBroadcast();
    }
}
