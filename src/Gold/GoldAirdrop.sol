// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IMerkleDistributor} from "../interfaces/IMerkleDistributor.sol";
import {IGold} from "./IGold.sol";

contract GoldAirdrop is IMerkleDistributor, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    struct RewardConfig {
        uint8 startTime;
        uint8 endTime;
        uint256 penalty; // (50) 50% penalty
        address vault;
    }

    uint256 constant public PENALTY_PRECISION = 100;
    IGold public gold;
    bytes32 public merkleRoot;
    RewardConfig public rewardConfig;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function initialize(address gold_, bytes32 merkleRoot_) external initializer {
        __UUPSUpgradeable_init();
        __Ownable_init(msg.sender);
        gold = IGold(gold_);
        merkleRoot = merkleRoot_;
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function isValidTime(uint8 time) public view returns (bool) {
        return time >= rewardConfig.startTime && time <= rewardConfig.endTime;
    }

    // @param amount0 amount of gold to withdraw
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof)
        public
        virtual
    {
        if (!isValidTime(uint8(block.timestamp))) revert InvalidTime();
        if (isClaimed(index)) revert AlreadyClaimed();

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        if (!MerkleProof.verify(merkleProof, merkleRoot, node)) revert InvalidProof();

        // Mark it claimed and send the token.
        _setClaimed(index);

        // @todo

        emit Claimed(index, account, amount);
    }
}