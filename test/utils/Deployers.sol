// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { Vault } from "../../src/core/vault/Vault.sol";
import { VaultManager } from "../../src/core/vault/VaultManager.sol";

import { Gold } from "../../src/core/token/Gold.sol";
import { IPointToken } from "../../src/interfaces/IPointToken.sol";
import { IRewardManager } from "../../src/interfaces/IRewardManager.sol";
import { ITimeBasedRewardVault, RewardConfig } from "../../src/interfaces/ITimeBasedRewardVault.sol";
import { IVault } from "../../src/interfaces/IVault.sol";
import { IVaultManager } from "../../src/interfaces/IVaultManager.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Test } from "forge-std/Test.sol";
import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";

contract Deployers is Test {
    IERC20 public asset;

    IPointToken public gold;
    address public goldImpl;

    IVault public vault;

    address public managerImpl;
    IVaultManager public vaultManager;

    address public admin = address(0x1);

    address public user_1 = address(0x2);
    address public user_2 = address(0x3);

    function deployVaultManager(IPointToken _token) public returns (IVaultManager) {
        assert(address(_token) != address(0));
        managerImpl = address(new VaultManager(_token));
        bytes memory data = abi.encodeCall(VaultManager.initialize, ());
        vaultManager = IVaultManager(address(new ERC1967Proxy(address(managerImpl), data)));
        return vaultManager;
    }

    function createVault(IERC20 _asset, IERC20 _reward) public returns (IVault) {
        vault = IVault(vaultManager.createVault(_asset, _reward));
        return vault;
    }

    function setupRewardVault(uint256 _rewardRate) public {
        assert(address(gold) != address(0));
        assert(address(vault) != address(0));
        assert(address(vaultManager) != address(0));
        ITimeBasedRewardVault rewardVault = ITimeBasedRewardVault(address(vault));
        rewardVault.updateRewardConfig(RewardConfig(block.timestamp, type(uint256).max, _rewardRate));
    }

    // function allocateReward(uint256 _amount) public {
    //     assert(address(gold) != address(0));
    //     assert(address(vault) != address(0));
    //     assert(address(vaultManager) != address(0));
    //     deal(address(gold), admin, _amount);
    //     ITimeBasedRewardVault rewardVault = ITimeBasedRewardVault(address(vault));
    //     IRewardManager rewardManager = IRewardManager(address(vaultManager));
    //     assert(address(gold) == rewardVault.reward());
    //     rewardVault.updateRewardConfig(RewardConfig(block.timestamp, type(uint256).max, 1e10));
    //     gold.approve(address(vaultManager), _amount);
    //     address[] memory rewardVaults = new address[](1);
    //     rewardVaults[0] = address(vault);
    //     uint256[] memory amounts = new uint256[](1);
    //     amounts[0] = _amount;
    //     rewardManager.allocateReward(address(gold), rewardVaults, amounts);
    // }

    function deployToken(string memory _name, string memory _symbol, uint8 _decimals) public returns (IERC20) {
        MockERC20 token = new MockERC20(_name, _symbol, _decimals);
        return IERC20(address(token));
    }

    function deployGold() public returns (IPointToken) {
        goldImpl = address(new Gold());
        bytes memory data = abi.encodeCall(Gold.initialize, ());
        gold = IPointToken(address(new ERC1967Proxy(address(goldImpl), data)));
        return gold;
    }

    function setGoldAuthorized(address _account, bool _authorized) public {
        IPointToken(address(gold)).setAuthorized(_account, _authorized);
    }
}
