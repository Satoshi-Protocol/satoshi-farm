// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { Farm } from "../../src/Farm.sol";

import { FarmManager } from "../../src/FarmManager.sol";
import { FarmConfig, IFarm } from "../../src/interfaces/IFarm.sol";
import { IFarmManager } from "../../src/interfaces/IFarmManager.sol";
import { IRewardToken } from "../../src/interfaces/IRewardToken.sol";

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Test } from "forge-std/Test.sol";
import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";

import { DEPLOYER, OWNER, TestConfig } from "./TestConfig.sol";
import { IBeacon } from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

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
        _createRewardFarm(DEPLOYER, rewardToken, DEFAULT_REWARD_FARM_CONFIG);
    }

    function _deployMockRewardToken(address deployer) internal {
        vm.startPrank(deployer);

        rewardToken = IRewardToken(address(new MockERC20("Mock Reward Token", "MRT", 18)));

        vm.stopPrank();
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
        bytes memory data = abi.encodeCall(FarmManager.initialize, (rewardToken, farmBeacon));
        farmManager = IFarmManager(address(new ERC1967Proxy(address(farmManagerImpl), data)));

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
        assert(address(rewardFarm) != address(0));
        IFarm farm = IFarm(address(farmManager.createFarm(underlyingAsset, rewardFarm, farmConfig)));

        vm.stopPrank();

        return farm;
    }

    function _createRewardFarm(
        address deployer,
        IERC20 underlyingAsset,
        FarmConfig memory farmConfig
    )
        internal
        returns (IFarm)
    {
        vm.startPrank(deployer);

        assert(address(underlyingAsset) != address(0));
        // input address(0) as rewardFarm when creating rewardFarm
        rewardFarm = IFarm(address(farmManager.createFarm(underlyingAsset, IFarm(address(0)), farmConfig)));

        vm.stopPrank();

        return rewardFarm;
    }
}
