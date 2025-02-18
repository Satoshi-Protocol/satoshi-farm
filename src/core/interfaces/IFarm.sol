// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IFarm } from "./IFarm.sol";
import { IFarmManager } from "./IFarmManager.sol";
import { IRewardToken } from "./IRewardToken.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

// Use default native asset address if the underlying asset is native asset
address constant DEFAULT_NATIVE_ASSET_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

/**
 * @notice The farm configuration
 * @param depositCap deposit cap for the farm
 * @param depositCapPerUser deposit cap per user
 * @param rewardRate reward rate per second
 * @param depositStartTime deposit start time
 * @param depositEndTime deposit end time
 * @param rewardStartTime reward start time
 * @param rewardEndTime reward end time
 * @param claimStartTime claim start time
 * @param claimEndTime claim end time
 * @param claimDelayTime delay time for claim
 * @param withdrawEnabled is withdraw enabled
 * @param forceClaimEnabled is force claim enabled
 */
struct FarmConfig {
    uint256 depositCap;
    uint256 depositCapPerUser;
    uint256 rewardRate;
    uint32 depositStartTime;
    uint32 depositEndTime;
    uint32 rewardStartTime;
    uint32 rewardEndTime;
    uint32 claimStartTime;
    uint32 claimEndTime;
    uint32 claimDelayTime;
    bool withdrawEnabled;
    bool forceClaimEnabled;
}

/**
 * @notice The whitelist configuration
 * @param enabled is whitelist enabled
 * @param merkleRoot merkle root for whitelist
 */
struct WhitelistConfig {
    bool enabled;
    bytes32 merkleRoot;
}

/**
 * @notice The claim status
 * @param NONE no claim requested
 * @param PENDING claim is pending
 * @param CLAIMED claim is claimed
 */
enum ClaimStatus {
    NONE,
    PENDING,
    CLAIMED
}

/**
 * @title IFarm interface
 * @notice The Farm interface
 */
interface IFarm {
    error InvalidZeroAddress();
    error InvalidZeroAmount();
    error DepositCapExceeded(uint256 amount, uint256 depositCap);
    error DepositCapPerUserExceeded(uint256 amount, uint256 depositCapPerUser);
    error AmountExceedsShares(uint256 amount, uint256 shares);
    error InvalidFarmManager(address caller);
    error AssetBalanceChangedUnexpectedly(uint256 expected, uint256 actual);
    error InvalidClaimTime(uint256 currentTime, uint256 claimStartTime, uint256 claimEndTime);
    error ClaimIsNotReady(uint256 claimableTime, uint256 currentTime);
    error AlreadyClaimed();
    error InvalidClaimId(bytes32 claimId, bytes32 expectedClaimId);
    error ZeroPendingRewards();
    error RequestClaimFirst();
    error InvalidStatusToRequestClaim(ClaimStatus status);
    error InvalidStatusToForceExecuteClaim(ClaimStatus status);
    error InvalidAmount(uint256 msgValue, uint256 amount);
    error TransferNativeAssetFailed();
    error InvalidDepositNativeAsset();
    error InvalidDepositERC20();
    error InvalidDepositTime(uint256 currentTime, uint256 depositStartTime, uint256 depositEndTime);
    error InvalidMerkleProof(bytes32[] merkleProof, bytes32 merkleRoot, bytes32 leaf);
    error WhitelistNotEnabled();
    error WhitelistEnabled();
    error InvalidConfigRewardTime(uint256 startTime, uint256 endTime);
    error InvalidConfigDepositTime(uint256 depositStartTime, uint256 depositEndTime);
    error InvalidConfigClaimTime(uint256 claimStartTime, uint256 claimEndTime);
    error InvalidConfigDepositCap(uint256 depositCap, uint256 depositCapPerUser);
    error ForceClaimNotEnabled();
    error WithdrawNotEnabled();
    error DelayTimeIsNotZero();
    error InvalidRewardEndTime(uint256 rewardEndTime, uint256 lastUpdateTime);

