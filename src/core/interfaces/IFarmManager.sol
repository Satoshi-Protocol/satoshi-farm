// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { FarmConfig, IFarm, WhitelistConfig } from "./IFarm.sol";
import { IRewardToken } from "./IRewardToken.sol";

import { IOAppComposer } from "../../layerzero/IOAppComposer.sol";
import { MessagingFee, SendParam } from "../../layerzero/IOFT.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IBeacon } from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

enum LZ_COMPOSE_OPT {
    NONE,
    DEPOSIT_REWARD_TOKEN
}

/**
 * @notice The current chain's LayerZero configuration
 * @param eid The current chain's endpoint id
 * @param endpoint The current chain's endpoint
 * @param refundAddress The address to refund
 */
struct LzConfig {
    uint32 eid;
    address endpoint;
    address refundAddress;
}

/**
 * @notice The destination chain's information
 * @dev The farm of reward token will be deployed on the destination chain and the only one
 * @param dstEid The destination chain's endpoint id
 * @param dstRewardFarm The destination chain's reward farm
 * @param dstRewardManagerBytes32 The destination chain's reward farm address in bytes32
 */
struct DstInfo {
    uint32 dstEid;
    IFarm dstRewardFarm;
    bytes32 dstRewardManagerBytes32;
}

/**
 * @notice The parameters for depositing with proof
 * @param farm The farm to deposit
 * @param amount The amount to deposit
 * @param receiver The receiver of the deposit
 * @param merkleProof The merkle proof checking the whitelist
 */
struct DepositWithProofParams {
    IFarm farm;
    uint256 amount;
    address receiver;
    bytes32[] merkleProof;
}

/**
 * @notice The parameters for depositing
 * @param farm The farm to deposit
 * @param amount The amount to deposit
 * @param receiver The receiver of the deposit
 */
struct DepositParams {
    IFarm farm;
    uint256 amount;
    address receiver;
}

/**
 * @notice The parameters for withdrawing
 * @param farm The farm to withdraw
 * @param amount The amount to withdraw underlying asset
 * @param receiver The receiver of the withdrawal
 */
struct WithdrawParams {
    IFarm farm;
    uint256 amount;
    address receiver;
}

/**
 * @notice The parameters for requesting claim
 * @param farm The farm to request claim
 * @param amount The amount requested to claim
 * @param receiver The receiver of the claim
 */
struct RequestClaimParams {
    IFarm farm;
    uint256 amount;
    address receiver;
}

/**
 * @notice The parameters for executing claim
 * @param farm The farm to execute claim
 * @param amount The amount to claim
 * @param owner The owner of the claim
 * @param claimableTime The claimable time of the claim
 * @param claimId The id of the claim
 */
struct ExecuteClaimParams {
    IFarm farm;
    uint256 amount;
    address owner;
    uint256 claimableTime;
    bytes32 claimId;
}

/**
 * @notice The parameters for staking pending claim
 * @dev Only used if the reward farm deployed chain is current chain
 * @param farm The farm to stake pending claim
 * @param amount The amount to stake
 * @param receiver The receiver of the stake
 * @param claimableTime The claimable time of the claim
 * @param claimId The id of the claim
 */
struct StakePendingClaimParams {
    IFarm farm;
    uint256 amount;
    address receiver;
    uint256 claimableTime;
    bytes32 claimId;
}

/**
 * @notice The parameters for staking pending claim cross chain
 * @dev Only used if the reward farm deployed chain is different from the current chain
 * @param farm The farm to stake pending claim
 * @param amount The amount of pending claim
 * @param receiver The receiver of the pending claim
 * @param claimableTime The claimable time of the pending claim
 * @param claimId The id of the pending claim
 * @param extraOptions The extra options for L0 cross chain
 */
struct StakePendingClaimCrossChainParams {
    IFarm farm;
    uint256 amount;
    address receiver;
    uint256 claimableTime;
    bytes32 claimId;
    bytes extraOptions;
}

