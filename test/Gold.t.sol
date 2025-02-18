// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IFarm } from "../src/core/interfaces/IFarm.sol";

import { FarmConfig } from "../src/core/interfaces/IFarm.sol";
import {
    ClaimAndStakeParams,
    DepositParams,
    DstInfo,
    ExecuteClaimParams,
    IFarmManager,
    IFarmManager,
    LzConfig,
    RequestClaimParams,
    StakePendingClaimParams,
    WhitelistConfig,
    WithdrawParams
} from "../src/core/interfaces/IFarmManager.sol";
import { BaseTest } from "./utils/BaseTest.sol";
import { DeployBase } from "./utils/DeployBase.sol";
import { DEPLOYER, OWNER, TestConfig } from "./utils/TestConfig.sol";

import { IGold } from "../src/Gold/interfaces/IGold.sol";
import { IGoldAirdrop } from "../src/Gold/interfaces/IGoldAirdrop.sol";

import { MerkleLib } from "./utils/MerkleLib.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "forge-std/console.sol";

contract GoldTest is BaseTest {
    IGold gold;
    IGoldAirdrop goldAirdrop;

    address payable deployer = payable(DEPLOYER);

    address payable user1;
    address payable user2;
    address payable user3;
    uint256 totalUsers = 3;
    uint256 airdropAmt = 10 ether;
    bytes32[] hashList = new bytes32[](3);

    function setUp() public override {
        super.setUp();
        user1 = _createUser("user1");
        user2 = _createUser("user2");
        user3 = _createUser("user3");
        uint256 mintAmt = totalUsers * airdropAmt;

        (gold, goldAirdrop) = _deployGold(DEPLOYER);

        vm.startPrank(DEPLOYER);

        gold.rely(DEPLOYER);
        gold.mint(address(goldAirdrop), mintAmt);

        // bytes32[] memory hashList = new bytes32[](3);
        hashList[0] = keccak256(abi.encode(user1, airdropAmt));
        hashList[1] = keccak256(abi.encode(user2, airdropAmt));
        hashList[2] = keccak256(abi.encode(user3, airdropAmt));

        (bytes32 root) = MerkleLib.prepareMerkleRoot(hashList);
        goldAirdrop.setMerkleRoot(root);

        vm.stopPrank();
    }

    function test_airdrop_time() public {
        vm.startPrank(DEPLOYER);
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + 1000;

        goldAirdrop.setAirdropTime(startTime, endTime);

        // check time valid
        assert(goldAirdrop.startTime() == startTime);
        assert(goldAirdrop.endTime() == endTime);
        assertEq(goldAirdrop.isValidTime(), true);

        // check time invalid
        vm.warp(endTime + 1);
        assertEq(goldAirdrop.isValidTime(), false);

        vm.stopPrank();
    }

    function test_claim() public {
        vm.startPrank(user1);

        uint256 beforeBalance = gold.balanceOf(user1);

        bytes32[] memory proof = MerkleLib.prepareMerkleProof(hashList, 0);
        goldAirdrop.claim(user1, airdropAmt, proof);

        uint256 afterBalance = gold.balanceOf(user1);

        assert(afterBalance == beforeBalance + airdropAmt);

        bytes32 leaf = keccak256(abi.encode(user1, airdropAmt));
        bool isClaimed = goldAirdrop.isClaimed(leaf);
        assert(isClaimed == true);

        vm.stopPrank();
    }
}
