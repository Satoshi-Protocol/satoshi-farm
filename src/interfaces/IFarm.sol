// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { IFarm } from "./IFarm.sol";
import { IFarmManager } from "./IFarmManager.sol";
import { IRewardToken } from "./IRewardToken.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

struct FarmConfig {
    // deposit cap for the farm
    uint256 depositCap;
    // deposit cap per user
    uint256 depositCapPerUser;
    // reward rate per second
    uint256 rewardRate;
    // reward start time
    uint256 rewardStartTime;
    // reward end time
    uint256 rewardEndTime;
    // claim start time
    uint256 claimStartTime;
    // claim end time
    uint256 claimEndTime;
    // delay time for claim
    uint256 claimDelayTime;
    // is claim and stake enabled
    bool claimAndStakeEnabled;
}

enum ClaimStatus {
    NONE,
    PENDING,
    CLAIMED
}

interface IFarm {
    error InvalidZeroAddress();
    error DepositCapExceeded(uint256 amount, uint256 depositCap);
    error DepositCapPerUserExceeded(uint256 amount, uint256 depositCapPerUser);
    error AmountExceedsShares(uint256 amount, uint256 shares);
    error InvalidFarmManager(address caller);
    error AssetBalanceChangedUnexpectedly(uint256 expected, uint256 actual);
    error InvalidClaimTime(uint256 currentTime);
    error ClaimIsNotReady(uint256 claimableTime, uint256 currentTime);
    error AlreadyClaimed();
    error InvalidClaimId(bytes32 claimId, bytes32 expectedClaimId);
    error ZeroPendingRewards();
    error RequestClaimFirst();
    error ClaimAndStakeDisabled();
    error InvalidStatusToRequestClaim(ClaimStatus status);

    event FarmConfigUpdated(FarmConfig farmConfig);
    event Deposit(uint256 indexed amount, address depositor, address receiver);
    event Withdraw(uint256 indexed amount, address owner, address receiver);
    event ClaimAndStake(IFarm indexed rewardFarm, uint256 indexed amount, address receiver);
    event ClaimRequested(
        bytes32 indexed claimId, uint256 indexed amount, address owner, address receiver, uint256 claimableTime
    );
    event RewardClaimed(
        bytes32 indexed claimId, uint256 indexed amount, address owner, address receiver, uint256 claimedTime
    );
    event PendingRewardUpdated(address indexed user, uint256 indexed amount, bool add, uint256 timestamp);
    event LastRewardPerTokenUpdated(uint256 indexed lastRewardPerToken, uint256 lastUpdateTime);
    event UserRewardPerTokenUpdated(address indexed user, uint256 indexed lastRewardPerToken, uint256 lastUpdateTime);

    function initialize(
        address underlyingAsset,
        address rewardToken,
        address rewardFarm,
        address farmManager,
        FarmConfig memory farmConfig
    )
        external;

    function updateFarmConfig(FarmConfig memory farmConfig) external;

    function deposit(uint256 amount, address depositor, address receiver) external;

    function withdraw(uint256 amount, address receiver, address owner) external;

    function requestClaim(
        uint256 amount,
        address owner,
        address receiver
    )
        external
        returns (uint256, uint256, bytes32);

    function claim(uint256 amount, address owner, address receiver, uint256 claimableTime, bytes32 claimId) external;

    function claimAndStake(uint256 amount, address owner, address receiver) external returns (uint256);

    function totalShares() external view returns (uint256);

    function shares(address addr) external view returns (uint256);

    function previewReward(address addr) external view returns (uint256);

    function lastRewardPerToken() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function getLastUserRewardPerToken(address addr) external view returns (uint256);

    function getPendingReward(address addr) external view returns (uint256);

    function getClaimStatus(bytes32 claimId) external view returns (ClaimStatus);

    function isClaimable() external view returns (bool);

    function rewardToken() external view returns (IRewardToken);

    function underlyingAsset() external view returns (IERC20);

    function farmManager() external view returns (IFarmManager);

    function farmConfig()
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, bool);
}