/**
 * @notice The parameters for instant claim and stake to reward farm
 * @dev Only used if the reward farm deployed chain is current chain
 * @param farm The farm to claim and stake
 * @param amount The amount to claim and stake
 * @param receiver The receiver of the claim and stake
 */
struct ClaimAndStakeParams {
    IFarm farm;
    uint256 amount;
    address receiver;
}

/**
 * @notice The parameters for instant claim and stake to reward farm cross chain
 * @dev Only used if the reward farm deployed chain is different from the current chain
 * @param farm The farm to claim and stake
 * @param amount The amount to claim and stake
 * @param receiver The receiver of the claim and stake
 * @param extraOptions The extra options for L0 cross chain
 */
struct ClaimAndStakeCrossChainParams {
    IFarm farm;
    uint256 amount;
    address receiver;
    bytes extraOptions;
}

/**
 * @title IFarmManager interface
 * @notice The interface for the farm manager
 */
interface IFarmManager is IOAppComposer {
    error InvalidFarm(IFarm farm);
    error InvalidAdmin(address expected, address actual);
    error FarmAlreadyExists(IFarm farm);
    error MintRewardTokenFailed(IRewardToken rewardToken, IFarm farm, uint256 amount);
    error InvalidAmount(uint256 msgValue, uint256 amount);
    error AssetBalanceChangedUnexpectedly(IERC20 token, IFarm farm, address from, uint256 amount, uint256 balanceDiff);
    error InvalidZeroAddress();
    error FarmBytes32Mismatch(IFarm farm, bytes32 farmBytes32);
    error InsufficientFee(uint256 fee, uint256 msgValue);
    error InvalidZeroValue();
    error InvalidZeroDstEid();
    error DstEidIsNotCurrentChain(uint32 dstEid, uint32 currentEid);
    error DstEidIsCurrentChain(uint32 dstEid, uint32 currentEid);

    event RewardRateUpdated(IFarm farm, uint256 rewardRate);
    event FarmConfigUpdated(IFarm farm, FarmConfig farmConfig);
    event WhitelistConfigUpdated(IFarm farm, WhitelistConfig whitelistConfig);
    event LzConfigUpdated(LzConfig lzConfig);
    event DstInfoUpdated(DstInfo dstInfo);
    event FarmCreated(IFarm indexed farm, IERC20 indexed underlyingAsset, IFarm rewardFarm);
    event DepositWithProof(
        IFarm indexed farm, uint256 indexed amount, address sender, address receiver, bytes32[] merkleProof
    );
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
    event ClaimExecuted(
        IFarm indexed farm,
        uint256 indexed amount,
        address owner,
        address receiver,
        uint256 claimedTime,
        bytes32 indexed claimId
    );
    event PendingClaimStaked(
        IFarm indexed farm,
        uint256 indexed amount,
        address owner,
        address receiver,
        uint256 claimableTime,
        bytes32 indexed claimId
    );
    event ClaimAndStake(IFarm indexed farm, uint256 indexed amount, address owner, address receiver);

    /**
     * @notice Initialize the farm manager
     * @param farmBeacon The farm beacon contract
     * @param rewardToken The reward token
     * @param dstInfo The reward farm's destination chain information
     * @param lzConfig The current chain's LayerZero configuration
     * @param farmConfig The farm configuration
     */
    function initialize(
        IBeacon farmBeacon,
        IRewardToken rewardToken,
        DstInfo memory dstInfo,
        LzConfig memory lzConfig,
        FarmConfig memory farmConfig
    )
        external;

    /**
     * @notice Pause the farm manager
     */
    function pause() external;

    /**
     * @notice Resume the farm manager
     */
    function resume() external;

    /**
     * @notice Update the reward rate
     * @param farm The farm to update
     * @param rewardRate The new reward rate
     */
    function updateRewardRate(IFarm farm, uint256 rewardRate) external;

    /**
     * @notice Update the farm configuration
     * @param farm The farm to update
     * @param farmConfig The farm configuration
     */
    function updateFarmConfig(IFarm farm, FarmConfig memory farmConfig) external;

