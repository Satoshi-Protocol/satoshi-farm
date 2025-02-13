// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Farm } from "../../src/core/Farm.sol";

import { FarmManager } from "../../src/core/FarmManager.sol";
import { FarmConfig, IFarm } from "../../src/core/interfaces/IFarm.sol";
import { DstInfo, IFarmManager, LzConfig } from "../../src/core/interfaces/IFarmManager.sol";
import { IRewardToken } from "../../src/core/interfaces/IRewardToken.sol";

import { IGold } from "../../src/Gold/interfaces/IGold.sol";
import { IGoldAirdrop } from "../../src/Gold/interfaces/IGoldAirdrop.sol";
import { Gold } from "../../src/Gold/Gold.sol";
import { GoldAirdrop } from "../../src/Gold/GoldAirdrop.sol";

import { DEPLOYER, OWNER, TestConfig } from "./TestConfig.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IBeacon } from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { StdCheats } from "forge-std/StdCheats.sol";
import { Test } from "forge-std/Test.sol";
import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";

abstract contract DeployBase is Test, TestConfig {
    IFarm farmImpl;
    IFarmManager farmManagerImpl;

    IBeacon farmBeacon;
    IRewardToken rewardToken;
    IFarmManager farmManager;
    IFarm rewardFarm;

    function setUp() public virtual { }

    function _deploySetUp() internal {
        _deployMockRewardToken(DEPLOYER);
        _deployImplementation(DEPLOYER);
        _deployFarmBeacon(DEPLOYER, OWNER);
        _deployFarmManager(DEPLOYER);

        vm.label(address(farmManager), "FarmManager");
        vm.label(address(rewardFarm), "RewardFarm");
        vm.label(address(rewardToken), "RewardToken");
    }

    function _deployMockRewardToken(address deployer) internal {
        vm.startPrank(deployer);

        rewardToken = IRewardToken(address(new MockERC20("Mock Reward Token", "MRT", 18)));

        vm.stopPrank();
    }

    function _deployMockUnderlyingAsset(address deployer) internal returns (IERC20) {
        vm.startPrank(deployer);

        IERC20 underlyingAsset = IERC20(address(new MockERC20("Mock Underlying Asset", "MUA", 18)));

        vm.stopPrank();

        return underlyingAsset;
    }

    function _deployImplementation(address deployer) internal {
        vm.startPrank(deployer);

        assert(farmImpl == IFarm(address(0)));
        assert(farmManagerImpl == IFarmManager(address(0)));

        farmImpl = new Farm();
        farmManagerImpl = new FarmManager();

        vm.stopPrank();
    }

    function _deployFarmBeacon(address deployer, address owner) internal {
        vm.startPrank(deployer);

        assert(farmImpl != IFarm(address(0))); // check if implementation contract is deployed
        assert(farmBeacon == UpgradeableBeacon(address(0))); // check if beacon contract is not deployed
        farmBeacon = new UpgradeableBeacon(address(farmImpl), owner);

        vm.stopPrank();
    }

    function _deployFarmManager(address deployer) internal {
        vm.startPrank(deployer);

        assert(address(rewardToken) != address(0));
        assert(address(farmBeacon) != address(0));
        DstInfo memory dstInfo = DEFAULT_DST_INFO;
        LzConfig memory lzConfig = DEFAULT_LZ_CONFIG;
        FarmConfig memory farmConfig = DEFAULT_REWARD_FARM_CONFIG;
        bytes memory data =
            abi.encodeCall(FarmManager.initialize, (farmBeacon, rewardToken, dstInfo, lzConfig, farmConfig));
        farmManager = IFarmManager(address(new ERC1967Proxy(address(farmManagerImpl), data)));

        (, IFarm dstRewardFarm,) = farmManager.dstInfo();
        rewardFarm = dstRewardFarm;

        vm.stopPrank();
    }

    function _deployGold(address deployer) internal returns (IGold gold, IGoldAirdrop goldAirdrop) {
        vm.startPrank(deployer);

        address goldImpl = address(new Gold());
        bytes memory goldData =
            abi.encodeCall(Gold.initialize, ("Gold", "GOLD"));
        gold = IGold(address(new ERC1967Proxy(goldImpl, goldData)));

        address goldAirdropImpl = address(new GoldAirdrop());
        bytes memory goldAirdropData =
            abi.encodeCall(GoldAirdrop.initialize, (address(gold), block.timestamp, type(uint256).max, bytes32(0)));
        goldAirdrop = IGoldAirdrop(address(new ERC1967Proxy(goldAirdropImpl, goldAirdropData)));

        gold.rely(address(goldAirdrop));
        vm.stopPrank();
    }

    function _createFarm(
        address deployer,
        IERC20 underlyingAsset,
        FarmConfig memory farmConfig
    )
        internal
        returns (IFarm)
    {
        vm.startPrank(deployer);

        assert(address(underlyingAsset) != address(0));
        // assert(address(rewardFarm) != address(0));
        IFarm farm = IFarm(address(farmManager.createFarm(underlyingAsset, farmConfig)));

        vm.stopPrank();

        return farm;
    }

    /// @dev Generates a user, labels its address, and funds it with test assets.
    function _createUser(string memory name_) internal returns (address payable user_) {
        StdCheats.Account memory account_ = _createAccount(name_);
        user_ = payable(account_.addr);
    }

    /// @dev Generates a user with private key, labels its address, and funds it with test assets.
    function _createAccount(string memory name_) internal returns (StdCheats.Account memory account_) {
        account_ = makeAccount(name_);
        vm.deal({ account: account_.addr, newBalance: 100 ether });
    }
}
