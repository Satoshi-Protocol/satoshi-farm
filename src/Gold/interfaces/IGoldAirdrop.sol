// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IGold } from "./IGold.sol";

interface IGoldAirdrop {
    error InvalidTime(uint256 currentTime, uint256 startTime, uint256 endTime);
    error AlreadyClaimed(bytes32 leaf);
    error InvalidProof(bytes32[] merkleProof, bytes32 merkleRoot, bytes32 leaf);

    event AirdropTimeUpdated(uint256 indexed startTime, uint256 indexed endTime);
    event MerkleRootUpdated(bytes32 indexed merkleRoot);
    event Claimed(bytes32 indexed leaf, address indexed account, uint256 indexed amount);

    function gold() external view returns (IGold);

    function startTime() external view returns (uint256);

    function endTime() external view returns (uint256);

    function merkleRoot() external view returns (bytes32);

    function initialize(address _gold, uint256 _startTime, uint256 _endTime, bytes32 _merkleRoot) external;

    function setAirdropTime(uint256 _startTime, uint256 _endTime) external;

    function setMerkleRoot(bytes32 _merkleRoot) external;

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external;

    function isClaimed(bytes32 leaf) external view returns (bool);

    function isValidTime() external returns (bool);
}
