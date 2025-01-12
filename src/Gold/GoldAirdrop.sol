// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IGold } from "./interfaces/IGold.sol";
import { IGoldAirdrop } from "./interfaces/IGoldAirdrop.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GoldAirdrop is IGoldAirdrop, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    IGold public gold;
    // airdrop config
    uint256 public startTime;
    uint256 public endTime;
    bytes32 public merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }

    function initialize(
        address _gold,
        uint256 _startTime,
        uint256 _endTime,
        bytes32 _merkleRoot
    )
        external
        initializer
    {
        __UUPSUpgradeable_init();
        __Ownable_init(msg.sender);

        gold = IGold(_gold);
        startTime = _startTime;
        endTime = _endTime;
        merkleRoot = _merkleRoot;

        emit AirdropTimeUpdated(_startTime, _endTime);
        emit MerkleRootUpdated(_merkleRoot);
    }

    function setAirdropTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
        startTime = _startTime;
        endTime = _endTime;

        emit AirdropTimeUpdated(_startTime, _endTime);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;

        emit MerkleRootUpdated(_merkleRoot);
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

    function isValidTime() public view returns (bool) {
        return block.timestamp >= startTime && block.timestamp <= endTime;
    }

    // @param amount0 amount of gold to withdraw
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external virtual {
        if (!isValidTime()) revert InvalidTime(block.timestamp, startTime, endTime);
        if (isClaimed(index)) revert AlreadyClaimed(index);

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encode(index, account, amount));
        if (!MerkleProof.verify(merkleProof, merkleRoot, node)) revert InvalidProof(merkleProof, merkleRoot, node);

        // Mark it claimed and send the token.
        _setClaimed(index);

        gold.mint(account, amount);

        emit Claimed(index, account, amount, node);
    }
}