    /**
     * @notice Update the whitelist configuration
     * @param farm The farm to update
     * @param whitelistConfig The whitelist configuration
     */
    function updateWhitelistConfig(IFarm farm, WhitelistConfig memory whitelistConfig) external;

    /**
     * @notice Create a farm
     * @param underlyingAsset The underlying asset of the farm
     * @param farmConfig The farm configuration
     * @return farm The farm address
     */
    function createFarm(IERC20 underlyingAsset, FarmConfig memory farmConfig) external returns (address farm);

    /**
     * @notice Deposit Native Asset with proof
     * @dev Only used if the underlying asset is native asset
     * @dev Only whitelisted users can deposit with proof
     * @param depositParams The deposit parameters
     */
    function depositNativeAssetWithProof(DepositWithProofParams memory depositParams) external payable;

    /**
     * @notice Deposit Native Asset with proof batch
     * @dev Only used if the underlying asset is native asset
     * @dev Only whitelisted users can deposit with proof
     * @param depositParamsArr The deposit parameters array
     */
    function depositNativeAssetWithProofBatch(DepositWithProofParams[] memory depositParamsArr) external payable;

    /**
     * @notice Deposit ERC20 with proof
     * @dev Only used if the underlying asset is ERC20
     * @dev Only whitelisted users can deposit with proof
     * @param depositParams The deposit parameters
     */
    function depositERC20WithProof(DepositWithProofParams memory depositParams) external;

    /**
     * @notice Deposit ERC20 with proof batch
     * @dev Only used if the underlying asset is ERC20
     * @dev Only whitelisted users can deposit with proof
     * @param depositParamsArr The deposit parameters array
     */
    function depositERC20WithProofBatch(DepositWithProofParams[] memory depositParamsArr) external;

    /**
     * @notice Deposit Native Asset
     * @dev Only used if the underlying asset is native asset
     * @param depositParams The deposit parameters
     */
    function depositNativeAsset(DepositParams memory depositParams) external payable;

    /**
     * @notice Deposit Native Asset batch
     * @dev Only used if the underlying asset is native asset
     * @param depositParamsArr The deposit parameters array
     */
    function depositNativeAssetBatch(DepositParams[] memory depositParamsArr) external payable;

    /**
     * @notice Deposit ERC20
     * @dev Only used if the underlying asset is ERC20
     * @param depositParams The deposit parameters
     */
    function depositERC20(DepositParams memory depositParams) external;

    /**
     * @notice Deposit ERC20 batch
     * @dev Only used if the underlying asset is ERC20
     * @param depositParamsArr The deposit parameters array
     */
    function depositERC20Batch(DepositParams[] memory depositParamsArr) external;

    /**
     * @notice Withdraw
     * @param withdrawParams The withdraw parameters
     */
    function withdraw(WithdrawParams memory withdrawParams) external;

    /**
     * @notice Withdraw batch
     * @param withdrawParamsArr The withdraw parameters array
     */
    function withdrawBatch(WithdrawParams[] memory withdrawParamsArr) external;

    /**
     * @notice Request claim
     * @param requestClaimParams The request claim parameters
     */
    function requestClaim(RequestClaimParams memory requestClaimParams) external;

    /**
     * @notice Request claim batch
     * @param requestClaimParamsArr The request claim parameters array
     */
    function requestClaimBatch(RequestClaimParams[] memory requestClaimParamsArr) external;

    /**
     * @notice Execute claim
     * @param executeClaimParams The execute claim parameters
     */
    function executeClaim(ExecuteClaimParams memory executeClaimParams) external;

    /**
     * @notice Execute claim batch
     * @param executeClaimParamsArr The execute claim parameters array
     */
    function executeClaimBatch(ExecuteClaimParams[] memory executeClaimParamsArr) external;

    /**
     * @notice Stake pending claim
     * @dev Only used if the reward farm deployed chain is current chain
     * @dev Only used if the claim is requested
     * @param stakePendingClaimParams The stake pending claim parameters
     */
    function stakePendingClaim(StakePendingClaimParams memory stakePendingClaimParams) external;

