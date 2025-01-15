// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { FarmConfig, IFarm, WhitelistConfig } from "./IFarm.sol";
import { IRewardToken } from "./IRewardToken.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IBeacon } from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import { SendParam, MessagingFee } from "./layerzero/IOFT.sol";

enum LZ_COMPOSE_OPT { NONE, DEPOSIT_REWARD_TOKEN }


struct DepositWhitelistParams {
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

struct ClaimParams {
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

struct ClaimAndStakeParams {
    IFarm farm;
    uint256 amount;
    address receiver;
}

struct LzConfig {
    uint32 eid;
    address endpoint;
    address refundAddress;
}
struct RewardInfo {
    uint32 dstEid; // Destination layerzero endpoint ID, if 0, then rewardToken is in native chain.
    IFarm rewardFarm;
    bytes32 rewardFarmBytes32;
    IRewardToken rewardToken;
}

interface IFarmManager {
    error InvalidFarm(IFarm farm);
    error InvalidAdmin(address expected, address actual);
    error FarmAlreadyExists(IFarm farm);
    error MintRewardTokenFailed(IRewardToken rewardToken, IFarm farm, uint256 amount);
    error InvalidAmount(uint256 msgValue, uint256 amount);
    error AssetBalanceChangedUnexpectedly(IERC20 token, IFarm farm, address from, uint256 amount, uint256 balanceDiff);

    event FarmConfigUpdated(IFarm farm, FarmConfig farmConfig);
    event WhitelistConfigUpdated(IFarm farm, WhitelistConfig whitelistConfig);
    event FarmCreated(IFarm indexed farm, IERC20 indexed underlyingAsset, IFarm rewardFarm);
    event DepositWhitelist(
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
    event RewardClaimed(
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
        RewardInfo memory _rewardInfo,
        LzConfig memory _lzConfig
    ) external;

    function updateFarmConfig(IFarm farm, FarmConfig memory farmConfig) external;

    function createFarm(
        IERC20 underlyingAsset,
        FarmConfig memory farmConfig
    )
        external
        returns (address);

    function depositNativeAssetWhitelist(DepositWhitelistParams memory depositParams) external payable;

    function depositNativeAssetWhitelistBatch(DepositWhitelistParams[] memory depositParams) external payable;

    function depositERC20Whitelist(DepositWhitelistParams memory depositParams) external;

    function depositERC20WhitelistBatch(DepositWhitelistParams[] memory depositParams) external;

    function depositNativeAsset(DepositParams memory depositParams) external payable;

    function depositNativeAssetBatch(DepositParams[] memory depositParams) external payable;

    function depositERC20(DepositParams memory depositParams) external;

    function depositERC20Batch(DepositParams[] memory depositParams) external;

    function withdraw(WithdrawParams memory withdrawParams) external;

    function withdrawBatch(WithdrawParams[] memory withdrawParams) external;

    function requestClaim(RequestClaimParams memory requestClaimParams) external;

    function requestClaimBatch(RequestClaimParams[] memory requestClaimParams) external;

    function claim(ClaimParams memory claimParams) external;

    function claimBatch(ClaimParams[] memory claimParams) external;

    function stakePendingClaim(StakePendingClaimParams memory stakePendingClaimParams, MessagingFee calldata fee, bytes memory extraOptions) payable external;

    // function stakePendingClaimBatch(StakePendingClaimParams[] memory stakePendingClaimParams) payable external;

    function claimAndStake(ClaimAndStakeParams memory claimAndStakeParams, MessagingFee calldata fee, bytes memory extraOptions) payable external;

    // function claimAndStakeBatch(ClaimAndStakeParams[] memory claimAndStakeParams) payable external;

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

    function lzConfig() external returns (
        uint32 eid,
        address endpoint,
        address refundAddress
    );
    function updateLzConfig(LzConfig memory config) external;

    function rewardInfo() external view returns (
        uint32 dstEid,
        IFarm rewardFarm,
        bytes32 rewardFarmBytes32,
        IRewardToken rewardToken
    );

    function updateRewardInfo(RewardInfo memory _rewardInfo) external;

    function isRewardFarmNative() view external returns (bool);

    function formatLzDepositRewardSendParam(address receiver, uint256 amount, bytes memory extraOptions) view external returns (SendParam memory sendParam);
}