    event FarmConfigUpdated(FarmConfig farmConfig);
    event Deposit(uint256 indexed amount, address depositor, address receiver);
    event Withdraw(uint256 indexed amount, address owner, address receiver);
    event ClaimRequested(
        bytes32 indexed claimId,
        uint256 indexed amount,
        address owner,
        address receiver,
        uint256 claimableTime,
        uint256 nonce
    );
    event ClaimExecuted(
        bytes32 indexed claimId, uint256 indexed amount, address owner, address receiver, uint256 claimedTime
    );
    event ForceClaimExecuted(bytes32 indexed claimId, uint256 indexed amount, address owner, address receiver);
    event ForceClaimed(uint256 indexed amount, address owner, address receiver);
    event InstantClaimed(uint256 indexed amount, address owner, address receiver);
    event PendingRewardUpdated(address indexed user, uint256 indexed amount, bool indexed add);
    event LastRewardPerTokenUpdated(uint256 indexed lastRewardPerToken);
    event UserRewardPerTokenUpdated(address indexed user, uint256 indexed lastRewardPerToken);
    event WhitelistConfigUpdated(WhitelistConfig whitelistConfig);

    /**
     * @notice Initialize the farm with the underlying asset and farm manager
     * @param underlyingAsset The address of the underlying asset
     * @param farmManager The address of the farm manager
     * @param farmConfig The farm configuration
     */
    function initialize(address underlyingAsset, address farmManager, FarmConfig memory farmConfig) external;

    /**
     * @notice Update the reward rate
     * @param _rewardRate The new reward rate
     */
    function updateRewardRate(uint256 _rewardRate) external;

    /**
     * @notice Update the farm configuration
     * @param farmConfig The farm configuration
     */
    function updateFarmConfig(FarmConfig memory farmConfig) external;

    /**
     * @notice Update the whitelist configuration
     * @param whitelistConfig The whitelist configuration
     */
    function updateWhitelistConfig(WhitelistConfig memory whitelistConfig) external;

    /**
     * @notice Deposit native asset with merkle proof
     * @dev Only when underlying asset is native asset
     * @dev Only whitelisted users can deposit with merkle proof
     * @param amount The amount of the native asset
     * @param depositor The address of the depositor
     * @param receiver The address of the receiver
     * @param merkleProof The merkle proof
     */
    function depositNativeAssetWithProof(
        uint256 amount,
        address depositor,
        address receiver,
        bytes32[] calldata merkleProof
    )
        external
        payable;

    /**
     * @notice Deposit ERC20 with merkle proof
     * @dev Only when underlying asset is ERC20
     * @dev Only whitelisted users can deposit with merkle proof
     * @param amount The amount of the ERC20
     * @param depositor The address of the depositor
     * @param receiver The address of the receiver
     * @param merkleProof The merkle proof
     */
    function depositERC20WithProof(
        uint256 amount,
        address depositor,
        address receiver,
        bytes32[] calldata merkleProof
    )
        external;

    /**
     * @notice Deposit native asset
     * @dev Only when underlying asset is native asset
     * @param amount The amount of the native asset
     * @param depositor The address of the depositor
     * @param receiver The address of the receiver
     */
    function depositNativeAsset(uint256 amount, address depositor, address receiver) external payable;

    /**
     * @notice Deposit ERC20
     * @dev Only when underlying asset is ERC20
     * @param amount The amount of the ERC20
     * @param depositor The address of the depositor
     * @param receiver The address of the receiver
     */
    function depositERC20(uint256 amount, address depositor, address receiver) external;

    /**
     * @notice Withdraw underlying asset
     * @param amount The amount of the underlying asset
     * @param receiver The address of the receiver
     * @param owner The address of the owner
     */
    function withdraw(uint256 amount, address receiver, address owner) external;

    /**
     * @notice Request claim reward token
     * @param amount The amount of the reward token requested
     * @param owner The address of the owner
     * @param receiver The address of the receiver
     * @return claimAmt The actual claim amount requested
     * @return claimableTime The claimable time
     * @return nonce The nonce
     * @return claimId The claim id
     */
    function requestClaim(
        uint256 amount,
        address owner,
        address receiver
    )
        external
        returns (uint256 claimAmt, uint256 claimableTime, uint256 nonce, bytes32 claimId);

    /**
     * @notice Execute claim reward token
     * @param amount The amount of the reward token to claim
     * @param owner The address of the owner
     * @param receiver The address of the receiver
     * @param claimableTime The claimable time
     * @param nonce The nonce
     * @param claimId The claim id
     */
    function executeClaim(
        uint256 amount,
        address owner,
        address receiver,
        uint256 claimableTime,
        uint256 nonce,
        bytes32 claimId
    )
        external;

    /**
     * @notice Force execute claim reward token
     * @dev Force execute claim reward token without waiting for the claimable time
     * @param amount The amount of the reward token to claim
     * @param owner The address of the owner
     * @param receiver The address of the receiver
     * @param claimableTime The claimable time
     * @param nonce The nonce
     * @param claimId The claim id
     */
    function forceExecuteClaim(
        uint256 amount,
        address owner,
        address receiver,
        uint256 claimableTime,
        uint256 nonce,
        bytes32 claimId
    )
        external;

