// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Farm } from "../src/core/Farm.sol";

import { FarmManager } from "../src/core/FarmManager.sol";
import { FarmConfig, IFarm, WhitelistConfig } from "../src/core/interfaces/IFarm.sol";
import { DepositParams, DstInfo, IFarmManager, LzConfig } from "../src/core/interfaces/IFarmManager.sol";
import { IRewardToken } from "../src/core/interfaces/IRewardToken.sol";

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Script, console } from "forge-std/Script.sol";

import { IBeacon } from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import { ERC20Mock } from "./testnet/MockERC20.sol";
import { ArbSepTestnetConfig, BaseSepTestnetConfig, TestnetConfigHelper } from "./testnet/TestnetConfig.sol";

contract DeployTestnet is Script, BaseSepTestnetConfig {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
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
            (farmBeacon, IRewardToken(REWARD_TOKEN_ADDRESS), DST_INFO, LZ_CONFIG,TestnetConfigHelper.getRewardFarmConfig())
        );
        farmManager = IFarmManager(address(new ERC1967Proxy(address(farmManagerImpl), data)));

        address[] memory whitelistAddresses = new address[](2);
        whitelistAddresses[0] = deployer;
        whitelistAddresses[1] = address(0xF3CFa03786e374e54b5A87c4043d03ed789faC78);
        (bytes32 whitelistRoot, bytes32[] memory whitelist) = TestnetConfigHelper.prepareWhitelist(whitelistAddresses);

        ERC20Mock memeAsset = new ERC20Mock("MEME", "MEME");
        memeAsset.mint(whitelistAddresses[0], 10_000_000e18);
        memeAsset.mint(whitelistAddresses[1], 10_000_000e18);
        IFarm memeFarm1 =
            IFarm(address(farmManager.createFarm(memeAsset, TestnetConfigHelper.getMemeFarmConfigWithWhitelist())));

        IFarm memeFarm2 =
            IFarm(address(farmManager.createFarm(memeAsset, TestnetConfigHelper.getMemeFarmConfigWith10000Cap500per())));

        IFarm memeFarm3 =
            IFarm(address(farmManager.createFarm(memeAsset, TestnetConfigHelper.getMemeFarmConfigWith10000Cap500per())));

        IFarm memeFarm4 =
            IFarm(address(farmManager.createFarm(memeAsset, TestnetConfigHelper.getMemeFarmConfigWithNoCap())));

        farmManager.updateWhitelistConfig(memeFarm1, WhitelistConfig({ enabled: true, merkleRoot: whitelistRoot }));
        farmManager.updateWhitelistConfig(memeFarm3, WhitelistConfig({ enabled: true, merkleRoot: whitelistRoot }));

        memeAsset.approve(address(farmManager), type(uint256).max);
        // farmManager.depositERC20(DepositParams(memeFarm1, 100 ether, deployer));
        farmManager.depositERC20(DepositParams(memeFarm2, 100 ether, deployer));
        // farmManager.depositERC20(DepositParams(memeFarm3, 100 ether, deployer));
        farmManager.depositERC20(DepositParams(memeFarm4, 100 ether, deployer));

        IRewardToken(REWARD_TOKEN_ADDRESS).grantRole(MINTER_ROLE, address(farmManager));

        vm.stopBroadcast();
        console.log("===== Deployed contracts =====");
        console.log("rewardToken:", address(REWARD_TOKEN_ADDRESS));
        console.log("farmImpl:", address(farmImpl));
        console.log("farmManagerImpl:", address(farmManagerImpl));
        console.log("farmBeacon:", address(farmBeacon));
        console.log("farmManager:", address(farmManager));
        console.log("===== Meme contracts =====");
        console.log("memeAsset:", address(memeAsset));
        console.log("memeFarm1 (only whitelist):", address(memeFarm1));
        console.log("memeFarm2 (only 10000 Cap + 500 per User):", address(memeFarm2));
        console.log("memeFarm3 (whitelist + 10000 Cap + 500 per User):", address(memeFarm3));
        console.log("memeFarm4 (unlimited):", address(memeFarm4));
        if (DST_INFO.dstEid == LZ_CONFIG.eid) {
            (uint32 dstEid, IFarm dstRewardFarm, bytes32 dstRewardFarmBytes32) = farmManager.dstInfo();
            console.log("===== DstInfo =====");
            console.log("dstEid:", dstEid);
            console.log("dstRewardFarm:", address(dstRewardFarm));
            console.log("dstRewardFarmBytes32:");
            console.logBytes32(dstRewardFarmBytes32);
        }
        console.log("");
        console.log("");
        console.log("===== Whitelist Proof %s =====", whitelistAddresses[0]);
        bytes32[] memory proof1 = TestnetConfigHelper.prepareMerkleProof(whitelist, 0);
        for (uint256 i = 0; i < proof1.length; i++) {
            console.logBytes32(proof1[i]);
        }
        console.log("");
        console.log("");
        console.log("===== Whitelist Proof %s =====", whitelistAddresses[1]);
        bytes32[] memory proof2 = TestnetConfigHelper.prepareMerkleProof(whitelist, 1);
        for (uint256 i = 0; i < proof2.length; i++) {
            console.logBytes32(proof2[i]);
        }
    }
}
