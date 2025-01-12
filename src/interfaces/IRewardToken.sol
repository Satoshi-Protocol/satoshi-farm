// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IRewardToken is IERC20 {
    
    function initialize() external;
    
    function wards(address) external view returns (bool);
    
    function rely(address usr) external;
    
    function deny(address usr) external;
    
    function mint(address to, uint256 amount) external;
    
    function burn(address from, uint256 amount) external;
}
