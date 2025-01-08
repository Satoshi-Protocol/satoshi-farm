// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { FarmConfig, IFarm } from "./IFarm.sol";
import { IRewardToken } from "./IRewardToken.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IBeacon } from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

interface IFarmManager {
    error InvalidFarm(IFarm farm);
    error InvalidAdmin(address expected, address actual);
    error FarmAlreadyExists(IFarm farm);
    error MintRewardTokenFailed(IRewardToken rewardToken, IFarm farm, uint256 amount);

    event FarmCreated(IFarm indexed farm, IERC20 indexed underlyingAsset, IFarm rewardFarm);
    event Deposit(IFarm indexed farm, uint256 indexed amount, address sender, address receiver);
    event Withdraw(IFarm indexed farm, uint256 indexed amount, address owner, address receiver);
    event ClaimRequested(
        IFarm indexed farm,
        uint256 indexed amount,
        address owner,
        address receiver,
        uint256 claimableTime,
        bytes32 indexed claimId
    );
    event RewardClaimed(
        IFarm indexed farm,
        uint256 indexed amount,
        address owner,
        address receiver,
        uint256 claimedTime,
        bytes32 indexed claimId
    );
    event ClaimAndStake(IFarm indexed farm, uint256 indexed amount, address owner, address receiver);

    function initialize(IRewardToken rewardToken, IBeacon farmBeacon) external;

    function updateFarmConfig(IFarm farm, FarmConfig memory farmConfig) external;

    function createFarm(
        IERC20 underlyingAsset,
        IFarm rewardFarm,
        FarmConfig memory farmConfig
    )
        external
        returns (address);

    function deposit(IFarm farm, uint256 amount, address receiver) external;

    function withdraw(IFarm farm, uint256 amount, address receiver) external;

    function requestClaim(IFarm farm, uint256 amount, address receiver) external;

    function claim(
        IFarm farm,
        uint256 amount,
        address owner,
        uint256 claimableTime,
        bytes32 claimId
    )
        external;

    function claimAndStake(IFarm farm, uint256 amount, address receiver) external;

    function mintRewardCallback(address to, uint256 amount) external;

    function totalShares(IFarm farm) external view returns (uint256);

    function shares(IFarm farm, address addr) external view returns (uint256);

    function previewReward(IFarm farm, address addr) external view returns (uint256);

    function lastRewardPerToken(IFarm farm) external view returns (uint256);

    function lastUpdateTime(IFarm farm) external view returns (uint256);

    function getLastUserRewardPerToken(IFarm farm, address addr) external view returns (uint256);

    function getPendingReward(IFarm farm, address addr) external view returns (uint256);

    function isClaimable(IFarm farm) external view returns (bool);

    function isValidFarm(IFarm farm) external view returns (bool);
}