    /**
     * @notice Stake pending claim batch
     * @dev Only used if the reward farm deployed chain is current chain
     * @dev Only used if the claim is requested
     * @param stakePendingClaimParamsArr The stake pending claim parameters array
     */
    function stakePendingClaimBatch(StakePendingClaimParams[] memory stakePendingClaimParamsArr) external;

    /**
     * @notice Stake pending claim cross chain
     * @dev Only used if the reward farm deployed chain is different from the current chain
     * @dev Only used if the claim is requested
     * @param stakePendingClaimCrossChainParams The stake pending claim cross chain parameters
     */
    function stakePendingClaimCrossChain(StakePendingClaimCrossChainParams memory stakePendingClaimCrossChainParams)
        external
        payable;

    /**
     * @notice Stake pending claim cross chain batch
     * @dev Only used if the reward farm deployed chain is different from the current chain
     * @dev Only used if the claim is requested
     * @param stakePendingClaimCrossChainParamsArr The stake pending claim cross chain parameters array
     */
    function stakePendingClaimCrossChainBatch(
        StakePendingClaimCrossChainParams[] memory stakePendingClaimCrossChainParamsArr
    )
        external
        payable;

    /**
     * @notice Claim and stake
     * @dev Only used if the reward farm deployed chain is current chain
     * @param claimAndStakeParams The claim and stake parameters
     */
    function claimAndStake(ClaimAndStakeParams memory claimAndStakeParams) external;

    /**
     * @notice Claim and stake batch
     * @dev Only used if the reward farm deployed chain is current chain
     * @param claimAndStakeParamsArr The claim and stake parameters array
     */
    function claimAndStakeBatch(ClaimAndStakeParams[] memory claimAndStakeParamsArr) external;

    /**
     * @notice Claim and stake cross chain
     * @dev Only used if the reward farm deployed chain is different from the current chain
     * @param claimAndStakeCrossChainParams The claim and stake cross chain parameters
     */
    function claimAndStakeCrossChain(ClaimAndStakeCrossChainParams memory claimAndStakeCrossChainParams)
        external
        payable;

    /**
     * @notice Claim and stake cross chain batch
     * @dev Only used if the reward farm deployed chain is different from the current chain
     * @param claimAndStakeCrossChainParamsArr The claim and stake cross chain parameters array
     */
    function claimAndStakeCrossChainBatch(ClaimAndStakeCrossChainParams[] memory claimAndStakeCrossChainParamsArr)
        external
        payable;

    /**
     * @notice Mint reward token
     * @dev Only called by the deployed farm
     * @param to The receiver of the minted reward token
     * @param amount The amount to mint
     */
    function mintRewardCallback(address to, uint256 amount) external;

    /**
     * @notice Transfer underlying asset when depositing
     * @dev Only called by the deployed farm
     * @param token the underlying asset
     * @param from The sender of the transfer
     * @param amount The amount to transfer
     */
    function transferCallback(IERC20 token, address from, uint256 amount) external;

    /**
     * @notice Get the paused status
     * @return paused The paused status
     */
    function paused() external view returns (bool);

    /**
     * @notice Get the farm beacon
     * @return farmBeacon The farm beacon
     */
    function farmBeacon() external view returns (IBeacon farmBeacon);

    /**
     * @notice Get the reward token
     * @return rewardToken The reward token
     */
    function rewardToken() external view returns (IRewardToken rewardToken);

    /**
     * @notice farm is valid or not
     * @param farm The farm to query
     * @return isValidFarm The farm is valid or not
     */
    function validFarms(IFarm farm) external view returns (bool isValidFarm);

    /**
     * @notice Total shares of the farm
     * @param farm The farm to query
     * @return totalShares The total shares of the farm
     */
    function totalShares(IFarm farm) external view returns (uint256 totalShares);

    /**
     * @notice Shares of the user
     * @param farm The farm to query
     * @param addr The user address
     * @return shares The shares of the user
     */
    function shares(IFarm farm, address addr) external view returns (uint256 shares);

