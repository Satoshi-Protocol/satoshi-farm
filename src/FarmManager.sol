// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { Farm } from "./Farm.sol";

import { FarmConfig, IFarm } from "./interfaces/IFarm.sol";
import { IFarmManager } from "./interfaces/IFarmManager.sol";
import { IRewardToken } from "./interfaces/IRewardToken.sol";

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { IBeacon } from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

contract FarmManager is IFarmManager, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    IRewardToken public rewardToken;
    IBeacon public farmBeacon;
    mapping(IFarm => bool) public validFarms;

    modifier onlyFarm(address addr) {
        IFarm farm = IFarm(addr);
        if (!isValidFarm(farm)) {
            revert InvalidFarm(farm);
        }
        _;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }

    function initialize(IRewardToken _rewardToken, IBeacon _farmBeacon) external initializer {
        __Ownable_init(msg.sender);
        __Pausable_init();
        __UUPSUpgradeable_init();

        rewardToken = _rewardToken;
        farmBeacon = _farmBeacon;
    }

    // --- onlyOwner functions ---
    function pause() external onlyOwner {
        _pause();
    }

    function resume() external onlyOwner {
        _unpause();
    }

    function updateFarmConfig(IFarm farm, FarmConfig memory farmConfig) external onlyOwner {
        farm.updateFarmConfig(farmConfig);
    }

    function createFarm(
        IERC20 underlyingAsset,
        IFarm rewardFarm,
        FarmConfig memory farmConfig
    )
        external
        onlyOwner
        returns (address)
    {
        bytes memory initData = abi.encodeCall(
            IFarm.initialize,
            (address(underlyingAsset), address(rewardToken), address(rewardFarm), address(this), farmConfig)
        );
        IFarm farm = IFarm(address(new BeaconProxy(address(farmBeacon), initData)));
        if (isValidFarm(farm)) {
            revert FarmAlreadyExists(farm);
        }

        validFarms[farm] = true;
        emit FarmCreated(farm, underlyingAsset, rewardFarm);
        return address(farm);
    }

    function deposit(IFarm farm, uint256 amount, address receiver) external whenNotPaused {
        _checkFarmIsValid(farm);

        farm.deposit(amount, msg.sender, receiver);
        emit Deposit(farm, amount, msg.sender, receiver);
    }

    function withdraw(IFarm farm, uint256 amount, address receiver) external whenNotPaused {
        _checkFarmIsValid(farm);

        farm.withdraw(amount, msg.sender, receiver);
        emit Withdraw(farm, amount, msg.sender, receiver);
    }

    function requestClaim(IFarm farm, uint256 amount, address receiver) external whenNotPaused {
        _checkFarmIsValid(farm);

        (uint256 claimAmt, uint256 claimableTime, bytes32 claimId) = farm.requestClaim(amount, msg.sender, receiver);
        emit ClaimRequested(farm, claimAmt, msg.sender, receiver, claimableTime, claimId);
    }

    function claim(
        IFarm farm,
        uint256 amount,
        address owner,
        uint256 claimableTime,
        bytes32 claimId
    )
        external
        whenNotPaused
    {
        _checkFarmIsValid(farm);

        farm.claim(amount, owner, msg.sender, claimableTime, claimId);
        emit RewardClaimed(farm, amount, owner, msg.sender, claimableTime, claimId);
    }

    function claimAndStake(IFarm farm, uint256 amount, address receiver) external whenNotPaused {
        _checkFarmIsValid(farm);

        uint256 claimAndStakeAmt = farm.claimAndStake(amount, msg.sender, receiver);
        emit ClaimAndStake(farm, claimAndStakeAmt, msg.sender, receiver);
    }

    function mintRewardCallback(address to, uint256 amount) external onlyFarm(msg.sender) {
        IFarm farm = IFarm(msg.sender);

        try rewardToken.mint(to, amount) { }
        catch {
            revert MintRewardTokenFailed(rewardToken, farm, amount);
        }
    }

    // --- external view functions ---
    function totalShares(IFarm farm) external view returns (uint256) {
        return farm.totalShares();
    }

    function shares(IFarm farm, address addr) external view returns (uint256) {
        return farm.shares(addr);
    }

    function previewReward(IFarm farm, address addr) external view returns (uint256) {
        return farm.previewReward(addr);
    }

    function lastRewardPerToken(IFarm farm) external view returns (uint256) {
        return farm.lastRewardPerToken();
    }

    function lastUpdateTime(IFarm farm) external view returns (uint256) {
        return farm.lastUpdateTime();
    }

    function getLastUserRewardPerToken(IFarm farm, address addr) external view returns (uint256) {
        return farm.getLastUserRewardPerToken(addr);
    }

    function getPendingReward(IFarm farm, address addr) external view returns (uint256) {
        return farm.getPendingReward(addr);
    }

    function isClaimable(IFarm farm) external view returns (bool) {
        return farm.isClaimable();
    }

    function isValidFarm(IFarm farm) public view returns (bool) {
        return validFarms[farm];
    }

    // --- internal functions ---
    function _checkFarmIsValid(IFarm farm) internal view {
        if (!isValidFarm(farm)) {
            revert InvalidFarm(farm);
        }
    }
}
