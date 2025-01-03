// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { VaultConfig } from "./IVault.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVaultManager {
    error VaultNotValid();
    error VaultAlreadyExists();
    error InvalidVault();
    error InvalidAsset();
    error InvalidCallbackCaller(address caller);
    error InvalidShareOwner(address owner, address caller);

    event Deposit(address vault, uint256 assets, address receiver);
    event Withdraw(address vault, uint256 amount, address receiver, address owner);

    function deposit(uint256 assets, address vault, address receiver) external returns (uint256);

    function withdraw(uint256 amount, address vault, address receiver, address owner) external returns (uint256);

    function updateConfig(address vault, VaultConfig memory _config) external;
}
