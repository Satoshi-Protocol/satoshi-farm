// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IGold is IERC20 {
    function initialize(string memory name, string memory symbol) external;

    function wards(address) external view returns (bool);

    function rely(address usr) external;

    function deny(address usr) external;

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}