    /**
     * @notice Preview reward of the user
     * @param farm The farm to query
     * @param addr The user address
     * @return reward The preview reward of the user
     */
    function previewReward(IFarm farm, address addr) external view returns (uint256 reward);

    /**
     * @notice Last reward per token
     * @param farm The farm to query
     * @return lastRewardPerToken The last reward per token
     */
    function lastRewardPerToken(IFarm farm) external view returns (uint256 lastRewardPerToken);

    /**
     * @notice Last update time
     * @param farm The farm to query
     * @return lastUpdateTime The last update time
     */
    function lastUpdateTime(IFarm farm) external view returns (uint256 lastUpdateTime);

    /**
     * @notice Last user reward per token
     * @param farm The farm to query
     * @param addr The user address
     * @return lastUserRewardPerToken The last user reward per token
     */
    function getLastUserRewardPerToken(
        IFarm farm,
        address addr
    )
        external
        view
        returns (uint256 lastUserRewardPerToken);

    /**
     * @notice Pending reward of the user
     * @param farm The farm to query
     * @param addr The user address
     * @return pendingReward The pending reward of the user
     */
    function getPendingReward(IFarm farm, address addr) external view returns (uint256 pendingReward);

    /**
     * @notice Deposit is enabled or not
     * @param farm The farm to query
     * @return depositEnabled The deposit is enabled or not
     */
    function isDepositEnabled(IFarm farm) external view returns (bool depositEnabled);

    /**
     * @notice Claim is enabled or not
     * @param farm The farm to query
     * @return claimable The claim is enabled or not
     */
    function isClaimable(IFarm farm) external view returns (bool claimable);

    /**
     * @notice Farm is valid or not
     * @param farm The farm to query
     * @return validFarm The farm is valid or not
     */
    function isValidFarm(IFarm farm) external view returns (bool validFarm);

    /**
     * @notice Get the underlying asset of the farm
     * @param farm The farm to query
     * @return underlyingAsset The underlying asset of the farm
     */
    function getUnderlyingAsset(IFarm farm) external view returns (IERC20 underlyingAsset);

    /**
     * @notice Get the farm configuration
     * @param farm The farm to query
     * @return farmConfig The farm configuration
     */
    function getFarmConfig(IFarm farm) external view returns (FarmConfig memory farmConfig);

    /**
     * @notice Get the whitelist configuration
     * @param farm The farm to query
     * @return whitelistConfig The whitelist configuration
     */
    function getWhitelistConfig(IFarm farm) external view returns (WhitelistConfig memory whitelistConfig);

    /**
     * @notice LayerZero configuration
     * @return eid The current chain's endpoint id
     * @return endpoint The current chain's endpoint
     * @return refundAddress The address to refund
     */
    function lzConfig() external returns (uint32 eid, address endpoint, address refundAddress);

    /**
     * @notice Update LayerZero configuration
     * @param lzConfig The LayerZero configuration to update
     */
    function updateLzConfig(LzConfig memory lzConfig) external;

    /**
     * @notice Destination chain's information of the reward farm
     * @return dstEid The destination chain's endpoint id
     * @return dstRewardFarm The destination chain's reward farm
     * @return dstRewardFarmBytes32 The destination chain's reward farm address in bytes32
     */
    function dstInfo() external view returns (uint32 dstEid, IFarm dstRewardFarm, bytes32 dstRewardFarmBytes32);

    /**
     * @notice Update destination chain's information
     * @param dstInfo The destination chain's information to update
     */
    function updateDstInfo(DstInfo memory dstInfo) external;

    /**
     * @notice Format the send param for deposit
     * @param receiver The receiver of the deposit
     * @param amount The amount to deposit
     * @param extraOptions The extra options for L0 cross chain
     * @return sendParam The send param for deposit
     */
    function formatDepositLzSendParam(
        address receiver,
        uint256 amount,
        bytes memory extraOptions
    )
        external
        view
        returns (SendParam memory sendParam);
}
