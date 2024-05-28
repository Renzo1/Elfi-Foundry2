// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// @audit change all functions to internal and param location to memory for easy testing
library Mint {
    bytes32 constant MINT_KEY = keccak256(abi.encode("xyz.elfi.storage.Mint"));

    struct Props {
        mapping(uint256 => Request) requests;
    }

    struct Request {
        address account;
        address stakeToken;
        address requestToken;
        uint256 requestTokenAmount;
        uint256 walletRequestTokenAmount;
        uint256 minStakeAmount;
        uint256 executionFee;
        bool isCollateral;
        bool isExecutionFeeFromLpVault;
    }

    function load() internal pure returns (Props storage self) {
        bytes32 s = MINT_KEY;
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
