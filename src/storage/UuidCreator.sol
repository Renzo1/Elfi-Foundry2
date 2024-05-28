// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// @audit change all functions to internal and param location to memory for easy testing
library UuidCreator {
    bytes32 private constant _UUID_CREATOR = keccak256(abi.encode("xyz.elfi.storage.UuidCreator"));

    uint256 private constant MIN_ID = 1111;

    struct Props {
        mapping(bytes32 => uint256) lastIds;
    }

    function load() internal pure returns (Props storage self) {
        bytes32 s = _UUID_CREATOR;

        assembly {
            self.slot := s
        }
    }

    function nextId(bytes32 key) internal returns (uint256) {
        Props storage self = load();
        uint256 lastId = self.lastIds[key];
        if (lastId < MIN_ID) {
            lastId = MIN_ID + 1;
        } else {
            lastId++;
        }
        self.lastIds[key] = lastId;
        return lastId;
    }

    function getId(bytes32 key) internal view returns (uint256) {
        Props storage self = load();
        return self.lastIds[key];
    }
}
