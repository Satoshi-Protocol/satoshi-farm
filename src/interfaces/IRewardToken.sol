// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IOFT } from "./layerzero/IOFT.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IRewardToken is IOFT, IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}
