// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { MerkleLib } from "./utils/MerkleLib.sol";

import { Hashes } from "@openzeppelin/contracts/utils/cryptography/Hashes.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { Test } from "forge-std/Test.sol";

contract MerkleProofTest is Test {
    using MerkleLib for bytes32[];

    function testMerkleProof() public pure {
        bytes32[] memory hashList = new bytes32[](7);
        for (uint256 i = 0; i < 7; i++) {
            hashList[i] = keccak256(abi.encodePacked(i));
        }

        uint256 index = 1;

        (bytes32 root, bytes32[] memory proof) = MerkleLib.prepareMerkleRootAndProof(hashList, index);

        bool isValid = MerkleProof.verify(proof, root, hashList[index]);
        assertTrue(isValid, "Proof should be valid");
    }
}
