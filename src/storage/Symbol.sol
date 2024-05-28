// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// @audit change all functions to internal and param location to memory for easy testing
library Symbol {
    enum Status {
        OPEN,
        PAUSE,
        REDUCE_ONLY,
        SETTLED
    }

    struct Props {
        bytes32 code;
        Status status;
        address stakeToken;
        address indexToken;
        address baseToken;
        string baseTokenName;
    }

    function create(bytes32 code) internal returns (Props storage self) {
        self = load(code);
        self.code = code;
    }

    function load(bytes32 code) internal pure returns (Props storage self) {
        bytes32 s = keccak256(abi.encode("xyz.elfi.storage.Symbol", code));

        assembly {
            self.slot := s
        }
    }

    function isSupportIncreaseOrder(Props storage self) internal view returns (bool) {
        return self.status == Status.OPEN;
    }

    function isExists(Props storage self) internal view returns(bool) {
        return self.stakeToken != address(0);
    }
}
