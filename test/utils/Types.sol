// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

struct Config {
    // vault config
    uint256 startTime;
    uint256 endTime;
    uint256 rewardRate;
    uint256 claimStartTime;
    uint256 claimEndTime;
    uint256 maxAsset;
    // asset config
    uint8 assetDecimals;
    // farming vault manager config
    uint256 refundRatio;
}
