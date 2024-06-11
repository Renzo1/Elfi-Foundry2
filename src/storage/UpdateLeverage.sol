// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// @audit change all functions to internal and param location to memory for easy testing
library UpdateLeverage {
    bytes32 internal constant KEY = keccak256(abi.encode("xyz.elfi.storage.UpdateLeverage"));

    struct Props {
        mapping(uint256 => Request) requests;
    }

    struct Request {
        address account;
        bytes32 symbol;
        bool isLong;
        bool isExecutionFeeFromTradeVault;
        bool isCrossMargin;
        uint256 leverage;
        address marginToken;
        uint256 addMarginAmount;
        uint256 executionFee;
        uint256 lastBlock;
    }

    function load() internal pure returns (Props storage self) {
        bytes32 s = KEY;
        assembly {
            self.slot := s
        }
    }

    function create(uint256 requestId) internal view returns (Request storage) {
        Props storage self = load();
        return self.requests[requestId];
    }

    function get(uint256 requestId) internal view returns (Request memory) {
        Props storage self = load();
        return self.requests[requestId];
    }

    function remove(uint256 requestId) internal {
        Props storage self = load();
        delete self.requests[requestId];
    }
}
