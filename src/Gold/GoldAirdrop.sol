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
    mapping(bytes32 => bool) internal _claimed;

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

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external {
        if (!isValidTime()) revert InvalidTime(block.timestamp, startTime, endTime);

        // Verify the merkle proof
        bytes32 leaf = keccak256(abi.encode(account, amount));
        if (_isClaimed(leaf)) revert AlreadyClaimed(leaf);
        if (!MerkleProof.verify(merkleProof, merkleRoot, leaf)) revert InvalidProof(merkleProof, merkleRoot, leaf);

        // update claimed
        _setClaimed(leaf);

        // mint gold
        gold.mint(account, amount);

        emit Claimed(leaf, account, amount);
    }

    function isClaimed(bytes32 leaf) external view returns (bool) {
        return _isClaimed(leaf);
    }

    function isValidTime() public view returns (bool) {
        return block.timestamp >= startTime && block.timestamp <= endTime;
    }

    function _isClaimed(bytes32 leaf) internal view returns (bool) {
        return _claimed[leaf];
    }

    function _setClaimed(bytes32 leaf) internal {
        _claimed[leaf] = true;
    }
}
