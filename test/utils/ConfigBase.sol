// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { Config } from "./Types.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Test } from "forge-std/Test.sol";

contract ConfigBase {
    Config public config = defaultConfig();

    function defaultConfig() public pure returns (Config memory) {
        return Config({
            startTime: 100,
            endTime: 1000,
            rewardRate: 1e10,
            claimStartTime: 500,
            claimEndTime: 1000,
            maxAsset: 1e20,
            assetDecimals: 18,
            penaltyRatio: 50 * 1_000_000 / 100
        });
    }
}
