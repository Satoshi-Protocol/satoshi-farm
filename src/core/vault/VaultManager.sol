// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IVault } from "../../interfaces/IVault.sol";
import { IVaultManager } from "../../interfaces/IVaultManager.sol";

import { IVaultDepositAssetCallback } from "../../interfaces/callbacks/IVaultDepositAssetCallback.sol";

import { IPointToken } from "../../interfaces/IPointToken.sol";
import { IRewardVaultMintCallback } from "../../interfaces/callbacks/IRewardVaultMintCallback.sol";
import { RewardManager } from "../reward-vault/RewardManager.sol";
import { Vault } from "./Vault.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract VaultManager is
    OwnableUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable,
    IVaultManager,
    RewardManager,
    IRewardVaultMintCallback
{
    IPointToken public immutable UNDERLYING_POINT_TOKEN;

    mapping(address => bool) public validVaults;

    constructor(IPointToken _underlyingPointToken) {
        UNDERLYING_POINT_TOKEN = _underlyingPointToken;
        _disableInitializers();
    }

    /// @notice Override the _authorizeUpgrade function inherited from UUPSUpgradeable contract
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {
        // No additional authorization logic is needed for this contract
    }

    function initialize() external initializer {
        __Ownable_init(msg.sender);
        __Pausable_init();
        __UUPSUpgradeable_init();
    }

    // --- onlyOwner functions ---

    function pause() external onlyOwner {
        _pause();
    }

    function resume() external onlyOwner {
        _unpause();
    }

    function createVault(IERC20 _asset, IERC20 _reward) public onlyOwner returns (address) {
        Vault vaultImpl = new Vault(_asset, _reward);
        bytes memory data = abi.encodeCall(Vault.initialize, (address(this)));
        address vault = address(new ERC1967Proxy(address(vaultImpl), data));
        if (isValidVault(vault)) {
            revert VaultAlreadyExists();
        }
        validVaults[vault] = true;
        emit VaultCreated(vault, address(_asset));
        return vault;
    }
    // --- public functions ---

    function getVault(address _vault) public view returns (address) {
        if (!isValidVault(_vault)) {
            revert VaultNotValid();
        }
        return _vault;
    }

    function isValidVault(address _vault) public view override returns (bool) {
        return validVaults[_vault];
    }

    function deposit(uint256 _assets, address _vault, address _receiver) public returns (uint256) {
        if (!isValidVault(_vault)) {
            revert VaultNotValid();
        }
        uint256 shares = IVault(_vault).deposit(_assets, msg.sender, _receiver);
        emit Deposit(_vault, _assets, _receiver);
        return shares;
    }

    function withdraw(uint256 _amount, address _vault, address _receiver, address _owner) public returns (uint256) {
        if (!isValidVault(_vault)) {
            revert VaultNotValid();
        }
        uint256 assets = IVault(_vault).withdraw(_amount, _receiver, _owner);
        emit Withdraw(_vault, _amount, _receiver, _owner);
        return assets;
    }

    function vaultDepositAssetCallback(address _asset, address _depositor, uint256 _amount, bytes calldata) external {
        if (!verifyCallback()) {
            revert InvalidCallbackCaller(msg.sender);
        }
        IERC20(_asset).transferFrom(_depositor, address(msg.sender), _amount);
    }

    function allocateReward(address, address[] memory, uint256[] memory) external returns (uint256[] memory) {
        revert("Not implemented");
    }

    function rewardVaultMintCallback(
        address reward,
        address recipient,
        uint256 amount,
        bytes calldata
    )
        external
        override
    {
        if (!isValidVault(msg.sender)) {
            revert InvalidRewardVault(msg.sender);
        }
        if (reward != address(UNDERLYING_POINT_TOKEN)) {
            revert InvalidReward(address(UNDERLYING_POINT_TOKEN), reward);
        }
        UNDERLYING_POINT_TOKEN.mint(recipient, amount);
    }

    function verifyCallback() public view returns (bool) {
        if (isValidVault(msg.sender)) {
            return true;
        }
        return false;
    }
}
