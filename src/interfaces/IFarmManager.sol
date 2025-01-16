// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { FarmConfig, IFarm, WhitelistConfig } from "./IFarm.sol";
import { IRewardToken } from "./IRewardToken.sol";

import { MessagingFee, SendParam } from "./layerzero/IOFT.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IBeacon } from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

enum LZ_COMPOSE_OPT {
    NONE,
    DEPOSIT_REWARD_TOKEN
}

struct LzConfig {
    uint32 eid;
    address endpoint;
    address refundAddress;
}

struct DstInfo {
    uint32 dstEid;
    IFarm dstRewardFarm;
    bytes32 dstRewardManagerBytes32;
}

struct DepositWithProofParams {
    IFarm farm;
    uint256 amount;
    address receiver;
    bytes32[] merkleProof;
}

struct DepositParams {
    IFarm farm;
    uint256 amount;
    address receiver;
}

struct WithdrawParams {
    IFarm farm;
    uint256 amount;
    address receiver;
}

struct RequestClaimParams {
    IFarm farm;
    uint256 amount;
    address receiver;
}

struct ExecuteClaimParams {
    IFarm farm;
    uint256 amount;
    address owner;
    uint256 claimableTime;
    bytes32 claimId;
}

struct StakePendingClaimParams {
    IFarm farm;
    uint256 amount;
    address receiver;
    uint256 claimableTime;
    bytes32 claimId;
}

struct StakePendingClaimCrossChainParams {
    IFarm farm;
    uint256 amount;
    address receiver;
    uint256 claimableTime;
    bytes32 claimId;
    bytes extraOptions;
}

struct ClaimAndStakeParams {
    IFarm farm;
    uint256 amount;
    address receiver;
}

struct ClaimAndStakeCrossChainParams {
    IFarm farm;
    uint256 amount;
    address receiver;
    bytes extraOptions;
}

interface IFarmManager {
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

    function initialize(
        IBeacon farmBeacon,
        IRewardToken rewardToken,
        DstInfo memory _dstInfo,
        LzConfig memory _lzConfig,
        FarmConfig memory _farmConfig
    )
        external;

    function updateFarmConfig(IFarm farm, FarmConfig memory farmConfig) external;

    function createFarm(IERC20 underlyingAsset, FarmConfig memory farmConfig) external returns (address);

    function depositNativeAssetWithProof(DepositWithProofParams memory depositParams) external payable;

    function depositNativeAssetWithProofBatch(DepositWithProofParams[] memory depositParamsArr) external payable;

    function depositERC20WithProof(DepositWithProofParams memory depositParams) external;

    function depositERC20WithProofBatch(DepositWithProofParams[] memory depositParamsArr) external;

    function depositNativeAsset(DepositParams memory depositParams) external payable;

    function depositNativeAssetBatch(DepositParams[] memory depositParamsArr) external payable;

    function depositERC20(DepositParams memory depositParams) external;

    function depositERC20Batch(DepositParams[] memory depositParamsArr) external;

    function withdraw(WithdrawParams memory withdrawParams) external;

    function withdrawBatch(WithdrawParams[] memory withdrawParamsArr) external;

    function requestClaim(RequestClaimParams memory requestClaimParams) external;

    function requestClaimBatch(RequestClaimParams[] memory requestClaimParamsArr) external;

    function executeClaim(ExecuteClaimParams memory executeClaimParams) external;

    function executeClaimBatch(ExecuteClaimParams[] memory executeClaimParamsArr) external;

    function stakePendingClaim(StakePendingClaimParams memory stakePendingClaimParams) external;

    function stakePendingClaimBatch(StakePendingClaimParams[] memory stakePendingClaimParamsArr) external;

    function stakePendingClaimCrossChain(StakePendingClaimCrossChainParams memory stakePendingClaimCrossChainParams)
        external
        payable;

    function stakePendingClaimCrossChainBatch(
        StakePendingClaimCrossChainParams[] memory stakePendingClaimCrossChainParamsArr
    )
        external
        payable;

    function claimAndStake(ClaimAndStakeParams memory claimAndStakeParams) external;

    function claimAndStakeBatch(ClaimAndStakeParams[] memory claimAndStakeParamsArr) external;

    function claimAndStakeCrossChain(ClaimAndStakeCrossChainParams memory claimAndStakeCrossChainParams)
        external
        payable;

    function claimAndStakeCrossChainBatch(ClaimAndStakeCrossChainParams[] memory claimAndStakeCrossChainParamsArr)
        external
        payable;

    function mintRewardCallback(address to, uint256 amount) external;

    function transferCallback(IERC20 token, address from, uint256 amount) external;

    function totalShares(IFarm farm) external view returns (uint256);

    function shares(IFarm farm, address addr) external view returns (uint256);

    function previewReward(IFarm farm, address addr) external view returns (uint256);

    function lastRewardPerToken(IFarm farm) external view returns (uint256);

    function lastUpdateTime(IFarm farm) external view returns (uint256);

    function getLastUserRewardPerToken(IFarm farm, address addr) external view returns (uint256);

    function getPendingReward(IFarm farm, address addr) external view returns (uint256);

    function isDepositEnabled(IFarm farm) external view returns (bool);

    function isClaimable(IFarm farm) external view returns (bool);

    function isValidFarm(IFarm farm) external view returns (bool);

    function lzConfig() external returns (uint32 eid, address endpoint, address refundAddress);

    function updateLzConfig(LzConfig memory config) external;

    function dstInfo() external view returns (uint32 dstEid, IFarm dstRewardFarm, bytes32 dstRewardFarmBytes32);

    function updateDstInfo(DstInfo memory _dstInfo) external;

    function formatLzDepositRewardSendParam(
        address receiver,
        uint256 amount,
        bytes memory extraOptions
    )
        external
        view
        returns (SendParam memory sendParam);
}
