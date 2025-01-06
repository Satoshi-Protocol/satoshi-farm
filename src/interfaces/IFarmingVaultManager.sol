// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { FarmingVaultConfig } from "./IFarmingVault.sol";
import { RewardConfig } from "./ITimeBasedRewardVault.sol";
import { VaultConfig } from "./IVault.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IFarmingVaultManager {
    error InvalidFarmingVault(address vault);
    error InvalidAdmin(address expected, address actual);

    event VaultCreated(address vault, address asset);

    function createVault(IERC20 asset, IERC20 reward, bytes memory data) external returns (address);

    function claimAndStake(
        address vault,
        address _receiver,
        uint256 _stakeAmount
    )
        external
        returns (uint256, uint256);

    function updateFarmingVaultConfig(
        address vault,
        FarmingVaultConfig memory _config,
        VaultConfig memory _vaultConfig,
        RewardConfig memory _rewardConfig
    )
        external;

    function isValidFarmingVault(address vault) external view returns (bool);
}
