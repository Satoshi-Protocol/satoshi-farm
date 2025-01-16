// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { DeployBase } from "./utils/DeployBase.sol";
import { Test } from "forge-std/Test.sol";

contract DeployTest is Test, DeployBase {
    function setUp() public override {
        super.setUp();
    }

    function test_deploy_setup() public {
        // _deploySetUp();
        // assert(address(farmImpl) != address(0));
        // assert(address(farmManagerImpl) != address(0));
        // assert(address(farmBeacon) != address(0));
        // assert(address(rewardToken) != address(0));
        // assert(address(farmManager) != address(0));
        // assert(address(rewardFarm) != address(0));
    }
}
