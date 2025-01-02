// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { Vault } from "../../src/core/vault/Vault.sol";
import { VaultManager } from "../../src/core/vault/VaultManager.sol";

import { FarmingVaultManager } from "../../src/FarmingVaultManager.sol";
import { Gold } from "../../src/core/token/Gold.sol";
import { IPointToken } from "../../src/interfaces/IPointToken.sol";
import { IRewardManager } from "../../src/interfaces/IRewardManager.sol";
import { ITimeBasedRewardVault, RewardConfig } from "../../src/interfaces/ITimeBasedRewardVault.sol";
import { IVault, VaultConfig } from "../../src/interfaces/IVault.sol";
import { IVaultManager } from "../../src/interfaces/IVaultManager.sol";

import { FarmingVaultConfig, IFarmingVault } from "../../src/interfaces/IFarmingVault.sol";
import { FarmingVaultGlobalConfig, IFarmingVaultManager } from "../../src/interfaces/IFarmingVaultManager.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Test } from "forge-std/Test.sol";
import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";

contract FarmingVaultDeployers is Test {
    address public admin = address(0x1);
    address public user_1 = address(0x2);
    address public user_2 = address(0x3);

    IERC20 public asset;

    IPointToken public gold;
    address public goldImpl;

    IFarmingVaultManager public manager;
    address public managerImpl;
    IFarmingVault public goldFarmingVault;
    IFarmingVault public farmingVault;

    function deployFarmingVaultManager(
        IPointToken _token,
        uint256 _refundRatio
    )
        public
        returns (IFarmingVaultManager)
    {
        assert(address(_token) != address(0));
        managerImpl = address(new FarmingVaultManager());
        bytes memory data =
            abi.encodeCall(FarmingVaultManager.initialize, (_token, FarmingVaultGlobalConfig(_refundRatio)));
        manager = IFarmingVaultManager(address(new ERC1967Proxy(address(managerImpl), data)));
        return manager;
    }

    function createGoldFarmingVault(IERC20 _gold) public returns (IFarmingVault) {
        goldFarmingVault = IFarmingVault(manager.createVault(_gold, _gold, abi.encode(address(0))));
        return goldFarmingVault;
    }

    function createFarmingVault(
        IERC20 _asset,
        IERC20 _reward,
        address _goldFarmingVault
    )
        public
        returns (IFarmingVault)
    {
        farmingVault = IFarmingVault(manager.createVault(_asset, _reward, abi.encode(_goldFarmingVault)));
        return farmingVault;
    }

    function setupRewardVault(address _vault, uint256 _rewardRate, uint256 _claimStartTime) public {
        assert(address(_vault) != address(0));
        IRewardManager(address(manager)).updateRewardConfig(
            _vault, RewardConfig(block.timestamp, type(uint256).max, _rewardRate, _claimStartTime, type(uint256).max)
        );
    }

    function setupFarmingVault(
        address _vault,
        uint256 _rewardRate,
        uint256 _claimStartTime,
        uint256 _maxAsset
    )
        public
    {
        assert(address(_vault) != address(0));
        manager.updateFarmingVaultConfig(
            _vault,
            VaultConfig(_maxAsset),
            RewardConfig(block.timestamp, type(uint256).max, _rewardRate, _claimStartTime, type(uint256).max)
        );
    }

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
