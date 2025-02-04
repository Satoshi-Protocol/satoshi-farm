// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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

    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name, string memory symbol) external initializer {
        __ERC20_init(name, symbol);
        __ERC20Permit_init(name);
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
