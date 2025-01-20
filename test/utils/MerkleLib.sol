// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Hashes } from "@openzeppelin/contracts/utils/cryptography/Hashes.sol";

library MerkleLib {
    function prepareMerkleLeaf(bytes memory data) internal pure returns (bytes32) {
        return keccak256(data);
    }

    function prepareMerkleRootAndProof(
        bytes32[] memory hashList,
        uint256 index
    )
        internal
        pure
        returns (bytes32 root, bytes32[] memory proof)
    {
        require(hashList.length > 0, "Empty hash list");
        require(index < hashList.length, "Index out of bounds");

        if (hashList.length == 1) {
            return (hashList[0], new bytes32[](0));
        }

        uint256 proofLength = 0;
        uint256 layer = hashList.length;
        while (layer > 1) {
            proofLength++;
            layer = (layer + 1) / 2;
        }

        proof = new bytes32[](proofLength);
        uint256 proofIndex = 0;
        uint256 currentIndex = index;
        layer = hashList.length;
        bytes32[] memory currentLayer = hashList;

        while (layer > 1) {
            bytes32[] memory newLayer = new bytes32[]((layer + 1) / 2);

            for (uint256 i = 0; i < layer - 1; i += 2) {
                if (i == currentIndex - (currentIndex % 2)) {
                    proof[proofIndex++] = currentLayer[i + (currentIndex % 2 == 0 ? 1 : 0)];
                }
                newLayer[i / 2] = Hashes.commutativeKeccak256(currentLayer[i], currentLayer[i + 1]);
            }

            // Handle odd number of elements
            if (layer % 2 == 1) {
                if (layer - 1 == currentIndex - (currentIndex % 2)) {
                    proof[proofIndex++] = currentLayer[layer - 1];
                }
                newLayer[(layer - 1) / 2] = currentLayer[layer - 1];
            }

            currentLayer = newLayer;
            currentIndex = currentIndex / 2;
            layer = (layer + 1) / 2;
        }

        return (currentLayer[0], proof);
    }

    function prepareMerkleProof(bytes32[] memory hashList, uint256 index) internal pure returns (bytes32[] memory) {
        require(hashList.length > 0, "Empty hash list");
        require(index < hashList.length, "Index out of bounds");

        uint256 proofLength = 0;
        uint256 layer = hashList.length;
        while (layer > 1) {
            proofLength++;
            layer = (layer + 1) / 2;
        }

        bytes32[] memory proof = new bytes32[](proofLength);
        uint256 proofIndex = 0;
        uint256 currentIndex = index;
        layer = hashList.length;
        bytes32[] memory currentLayer = hashList;

        while (layer > 1) {
            bytes32[] memory newLayer = new bytes32[]((layer + 1) / 2);

            for (uint256 i = 0; i < layer - 1; i += 2) {
                if (i == currentIndex - (currentIndex % 2)) {
                    proof[proofIndex++] = currentLayer[i + (currentIndex % 2 == 0 ? 1 : 0)];
                }
                newLayer[i / 2] = Hashes.commutativeKeccak256(currentLayer[i], currentLayer[i + 1]);
            }

            // Handle odd number of elements
            if (layer % 2 == 1) {
                newLayer[(layer - 1) / 2] = currentLayer[layer - 1];
            }

            currentLayer = newLayer;
            currentIndex = currentIndex / 2;
            layer = (layer + 1) / 2;
        }

        return proof;
    }

    function prepareMerkleRoot(bytes32[] memory hashList) internal pure returns (bytes32) {
        require(hashList.length > 0, "Empty hash list");

        if (hashList.length == 1) {
            return hashList[0];
        }

        uint256 layer = hashList.length;
        bytes32[] memory currentLayer = hashList;

        while (layer > 1) {
            bytes32[] memory newLayer = new bytes32[]((layer + 1) / 2);

            for (uint256 i = 0; i < layer - 1; i += 2) {
                newLayer[i / 2] = Hashes.commutativeKeccak256(currentLayer[i], currentLayer[i + 1]);
            }

            // Handle odd number of elements
            if (layer % 2 == 1) {
                newLayer[(layer - 1) / 2] = currentLayer[layer - 1];
            }

            currentLayer = newLayer;
            layer = (layer + 1) / 2;
        }

        return currentLayer[0];
    }
}
