// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { ClaimStatus, DEFAULT_NATIVE_ASSET_ADDRESS, FarmConfig, IFarm } from "./interfaces/IFarm.sol";

import { DepositParams, IFarmManager } from "./interfaces/IFarmManager.sol";
import { IRewardToken } from "./interfaces/IRewardToken.sol";
import { FarmMath } from "./libraries/FarmMath.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Farm is IFarm, Initializable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IRewardToken;

    // --- state variables ---
    IERC20 public underlyingAsset;
    IFarm public rewardFarm;
    IFarmManager public farmManager;
    IRewardToken public rewardToken;
    FarmConfig public farmConfig;

    uint256 internal _totalShares;
    uint256 internal _lastRewardPerToken;
    uint256 internal _lastUpdateTime;
    mapping(address => uint256) internal _shares;
    mapping(address => uint256) internal _lastUserRewardPerToken;
    mapping(address => uint256) internal _pendingRewards;
    // claimId(keccak256(amount, owner, receiver, claimableTime)) => ClaimStatus
    mapping(bytes32 => ClaimStatus) internal _claimStatus;

    modifier onlyFarmManager() {
        if (msg.sender != address(farmManager)) {
            revert InvalidFarmManager(msg.sender);
        }
        _;
    }

    function initialize(
        address _underlyingAsset,
        address _rewardToken,
        address _rewardFarm,
        address _farmManager,
        FarmConfig memory _farmConfig
    )
        external
        initializer
    {
        _checkIsNotZeroAddress(_underlyingAsset);
        _checkIsNotZeroAddress(_rewardToken);
        _checkIsNotZeroAddress(_farmManager);
        // rewardFarm can be zero address

        underlyingAsset = IERC20(_underlyingAsset);
        rewardToken = IRewardToken(_rewardToken);
        rewardFarm = IFarm(_rewardFarm);
        farmManager = IFarmManager(_farmManager);
        farmConfig = _farmConfig;

        emit FarmConfigUpdated(_farmConfig);
    }

    function updateFarmConfig(FarmConfig memory _farmConfig) external onlyFarmManager {
        farmConfig = _farmConfig;
        emit FarmConfigUpdated(_farmConfig);
    }

    function deposit(uint256 amount, address depositor, address receiver) external payable onlyFarmManager {
        _beforeDeposit(amount, depositor, receiver);

        _deposit(amount, depositor, receiver);
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

    function claimAndStake(
        uint256 amount,
        address owner,
        address receiver
    )
        external
        onlyFarmManager
        returns (uint256)
    {
        _beforeClaimAndStake(amount, owner, receiver);

        uint256 claimAndStakeAmt = _claimAndStake(amount, owner, receiver);

        return claimAndStakeAmt;
    }

    function previewReward(address addr) external view returns (uint256) {
        (, uint256 rewardAmount) = _calcReward(addr);
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

    function isClaimable() external view returns (bool) {
        return _isClaimable();
    }

    // --- internal functions ---

    function _checkIsClaimable() internal view {
        if (!_isClaimable()) {
            revert InvalidClaimTime(block.timestamp);
        }
    }

    function _checkIsClaimAndStakeEnabled() internal view {
        if (!_isClaimAndStakeEnabled()) {
            revert ClaimAndStakeDisabled();
        }
    }

    function _isClaimable() internal view returns (bool) {
        return block.timestamp >= farmConfig.claimStartTime && block.timestamp <= farmConfig.claimEndTime;
    }

    function _isClaimAndStakeEnabled() internal view returns (bool) {
        return farmConfig.claimAndStakeEnabled;
    }

    function _beforeDeposit(uint256 amount, address, address receiver) internal view {
        if (_totalShares + amount > farmConfig.depositCap) {
            revert DepositCapExceeded(amount, farmConfig.depositCap);
        }

        if (_shares[receiver] + amount > farmConfig.depositCapPerUser) {
            revert DepositCapPerUserExceeded(amount, farmConfig.depositCapPerUser);
        }
    }

    function _deposit(uint256 amount, address depositor, address receiver) internal {
        if (address(underlyingAsset) == DEFAULT_NATIVE_ASSET_ADDRESS) {
            // case1: deposit native asset
            if (msg.value != amount) {
                revert InvalidAmount(msg.value, amount);
            }
        } else {
            // case2: deposit ERC20 token
            if (msg.value != 0) {
                revert InvalidAmount(msg.value, amount);
            }
            uint256 balanceBefore = underlyingAsset.balanceOf(address(this));
            underlyingAsset.safeTransferFrom(depositor, address(this), amount);
            uint256 balanceAfter = underlyingAsset.balanceOf(address(this));
            uint256 balanceChange = balanceAfter - balanceBefore;
            if (balanceChange != amount) {
                revert AssetBalanceChangedUnexpectedly(amount, balanceChange);
            }
        }

        _updateShares(amount, receiver, true);

        emit Deposit(amount, depositor, receiver);
    }

    function _beforeWithdraw(uint256 amount, address owner, address) internal view {
        uint256 ownerShares = _shares[owner];
        if (amount > ownerShares) {
            revert AmountExceedsShares(amount, ownerShares);
        }
    }

    function _withdraw(uint256 amount, address owner, address receiver) internal {
        if (address(underlyingAsset) == DEFAULT_NATIVE_ASSET_ADDRESS) {
            // case1: withdraw native asset
            (bool success,) = receiver.call{ value: amount }("");
            if (!success) {
                revert TransferNativeAssetFailed();
            }
        } else {
            // case2: withdraw ERC20 token
            underlyingAsset.safeTransfer(receiver, amount);
        }

        _updateShares(amount, owner, false);

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

        if (pendingRewards == 0) {
            revert ZeroPendingRewards();
        }

        uint256 claimableTime = block.timestamp + farmConfig.claimDelayTime;
        bytes32 claimId = keccak256(abi.encodePacked(amount, owner, receiver, claimableTime));
        ClaimStatus claimStatus = _claimStatus[claimId];
        if (claimStatus != ClaimStatus.NONE) {
            revert InvalidStatusToRequestClaim(claimStatus);
        }

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

        if (claimStatus == ClaimStatus.CLAIMED) {
            revert AlreadyClaimed();
        }

        // if claim is requested
        if (claimStatus == ClaimStatus.PENDING) {
            if (claimableTime > block.timestamp) {
                revert ClaimIsNotReady(claimableTime, block.timestamp);
            }
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

    function _beforeClaimAndStake(uint256, address owner, address) internal {
        _checkIsClaimable();
        _checkIsClaimAndStakeEnabled();

        _updateReward(owner);
    }

    function _claimAndStake(uint256 amount, address owner, address receiver) internal returns (uint256) {
        uint256 pendingRewards = _pendingRewards[owner];
        if (pendingRewards == 0) {
            revert ZeroPendingRewards();
        }

        if (amount > pendingRewards) {
            // if amount exceeds pending rewards, claim all pending rewards
            amount = pendingRewards;
        }

        // update state
        _updatePendingReward(owner, amount, false);

        //TODO: add cross chain claim and stake (call manager to mint reward and do cross chain deposit)

        // mint reward to address(this)
        farmManager.mintRewardCallback(address(this), amount);

        // stake(deposit) the reward to rewardFarm
        rewardToken.approve(address(farmManager), amount);

        DepositParams memory depositParams = DepositParams({ farm: rewardFarm, amount: amount, receiver: receiver });
        farmManager.deposit(depositParams);
        emit ClaimAndStake(rewardFarm, amount, receiver);

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
        // calculate reward per token and reward amount
        (uint256 rewardPerToken, uint256 rewardAmount) = _calcReward(addr);

        // update last reward state
        _updateLastRewardPerToken(rewardPerToken);

        // update user reward state
        _updateLastUserRewardPerToken(addr, rewardPerToken);
        _updatePendingReward(addr, rewardAmount, true);
    }

    function _calcReward(address addr) internal view returns (uint256, uint256) {
        // calculate reward per token
        uint256 rewardPerToken = FarmMath.computeLatestRewardPerToken(
            _lastRewardPerToken,
            farmConfig.rewardRate,
            FarmMath.computeInterval(
                block.timestamp, _lastUpdateTime, farmConfig.rewardStartTime, farmConfig.rewardEndTime
            ),
            _totalShares
        );

        // calculate reward amount
        uint256 rewardAmount =
            FarmMath.computeReward(farmConfig, _shares[addr], rewardPerToken, _lastUserRewardPerToken[addr]);
        return (rewardPerToken, rewardAmount);
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
        bytes32 expectedClaimId = keccak256(abi.encodePacked(amount, owner, receiver, claimableTime));
        if (claimId != expectedClaimId) {
            revert InvalidClaimId(claimId, expectedClaimId);
        }
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
        return keccak256(abi.encodePacked(amount, owner, receiver, claimableTime));
    }

    function _checkIsNotZeroAddress(address addr) internal pure {
        if (addr == address(0)) {
            revert InvalidZeroAddress();
        }
    }
}
