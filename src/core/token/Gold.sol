// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IRewardToken } from "../../interfaces/IRewardToken.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract Gold is ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable, IRewardToken {
    // --- Auth ---
    mapping(address => bool) public authorized;

    constructor() {
        _disableInitializers();
    }

    /// @notice Override the _authorizeUpgrade function inherited from UUPSUpgradeable contract
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {
        // No additional authorization logic is needed for this contract
    }

    function initialize() external initializer {
        __ERC20_init("Gold", "GLD");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init_unchained();
    }

    function mint(address to, uint256 amount) external override {
        require(authorized[msg.sender], "Gold: Not authorized");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external override {
        if (msg.sender != from) {
            revert("Gold: Not authorized");
        }
        _burn(from, amount);
    }

    function setAuthorized(address account, bool _authorized) external override onlyOwner {
        authorized[account] = _authorized;
    }
}
