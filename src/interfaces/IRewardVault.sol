// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardVault {
    event ClaimReward(address reward, uint256 amount, address owner, address recipient);
    event AllocateReward(address reward, uint256 amount);

    function previewReward(address owner) external view returns (uint256);

    function claimReward(address owner, address recipient) external returns (uint256);

    function allocateReward(address caller, address reward, uint256 amount) external returns (uint256);

    function reward() external view returns (address);

    function getPendingReward(address user) external view returns (uint256);

    function totalShares() external view returns (uint256);
}
