// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { ClaimStatus, DEFAULT_NATIVE_ASSET_ADDRESS, FarmConfig, IFarm, WhitelistConfig } from "./interfaces/IFarm.sol";

import { DepositParams, IFarmManager } from "./interfaces/IFarmManager.sol";
import { IRewardToken } from "./interfaces/IRewardToken.sol";
import { FarmMath } from "./libraries/FarmMath.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { OFTComposeMsgCodec } from "./interfaces/layerzero/OFTComposeMsgCodec.sol";

contract Farm is IFarm, Initializable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IRewardToken;

    // --- state variables ---
    IERC20 public underlyingAsset;
    IFarmManager public farmManager;
    FarmConfig public farmConfig;
    WhitelistConfig public whitelistConfig;

    uint256 internal _totalShares;
    uint256 internal _lastRewardPerToken;
    uint256 internal _lastUpdateTime;

    mapping(address => uint256) internal _shares;
    mapping(address => uint256) internal _lastUserRewardPerToken;
    mapping(address => uint256) internal _pendingRewards;
    // claimId(keccak256(amount, owner, receiver, claimableTime)) => ClaimStatus
    mapping(bytes32 => ClaimStatus) internal _claimStatus;

    modifier onlyFarmManager() {
        if (msg.sender != address(farmManager)) revert InvalidFarmManager(msg.sender);

        _;
    }

    modifier onlyWhitelist(address depositor, bytes32[] calldata merkleProof) {
        if (whitelistConfig.enabled == false) revert WhitelistNotEnabled();

        bytes32 leaf = keccak256(abi.encode(depositor));
        if (!MerkleProof.verify(merkleProof, whitelistConfig.merkleRoot, leaf)) {
            revert InvalidMerkleProof(merkleProof, whitelistConfig.merkleRoot, leaf);
        }

        _;
    }

    modifier onlyWhitelistNotEnabled() {
        if (whitelistConfig.enabled) revert WhitelistEnabled();

        _;
    }

    function initialize(
        address _underlyingAsset,
        address _farmManager,
        FarmConfig memory _farmConfig
    )
        external
        initializer
    {
        _checkIsNotZeroAddress(_underlyingAsset);
        _checkIsNotZeroAddress(_farmManager);
        _checkFarmConfig(_farmConfig);

        underlyingAsset = IERC20(_underlyingAsset);
        farmManager = IFarmManager(_farmManager);
        farmConfig = _farmConfig;

        emit FarmConfigUpdated(_farmConfig);
    }


    function updateFarmConfig(FarmConfig memory _farmConfig) external onlyFarmManager {
        _checkFarmConfig(_farmConfig);
        _updateLastRewardPerToken(_calcRewardPerToken());
        farmConfig = _farmConfig;
        emit FarmConfigUpdated(_farmConfig);
    }

    function updateWhitelistConfig(WhitelistConfig memory _whitelistConfig) external onlyFarmManager {
        whitelistConfig = _whitelistConfig;
        emit WhitelistConfigUpdated(_whitelistConfig);
    }

    function depositNativeAssetWhitelist(
        uint256 amount,
        address depositor,
        address receiver,
        bytes32[] calldata merkleProof
    )
        external
        payable
        onlyFarmManager
        onlyWhitelist(depositor, merkleProof)
    {
        _beforeDeposit(amount, depositor, receiver);

        _depositNativeAsset(amount, depositor, receiver);
    }

    function depositERC20Whitelist(
        uint256 amount,
        address depositor,
        address receiver,
        bytes32[] calldata merkleProof
    )
        external
        onlyFarmManager
        onlyWhitelist(depositor, merkleProof)
    {
        _beforeDeposit(amount, depositor, receiver);

        _depositERC20(amount, depositor, receiver);
    }

    function depositNativeAsset(
        uint256 amount,
        address depositor,
        address receiver
    )
        external
        payable
        onlyFarmManager
        onlyWhitelistNotEnabled
    {
        _beforeDeposit(amount, depositor, receiver);

        _depositNativeAsset(amount, depositor, receiver);
    }

    function depositERC20(
        uint256 amount,
        address depositor,
        address receiver
    )
        external
        onlyFarmManager
        onlyWhitelistNotEnabled
    {
        _beforeDeposit(amount, depositor, receiver);

        _depositERC20(amount, depositor, receiver);
    }

    function withdraw(uint256 amount, address owner, address receiver) external onlyFarmManager {
        _beforeWithdraw(amount, owner, receiver);

        _withdraw(amount, owner, receiver);
    }

    function requestClaim(
        uint256 amount,
        address owner,
        address receiver
    )
        external
        onlyFarmManager
        returns (uint256, uint256, bytes32)
    {
        _beforeRequestClaim(amount, owner, receiver);

        (uint256 claimAmt, uint256 claimableTime, bytes32 claimId) = _requestClaim(amount, owner, receiver);

        return (claimAmt, claimableTime, claimId);
    }

    function claim(
        uint256 amount,
        address owner,
        address receiver,
        uint256 claimableTime,
        bytes32 claimId
    )
        external
        onlyFarmManager
    {
        _beforeClaim(amount, owner, receiver, claimableTime, claimId);

        _claim(amount, owner, receiver, claimableTime, claimId);
    }

    function instantClaimFromPending(
        uint256 amount,
        address owner,
        address receiver,
        uint256 claimableTime,
        bytes32 claimId,
        address claimReceiver
    ) external
        onlyFarmManager
    {
        _beforeInstantClaimFromPending(amount, owner, receiver, claimableTime, claimId);

        _instantClaimFromPending(claimId, amount, claimReceiver);
    }

    function instantClaim(
        uint256 amount,
        address owner,
        address receiver
    )
        external
        onlyFarmManager
        returns (uint256)
    {
        _beforeInstantClaim(amount, owner, receiver);

        uint256 claimAndStakeAmt = _instantClaim(amount, owner, receiver);

        return claimAndStakeAmt;
    }

    function previewReward(address addr) external view returns (uint256) {
        uint256 rewardAmount = _calcUserReward(addr, _calcRewardPerToken());
        return rewardAmount + _pendingRewards[addr];
    }

    function totalShares() external view returns (uint256) {
        return _totalShares;
    }

    function shares(address addr) external view returns (uint256) {
        return _shares[addr];
    }

    function lastRewardPerToken() external view returns (uint256) {
        return _lastRewardPerToken;
    }

    function lastUpdateTime() external view returns (uint256) {
        return _lastUpdateTime;
    }

    function getClaimStatus(bytes32 claimId) external view returns (ClaimStatus) {
        return _claimStatus[claimId];
    }

    function getLastUserRewardPerToken(address addr) external view returns (uint256) {
        return _lastUserRewardPerToken[addr];
    }

    function getPendingReward(address addr) external view returns (uint256) {
        return _pendingRewards[addr];
    }

    function isDepositEnabled() external view returns (bool) {
        return _isDepositEnabled();
    }

    function isClaimable() external view returns (bool) {
        return _isClaimable();
    }

    // --- internal functions ---

    function _checkIsDepositEnabled() internal view {
        if (!_isDepositEnabled()) {
            revert InvalidDepositTime(block.timestamp, farmConfig.depositStartTime, farmConfig.depositEndTime);
        }
    }

    function _checkIsClaimable() internal view {
        if (!_isClaimable()) revert InvalidClaimTime(block.timestamp);
    }

    function _isDepositEnabled() internal view returns (bool) {
        return block.timestamp >= farmConfig.depositStartTime && block.timestamp <= farmConfig.depositEndTime;
    }

    function _isClaimable() internal view returns (bool) {
        return block.timestamp >= farmConfig.claimStartTime && block.timestamp <= farmConfig.claimEndTime;
    }

    function _isClaimAndStakeEnabled() internal view returns (bool) {
        return farmConfig.claimAndStakeEnabled;
    }

    function _beforeDeposit(uint256 amount, address, address receiver) internal {
        if (amount == 0) revert InvalidZeroAmount();

        if (_totalShares + amount > farmConfig.depositCap) revert DepositCapExceeded(amount, farmConfig.depositCap);

        if (_shares[receiver] + amount > farmConfig.depositCapPerUser) {
            revert DepositCapPerUserExceeded(amount, farmConfig.depositCapPerUser);
        }

        _checkIsDepositEnabled();

        _updateReward(receiver);
    }

    function _depositNativeAsset(uint256 amount, address depositor, address receiver) internal {
        if (address(underlyingAsset) != DEFAULT_NATIVE_ASSET_ADDRESS) revert InvalidDepositNativeAsset();

        if (msg.value != amount) revert InvalidAmount(msg.value, amount);

        _updateShares(amount, receiver, true);

        emit Deposit(amount, depositor, receiver);
    }

    function _depositERC20(uint256 amount, address depositor, address receiver) internal {
        if (address(underlyingAsset) == DEFAULT_NATIVE_ASSET_ADDRESS) revert InvalidDepositERC20();

        farmManager.transferCallback(underlyingAsset, depositor, amount);

        _updateShares(amount, receiver, true);

        emit Deposit(amount, depositor, receiver);
    }

    function _beforeWithdraw(uint256 amount, address owner, address) internal {
        uint256 ownerShares = _shares[owner];
        if (amount > ownerShares) revert AmountExceedsShares(amount, ownerShares);

        _updateReward(owner);
    }

    function _withdraw(uint256 amount, address owner, address receiver) internal {
        _updateShares(amount, owner, false);

        if (address(underlyingAsset) == DEFAULT_NATIVE_ASSET_ADDRESS) {
            // case1: withdraw native asset
            (bool success,) = receiver.call{ value: amount }("");
            if (!success) revert TransferNativeAssetFailed();
        } else {
            // case2: withdraw ERC20 token
            underlyingAsset.safeTransfer(receiver, amount);
        }

        emit Withdraw(amount, owner, receiver);
    }

    function _beforeRequestClaim(uint256, address owner, address) internal {
        _checkIsClaimable();

        _updateReward(owner);
    }

    function _requestClaim(
        uint256 amount,
        address owner,
        address receiver
    )
        internal
        returns (uint256, uint256, bytes32)
    {
        uint256 pendingRewards = _pendingRewards[owner];
        if (amount > pendingRewards) {
            // if amount exceeds pending rewards, claim all pending rewards
            amount = pendingRewards;
        }

        if (pendingRewards == 0) revert ZeroPendingRewards();

        uint256 claimableTime = block.timestamp + farmConfig.claimDelayTime;
        bytes32 claimId = keccak256(abi.encode(amount, owner, receiver, claimableTime));
        ClaimStatus claimStatus = _claimStatus[claimId];
        if (claimStatus != ClaimStatus.NONE) revert InvalidStatusToRequestClaim(claimStatus);

        // update state
        _updatePendingReward(owner, amount, false);
        _claimStatus[claimId] = ClaimStatus.PENDING;

        emit ClaimRequested(claimId, amount, owner, receiver, claimableTime);

        return (amount, claimableTime, claimId);
    }

    function _beforeClaim(
        uint256 amount,
        address owner,
        address receiver,
        uint256 claimableTime,
        bytes32 claimId
    )
        internal
    {
        _checkIsClaimable();

        _checkClaimId(amount, owner, receiver, claimableTime, claimId);

        _updateReward(owner);

        ClaimStatus claimStatus = _claimStatus[claimId];

        if (claimStatus == ClaimStatus.CLAIMED) revert AlreadyClaimed();

        // if claim is requested
        if (claimStatus == ClaimStatus.PENDING) {
            if (claimableTime > block.timestamp) revert ClaimIsNotReady(claimableTime, block.timestamp);
        } else {
            if (farmConfig.claimDelayTime == 0) {
                // if no delay time, request claim then claim immediately
                _requestClaim(amount, owner, receiver);
            } else {
                // if has delay time, use `requestClaim` first then `claim` later
                revert RequestClaimFirst();
            }
        }
    }

    function _claim(uint256 amount, address owner, address receiver, uint256 claimableTime, bytes32 claimId) internal {
        _claimStatus[claimId] = ClaimStatus.CLAIMED;

        // mint reward to receiver
        farmManager.mintRewardCallback(receiver, amount);
        emit RewardClaimed(claimId, amount, owner, receiver, claimableTime);
    }

    function _beforeInstantClaimFromPending(
        uint256 amount,
        address owner,
        address receiver,
        uint256 claimableTime,
        bytes32 claimId
    )
        internal
        view
    {
        _checkClaimId(amount, owner, receiver, claimableTime, claimId);

        ClaimStatus claimStatus = _claimStatus[claimId];

        if (claimStatus != ClaimStatus.PENDING) revert InvalidStatusToInstantClaimPending(claimStatus);
    }

    function _instantClaimFromPending(
        bytes32 claimId,
        uint256 amount,
        address receiver
    )
        internal
    {
        _claimStatus[claimId] = ClaimStatus.CLAIMED;
        farmManager.mintRewardCallback(receiver, amount);
    }

    function _beforeInstantClaim(uint256, address owner, address) internal {
        _checkIsClaimable();

        _updateReward(owner);
    }

    function _instantClaim(uint256 amount, address owner, address receiver) internal returns (uint256) {
        uint256 pendingRewards = _pendingRewards[owner];
        if (pendingRewards == 0) revert ZeroPendingRewards();

        if (amount > pendingRewards) {
            // if amount exceeds pending rewards, claim all pending rewards
            amount = pendingRewards;
        }

        // update state
        _updatePendingReward(owner, amount, false);
        farmManager.mintRewardCallback(receiver, amount);
        return amount;
    }



    function _updateShares(uint256 amount, address addr, bool add) internal {
        if (add) {
            _shares[addr] += amount;
            _totalShares += amount;
        } else {
            _shares[addr] -= amount;
            _totalShares -= amount;
        }
    }

    function _updateReward(address addr) internal {
        uint256 rewardPerToken = _calcRewardPerToken();
        _updateLastRewardPerToken(rewardPerToken);
        uint256 rewardAmount = _calcUserReward(addr, rewardPerToken);
        _updateUserReward(addr, rewardPerToken, rewardAmount);
    }

    function _calcRewardPerToken() internal view returns (uint256) {
        // calculate reward per token
        return FarmMath.computeLatestRewardPerToken(
            _lastRewardPerToken,
            farmConfig.rewardRate,
            FarmMath.computeInterval(
                block.timestamp, _lastUpdateTime, farmConfig.rewardStartTime, farmConfig.rewardEndTime
            ),
            _totalShares
        );
    }

    function _calcUserReward(address addr, uint256 rewardPerToken) internal view returns (uint256) {
        // calculate reward amount
        return FarmMath.computeReward(farmConfig, _shares[addr], rewardPerToken, _lastUserRewardPerToken[addr]);
    }

    function _updateUserReward(address addr, uint256 rewardPerToken, uint256 rewardAmount) internal {
        // update user reward state
        _updateLastUserRewardPerToken(addr, rewardPerToken);
        _updatePendingReward(addr, rewardAmount, true);
    }

    function _updateLastRewardPerToken(uint256 rewardPerToken) internal {
        _lastRewardPerToken = rewardPerToken;
        _lastUpdateTime = block.timestamp;
        emit LastRewardPerTokenUpdated(rewardPerToken, block.timestamp);
    }

    function _updateLastUserRewardPerToken(address addr, uint256 rewardPerToken) internal {
        _lastUserRewardPerToken[addr] = rewardPerToken;
        emit UserRewardPerTokenUpdated(addr, rewardPerToken, block.timestamp);
    }

    function _updatePendingReward(address addr, uint256 amount, bool add) internal {
        if (add) {
            _pendingRewards[addr] += amount;
        } else {
            _pendingRewards[addr] -= amount;
        }
        emit PendingRewardUpdated(addr, amount, add, block.timestamp);
    }

    function _checkClaimId(
        uint256 amount,
        address owner,
        address receiver,
        uint256 claimableTime,
        bytes32 claimId
    )
        internal
        pure
    {
        bytes32 expectedClaimId = keccak256(abi.encode(amount, owner, receiver, claimableTime));
        if (claimId != expectedClaimId) revert InvalidClaimId(claimId, expectedClaimId);
    }

    function _calcClaimId(
        uint256 amount,
        address owner,
        address receiver,
        uint256 claimableTime
    )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(amount, owner, receiver, claimableTime));
    }

    function _checkIsNotZeroAddress(address addr) internal pure {
        if (addr == address(0)) revert InvalidZeroAddress();
    }

    function _checkFarmConfig(FarmConfig memory _farmConfig) internal pure {
        if (_farmConfig.rewardEndTime < _farmConfig.rewardStartTime) {
            revert InvalidConfigRewardTime(_farmConfig.rewardStartTime, _farmConfig.rewardEndTime);
        }
        if (_farmConfig.depositEndTime < _farmConfig.depositStartTime) {
            revert InvalidConfigDepositTime(_farmConfig.depositStartTime, _farmConfig.depositEndTime);
        }
        if (_farmConfig.claimEndTime < _farmConfig.claimStartTime) {
            revert InvalidConfigClaimTime(_farmConfig.claimStartTime, _farmConfig.claimEndTime);
        }
        if (_farmConfig.depositCap < _farmConfig.depositCapPerUser) {
            revert InvalidConfigDepositCap(_farmConfig.depositCap, _farmConfig.depositCapPerUser);
        }
    }

}
