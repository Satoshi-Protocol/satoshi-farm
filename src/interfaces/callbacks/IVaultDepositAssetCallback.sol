// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVaultDepositAssetCallback {
    function vaultDepositAssetCallback(address asset, address from, uint256 amount, bytes calldata data) external;
}
