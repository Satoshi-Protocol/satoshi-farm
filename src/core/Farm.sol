// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ClaimStatus, DEFAULT_NATIVE_ASSET_ADDRESS, FarmConfig, IFarm, WhitelistConfig } from "./interfaces/IFarm.sol";

import { DepositParams, IFarmManager } from "./interfaces/IFarmManager.sol";
import { IRewardToken } from "./interfaces/IRewardToken.sol";
import { FarmMath } from "./libraries/FarmMath.sol";

import { OFTComposeMsgCodec } from "../layerzero/OFTComposeMsgCodec.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Farm contract
 * @dev A contract for depositing underlying assets to earn rewards
 * @dev Using Beacon Proxy pattern
 * @dev Deployed and managed by FarmManager
 */
contract Farm is IFarm, Initializable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IRewardToken;

    /* --- state variables --- */

    /// @inheritdoc IFarm
    IERC20 public underlyingAsset;
    /// @inheritdoc IFarm
    IFarmManager public farmManager;
    /// @inheritdoc IFarm
    FarmConfig public farmConfig;
    /// @inheritdoc IFarm
    WhitelistConfig public whitelistConfig;

    /// total underlying asset shares
    uint256 internal _totalShares;
    /// last reward per token
    uint256 internal _lastRewardPerToken;
    /// last update time
    uint256 internal _lastUpdateTime;
    /// user shares mapping (user => shares)
    mapping(address => uint256) internal _shares;
    /// last user reward per token mapping (user => lastUserRewardPerToken)
    mapping(address => uint256) internal _lastUserRewardPerToken;
    /// pending rewards mapping (user => pendingRewards)
    mapping(address => uint256) internal _pendingRewards;
    /// claim status mapping (claimId => ClaimStatus)
    /// claimId = keccak256(amount, owner, receiver, claimableTime)
    mapping(bytes32 /* claimId */ => ClaimStatus) internal _claimStatus;

    /**
     * @notice modifier for only farm manager
     */
    modifier onlyFarmManager() {
        if (msg.sender != address(farmManager)) revert InvalidFarmManager(msg.sender);
        _;
    }

    /**
     * @notice modifier for only whitelist
     * @param depositor The depositor address
     * @param merkleProof The merkle proof
     */
    modifier onlyWhitelist(address depositor, bytes32[] calldata merkleProof) {
        if (whitelistConfig.enabled == false) revert WhitelistNotEnabled();

        bytes32 leaf = keccak256(abi.encode(depositor));
        if (!MerkleProof.verify(merkleProof, whitelistConfig.merkleRoot, leaf)) {
            revert InvalidMerkleProof(merkleProof, whitelistConfig.merkleRoot, leaf);
        }
        _;
    }

    /**
     * @notice modifier for only whitelist not enabled
     */
    modifier onlyWhitelistNotEnabled() {
        if (whitelistConfig.enabled) revert WhitelistEnabled();
        _;
    }

    /**
     * @notice modifier for only withdraw enabled
     */
    modifier onlyWithdrawEnabled() {
        if (!farmConfig.withdrawEnabled) revert WithdrawNotEnabled();
        _;
    }

    /// @inheritdoc IFarm
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

    /// @inheritdoc IFarm
    function updateRewardRate(uint256 _rewardRate) external onlyFarmManager {
        _updateLastRewardPerToken(_calcRewardPerToken());
        farmConfig.rewardRate = _rewardRate;
        emit FarmConfigUpdated(farmConfig);
    }

    /// @inheritdoc IFarm
    function updateFarmConfig(FarmConfig memory _farmConfig) external onlyFarmManager {
        _checkFarmConfig(_farmConfig);
        _updateLastRewardPerToken(_calcRewardPerToken());
        farmConfig = _farmConfig;
        emit FarmConfigUpdated(_farmConfig);
    }

    /// @inheritdoc IFarm
    function updateWhitelistConfig(WhitelistConfig memory _whitelistConfig) external onlyFarmManager {
        whitelistConfig = _whitelistConfig;
        emit WhitelistConfigUpdated(_whitelistConfig);
    }

    /// @inheritdoc IFarm
    function depositNativeAssetWithProof(
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

    /// @inheritdoc IFarm
    function depositERC20WithProof(
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

    /// @inheritdoc IFarm
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

    /// @inheritdoc IFarm
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

    /// @inheritdoc IFarm
    function withdraw(uint256 amount, address owner, address receiver) external onlyFarmManager onlyWithdrawEnabled {
        _beforeWithdraw(amount, owner, receiver);

        _withdraw(amount, owner, receiver);
    }

    /// @inheritdoc IFarm
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

    /// @inheritdoc IFarm
    function executeClaim(
        uint256 amount,
        address owner,
        address receiver,
        uint256 claimableTime,
        bytes32 claimId
    )
        external
        onlyFarmManager
    {
        _beforeExecuteClaim(amount, owner, receiver, claimableTime, claimId);

        _executeClaim(amount, owner, receiver, claimableTime, claimId);
    }

    /// @inheritdoc IFarm
    function forceExecuteClaim(
        uint256 amount,
        address owner,
        address receiver,
        uint256 claimableTime,
        bytes32 claimId
    )
        external
        onlyFarmManager
    {
        _beforeForceExecuteClaim(amount, owner, receiver, claimableTime, claimId);

        _forceExecuteClaim(amount, owner, receiver, claimableTime, claimId);
    }

    /// @inheritdoc IFarm
    function instantClaim(uint256 amount, address owner, address receiver) external onlyFarmManager returns (uint256) {
        _beforeInstantClaim(amount, owner, receiver);

        uint256 claimAmt = _instantClaim(amount, owner, receiver);

        return claimAmt;
    }

    /// @inheritdoc IFarm
    function previewReward(address addr) external view returns (uint256) {
        uint256 rewardAmount = _calcUserReward(addr, _calcRewardPerToken());
        return rewardAmount + _pendingRewards[addr];
    }

    /// @inheritdoc IFarm
    function totalShares() external view returns (uint256) {
        return _totalShares;
    }

    /// @inheritdoc IFarm
    function shares(address addr) external view returns (uint256) {
        return _shares[addr];
    }

    /// @inheritdoc IFarm
    function lastRewardPerToken() external view returns (uint256) {
        return _lastRewardPerToken;
    }

    /// @inheritdoc IFarm
    function lastUpdateTime() external view returns (uint256) {
        return _lastUpdateTime;
    }

    /// @inheritdoc IFarm
    function getClaimStatus(bytes32 claimId) external view returns (ClaimStatus) {
        return _claimStatus[claimId];
    }

    /// @inheritdoc IFarm
    function getLastUserRewardPerToken(address addr) external view returns (uint256) {
        return _lastUserRewardPerToken[addr];
    }

    /// @inheritdoc IFarm
    function getPendingReward(address addr) external view returns (uint256) {
        return _pendingRewards[addr];
    }

    /// @inheritdoc IFarm
    function isDepositEnabled() external view returns (bool) {
        return _isDepositEnabled();
    }

    /// @inheritdoc IFarm
    function isClaimable() external view returns (bool) {
        return _isClaimable();
    }

    /* --- internal functions --- */

    /**
     * @notice Check if deposit is enabled
     */
    function _checkIsDepositEnabled() internal view {
        if (!_isDepositEnabled()) {
            revert InvalidDepositTime(block.timestamp, farmConfig.depositStartTime, farmConfig.depositEndTime);
        }
    }

    /**
     * @notice Check if claim is claimable
     */
    function _checkIsClaimable() internal view {
        if (!_isClaimable()) revert InvalidClaimTime(block.timestamp);
    }

    /**
     * @notice Check if instant claim is enabled
     */
    function _checkIsInstantClaimEnabled() internal view {
        if (!_isInstantClaimEnabled()) revert InstantClaimNotEnabled();
    }

    /**
     * @notice Check if deposit is enabled
     */
    function _isDepositEnabled() internal view returns (bool) {
        return block.timestamp >= farmConfig.depositStartTime && block.timestamp <= farmConfig.depositEndTime;
    }

    /**
     * @notice Check if claim is claimable
     */
    function _isClaimable() internal view returns (bool) {
        return block.timestamp >= farmConfig.claimStartTime && block.timestamp <= farmConfig.claimEndTime;
    }

    /**
     * @notice Check if instant claim is enabled
     */
    function _isInstantClaimEnabled() internal view returns (bool) {
        return farmConfig.instantClaimEnabled;
    }

    /**
     * @notice Before deposit hook
     * @param amount The deposit amount
     * @param receiver The receiver address
     */
    function _beforeDeposit(uint256 amount, address, /* depositor */ address receiver) internal {
        if (amount == 0) revert InvalidZeroAmount();

        if (_totalShares + amount > farmConfig.depositCap) revert DepositCapExceeded(amount, farmConfig.depositCap);

        if (_shares[receiver] + amount > farmConfig.depositCapPerUser) {
            revert DepositCapPerUserExceeded(amount, farmConfig.depositCapPerUser);
        }

        _checkIsDepositEnabled();

        _updateReward(receiver);
    }

    /**
     * @notice Deposit native asset internal function
     * @param amount The deposit amount
     * @param depositor The depositor address
     * @param receiver The receiver address
     */
    function _depositNativeAsset(uint256 amount, address depositor, address receiver) internal {
        if (address(underlyingAsset) != DEFAULT_NATIVE_ASSET_ADDRESS) revert InvalidDepositNativeAsset();

        if (msg.value != amount) revert InvalidAmount(msg.value, amount);

        _updateShares(amount, receiver, true);

        emit Deposit(amount, depositor, receiver);
    }

    /**
     * @notice Deposit ERC20 token internal function
     * @param amount The deposit amount
     * @param depositor The depositor address
     * @param receiver The receiver address
     */
    function _depositERC20(uint256 amount, address depositor, address receiver) internal {
        if (address(underlyingAsset) == DEFAULT_NATIVE_ASSET_ADDRESS) revert InvalidDepositERC20();

        farmManager.transferCallback(underlyingAsset, depositor, amount);

        _updateShares(amount, receiver, true);

        emit Deposit(amount, depositor, receiver);
    }

    /**
     * @notice Before withdraw hook
     * @param amount The withdraw amount
     * @param owner The owner address
     */
    function _beforeWithdraw(uint256 amount, address owner, address /* receiver */ ) internal {
        uint256 ownerShares = _shares[owner];
        if (amount > ownerShares) revert AmountExceedsShares(amount, ownerShares);

        _updateReward(owner);
    }

    /**
     * @notice Withdraw internal function
     * @param amount The withdraw amount
     * @param owner The owner address
     * @param receiver The receiver address
     */
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

    /**
     * @notice Before request claim hook
     * @param owner The owner address
     */
    function _beforeRequestClaim(uint256, /* amount */ address owner, address /* receiver */ ) internal {
        _checkIsClaimable();

        _updateReward(owner);
    }

    /**
     * @notice Request claim internal function
     * @param amount The claim amount
     * @param owner The owner address
     * @param receiver The receiver address
     */
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

    /**
     * @notice Before execute claim hook
     * @param amount The claim amount
     * @param owner The owner address
     * @param receiver The receiver address
     * @param claimableTime The claimable time
     * @param claimId The claim ID
     */
    function _beforeExecuteClaim(
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
            revert RequestClaimFirst();
        }
    }

    /**
     * @notice Execute claim internal function
     * @param amount The claim amount
     * @param owner The owner address
     * @param receiver The receiver address
     * @param claimableTime The claimable time
     * @param claimId The claim ID
     */
    function _executeClaim(
        uint256 amount,
        address owner,
        address receiver,
        uint256 claimableTime,
        bytes32 claimId
    )
        internal
    {
        _claimStatus[claimId] = ClaimStatus.CLAIMED;

        // mint reward to receiver
        farmManager.mintRewardCallback(receiver, amount);
        emit ClaimExecuted(claimId, amount, owner, receiver, claimableTime);
    }

    /**
     * @notice Before force execute claim hook
     * @param amount The claim amount
     * @param owner The owner address
     * @param receiver The receiver address
     * @param claimableTime The claimable time
     * @param claimId The claim ID
     */
    function _beforeForceExecuteClaim(
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

    /**
     * @notice Force execute claim internal function
     * @param amount The claim amount
     * @param owner The owner address
     * @param receiver The receiver address
     * @param claimId The claim ID
     */
    function _forceExecuteClaim(
        uint256 amount,
        address owner,
        address receiver,
        uint256, /* claimableTime */
        bytes32 claimId
    )
        internal
    {
        _claimStatus[claimId] = ClaimStatus.CLAIMED;

        farmManager.mintRewardCallback(address(farmManager), amount);

        emit ForceClaimExecuted(claimId, amount, owner, receiver);
    }

    /**
     * @notice Before instant claim hook
     * @param owner The owner address
     */
    function _beforeInstantClaim(uint256, /* amount */ address owner, address /* receiver */ ) internal {
        _checkIsClaimable();
        _checkIsInstantClaimEnabled();

        _updateReward(owner);
    }

    /**
     * @notice Instant claim internal function
     * @param amount The claim amount
     * @param owner The owner address
     * @param receiver The receiver address
     */
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

        emit InstantClaimed(amount, owner, receiver);

        return amount;
    }

    /**
     * @notice Update shares internal function
     * @param amount The amount
     * @param addr The address
     * @param add Add or subtract shares
     */
    function _updateShares(uint256 amount, address addr, bool add) internal {
        if (add) {
            _shares[addr] += amount;
            _totalShares += amount;
        } else {
            _shares[addr] -= amount;
            _totalShares -= amount;
        }
    }

    /**
     * @notice Update reward internal function
     * @param addr The address
     */
    function _updateReward(address addr) internal {
        uint256 rewardPerToken = _calcRewardPerToken();
        _updateLastRewardPerToken(rewardPerToken);
        uint256 rewardAmount = _calcUserReward(addr, rewardPerToken);
        _updateUserReward(addr, rewardPerToken, rewardAmount);
    }

    /**
     * @notice Calculate reward per token
     * @return The reward per token
     */
    function _calcRewardPerToken() internal view returns (uint256) {
        if (_lastUpdateTime == 0) {
            return 0;
        } else {
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
    }

    /**
     * @notice Calculate user reward
     * @param addr The address
     * @param rewardPerToken The reward per token
     * @return The reward amount
     */
    function _calcUserReward(address addr, uint256 rewardPerToken) internal view returns (uint256) {
        // calculate reward amount
        return FarmMath.computeReward(farmConfig, _shares[addr], rewardPerToken, _lastUserRewardPerToken[addr]);
    }

    /**
     * @notice Update user reward internal function
     * @param addr The address
     * @param rewardPerToken The reward per token
     * @param rewardAmount The reward amount
     */
    function _updateUserReward(address addr, uint256 rewardPerToken, uint256 rewardAmount) internal {
        // update user reward state
        _updateLastUserRewardPerToken(addr, rewardPerToken);
        _updatePendingReward(addr, rewardAmount, true);
    }

    /**
     * @notice Update last reward per token internal function
     * @param rewardPerToken The reward per token
     */
    function _updateLastRewardPerToken(uint256 rewardPerToken) internal {
        require(_lastUpdateTime <= block.timestamp, "Farm: invalid last update time");
        _lastRewardPerToken = rewardPerToken;
        _lastUpdateTime = block.timestamp;
        emit LastRewardPerTokenUpdated(rewardPerToken, block.timestamp);
    }

    /**
     * @notice Update last user reward per token internal function
     * @param addr The address
     * @param rewardPerToken The reward per token
     */
    function _updateLastUserRewardPerToken(address addr, uint256 rewardPerToken) internal {
        _lastUserRewardPerToken[addr] = rewardPerToken;
        emit UserRewardPerTokenUpdated(addr, rewardPerToken, block.timestamp);
    }

    /**
     * @notice Update pending reward internal function
     * @param addr The address
     * @param amount The amount
     * @param add Add or subtract pending rewards
     */
    function _updatePendingReward(address addr, uint256 amount, bool add) internal {
        if (add) {
            _pendingRewards[addr] += amount;
        } else {
            _pendingRewards[addr] -= amount;
        }
        emit PendingRewardUpdated(addr, amount, add, block.timestamp);
    }

    /**
     * @notice Check input claim ID is valid
     * @param amount The claim amount
     * @param owner The owner address
     * @param receiver The receiver address
     * @param claimableTime The claimable time
     * @param claimId The claim ID
     */
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

    /**
     * @notice Calculate claim ID
     * @param amount The claim amount
     * @param owner The owner address
     * @param receiver The receiver address
     * @param claimableTime The claimable time
     * @return The claim ID
     */
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

    /**
     * @notice Check address is not zero address
     * @param addr The address
     */
    function _checkIsNotZeroAddress(address addr) internal pure {
        if (addr == address(0)) revert InvalidZeroAddress();
    }

    /**
     * @notice Check farm config is valid
     * @param _farmConfig The farm config
     */
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
