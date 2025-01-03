// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { FarmingVault } from "./FarmingVault.sol";

import { RewardManager } from "./core/reward-vault/RewardManager.sol";
import { VaultManager } from "./core/vault/VaultManager.sol";

import { IFarmingVault } from "./interfaces/IFarmingVault.sol";
import { FarmingVaultGlobalConfig, IFarmingVaultManager } from "./interfaces/IFarmingVaultManager.sol";
import { IPointToken } from "./interfaces/IPointToken.sol";
import { RewardConfig } from "./interfaces/ITimeBasedRewardVault.sol";
import { VaultConfig } from "./interfaces/IVault.sol";

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract FarmingVaultManager is
    IFarmingVaultManager,
    VaultManager,
    RewardManager,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    mapping(address => bool) public validVaults;
    FarmingVaultGlobalConfig public globalConfig;

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }

    function initialize(IPointToken rewardToken, FarmingVaultGlobalConfig memory _globalConfig) external initializer {
        __Ownable_init(msg.sender);
        __Pausable_init();
        __UUPSUpgradeable_init();
        __VaultManager__init(rewardToken);
        __RewardManager__init(rewardToken);
        globalConfig = _globalConfig;
    }

    // --- onlyOwner functions ---
    function pause() external onlyOwner {
        _pause();
    }

    function resume() external onlyOwner {
        _unpause();
    }

    function setGlobalConfig(FarmingVaultGlobalConfig memory _globalConfig) external onlyAdmin {
        globalConfig = _globalConfig;
    }

    function createVault(
        IERC20 _asset,
        IERC20 _reward,
        bytes memory data
    )
        public
        override
        onlyAdmin
        returns (address)
    {
        address goldFarmingVault = _decodeCreateVaultData(data);
        address vault;
        if (goldFarmingVault == address(0)) {
            require(address(_asset) == address(_reward), "Gold farming vault is not set");
        }
        FarmingVault vaultImpl = new FarmingVault();
        bytes memory initData =
            abi.encodeCall(FarmingVault.initialize, (_asset, _reward, address(this), address(goldFarmingVault)));
        vault = address(new ERC1967Proxy(address(vaultImpl), initData));
        if (isValidVault(vault)) {
            revert VaultAlreadyExists();
        }
        validVaults[vault] = true;
        emit VaultCreated(vault, address(_asset));
        return vault;
    }

    function updateFarmingVaultConfig(
        address vault,
        VaultConfig memory _config,
        RewardConfig memory _rewardConfig
    )
        external
        onlyAdmin
    {
        IFarmingVault(vault).updateFarmingVaultConfig(_config, _rewardConfig);
    }

    // --- public functions ---
    function claimAndStake(
        address vault,
        address _owner,
        address _receiver,
        uint256 _stakeAmount
    )
        external
        returns (uint256, uint256)
    {
        if (!isValidFarmingVault(vault)) {
            revert InvalidFarmingVault(vault);
        }

        if (msg.sender != _owner) {
            revert InvalidFarmingOwner(_owner, msg.sender);
        }

        return IFarmingVault(vault).claimAndStake(_owner, _receiver, _stakeAmount);
    }

    function isValidFarmingVault(address vault) public view returns (bool) {
        return validVaults[vault];
    }

    function isValidVault(address vault) public view override(RewardManager, VaultManager) returns (bool) {
        return validVaults[vault];
    }

    function getGlobalConfig() external view returns (FarmingVaultGlobalConfig memory) {
        return globalConfig;
    }

    function admin() public view override(RewardManager, VaultManager) returns (address) {
        return owner();
    }

    // --- internal functions ---
    function _decodeCreateVaultData(bytes memory data) internal pure returns (address) {
        return abi.decode(data, (address));
    }

    modifier onlyAdmin() override(RewardManager, VaultManager) {
        if (msg.sender != admin()) {
            revert InvalidAdmin(admin(), msg.sender);
        }
        _;
    }
}
