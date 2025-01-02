// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

struct VaultConfig {
    uint256 maxAsset;
}

interface IVault is IERC4626 {
    error InvalidAsset();
    error InvalidStrategy();
    error InvalidAmount();
    error InvalidReceiver();
    error InvalidManager(address manager);
    error InvalidOwner(address owner);
    error AssetBalanceChangedUnexpectedly(uint256 expected, uint256 actual);
    error InsufficientAssetBalance(uint256 expected, uint256 actual);
    error MaxAssetExceeded(uint256 amount, uint256 maxAsset);

    event Deposit(uint256 assets, address receiver);
    event Withdraw(uint256 assets, address receiver, address owner);

    function deposit(uint256 assets, address depositor, address receiver) external returns (uint256);

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256);

    function asset() external view returns (address);

    function totalAssets() external view returns (uint256);

    function config() external view returns (VaultConfig memory);

    function updateConfig(VaultConfig memory _config) external;
}
