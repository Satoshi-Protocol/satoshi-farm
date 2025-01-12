// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ERC20PermitUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";

contract Gold is ERC20Upgradeable, ERC20PermitUpgradeable, OwnableUpgradeable {
    mapping(address => bool) public wards;

    modifier auth() {
        require(wards[msg.sender], "DebtToken: not-authorized");
        _;
    }

    function initialize() external initializer {
        __ERC20_init("Gold", "GOLD");
        __ERC20Permit_init("Gold");
        __Ownable_init(msg.sender);
    }

    function rely(address usr) external onlyOwner {
        wards[usr] = true;
    }

    function deny(address usr) external onlyOwner {
        wards[usr] = false;
    }

    function mint(address to, uint256 amount) external auth {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external auth {
        _burn(from, amount);
    }
}