    /**
     * @notice force claim reward token
     * @dev Force claim reward token without waiting for delay time
     * @dev Used in the claim&stake function
     * @param amount The amount of the reward token to claim
     * @param owner The address of the owner
     * @param receiver The address of the receiver
     * @return claimAmt The actual claim amount claimed
     */
    function forceClaim(uint256 amount, address owner, address receiver) external returns (uint256 claimAmt);

    /**
     * @notice Instant claim reward token
     * @dev Instant claim reward token if delay time is 0
     * @param amount The amount of the reward token to claim
     * @param owner The address of the owner
     * @param receiver The address of the receiver
     * @return claimAmt The actual claim amount claimed
     */
    function instantClaim(uint256 amount, address owner, address receiver) external returns (uint256 claimAmt);

    /**
     * @notice Total shares in the farm
     * @return totalShares The total shares in the farm
     */
    function totalShares() external view returns (uint256 totalShares);

    /**
     * @notice Shares of the address in the farm
     * @param addr The address
     * @return shares The shares of the address in the farm
     */
    function shares(address addr) external view returns (uint256 shares);

    /**
     * @notice Preview reward amount for the address
     * @param addr The address
     * @return reward The preview reward amount for the address
     */
    function previewReward(address addr) external view returns (uint256 reward);

    /**
     * @notice Last reward per token
     * @return lastRewardPerToken The last reward per token
     */
    function lastRewardPerToken() external view returns (uint256 lastRewardPerToken);

    /**
     * @notice Last update time
     * @return lastUpdateTime The last update time
     */
    function lastUpdateTime() external view returns (uint256 lastUpdateTime);

    /**
     * @notice Last user reward per token
     * @param addr The address
     * @return lastUserRewardPerToken The last user reward per token
     */
    function getLastUserRewardPerToken(address addr) external view returns (uint256 lastUserRewardPerToken);

    /**
     * @notice Pending reward for the address
     * @param addr The address
     * @return pendingReward The pending reward for the address
     */
    function getPendingReward(address addr) external view returns (uint256 pendingReward);

    /**
     * @notice Claim status for the claim id
     * @param claimId The claim id
     * @return claimStatus The claim status
     */
    function getClaimStatus(bytes32 claimId) external view returns (ClaimStatus claimStatus);

    /**
     * @notice Get nonce for the address
     * @param addr The address
     * @return nonce The nonce for the address
     */
    function getNonce(address addr) external view returns (uint256);

    /**
     * @notice The claim function is open
     * @return isClaimable True if the claim function is open
     */
    function isClaimable() external view returns (bool isClaimable);

    /**
     * @notice The deposit function is open
     * @return isDepositEnabled True if the deposit function is open
     */
    function isDepositEnabled() external view returns (bool isDepositEnabled);

    /**
     * @notice underlying asset of the farm
     * @return underlyingAsset The address of the underlying asset
     */
    function underlyingAsset() external view returns (IERC20 underlyingAsset);

    /**
     * @notice farm manager of the farm
     * @return farmManager The address of the farm manager
     */
    function farmManager() external view returns (IFarmManager farmManager);

    /**
     * @notice farm config of the farm
     * @return depositCap The deposit cap
     * @return depositCapPerUser The deposit cap per user
     * @return rewardRate The reward rate
     * @return depositStartTime The deposit start time
     * @return depositEndTime The deposit end time
     * @return rewardStartTime The reward start time
     * @return rewardEndTime The reward end time
     * @return claimStartTime The claim start time
     * @return claimEndTime The claim end time
     * @return claimDelayTime The claim delay time
     * @return withdrawEnabled The withdraw enabled
     * @return forceClaimEnabled The force claim enabled
     */
    function farmConfig()
        external
        view
        returns (
            uint256 depositCap,
            uint256 depositCapPerUser,
            uint256 rewardRate,
            uint32 depositStartTime,
            uint32 depositEndTime,
            uint32 rewardStartTime,
            uint32 rewardEndTime,
            uint32 claimStartTime,
            uint32 claimEndTime,
            uint32 claimDelayTime,
            bool withdrawEnabled,
            bool forceClaimEnabled
        );

    /**
     * @notice whitelist config of the farm
     * @return enabled True if the whitelist is enabled
     * @return merkleRoot The merkle root for the
     */
    function whitelistConfig() external view returns (bool enabled, bytes32 merkleRoot);
}
