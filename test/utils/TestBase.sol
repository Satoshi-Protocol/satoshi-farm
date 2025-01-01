// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Test } from "forge-std/Test.sol";

contract TestBase is Test {
    function checkBalance(IERC20 token, address user, uint256 expectedBalance) public view {
        uint256 balance = token.balanceOf(user);
        assertEq(balance, expectedBalance);
    }
}
