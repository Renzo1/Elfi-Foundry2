// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../chain/ArbSys.sol";

// @audit change all functions to internal and param location to memory for easy testing
library ChainUtils {
    uint256 public constant ARBITRUM_CHAIN_ID = 42161;
    uint256 public constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;

    ArbSys public constant arbSys = ArbSys(address(100));

    function currentTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    function currentBlock() internal view returns (uint256) {
        if (block.chainid == ARBITRUM_CHAIN_ID || block.chainid == ARBITRUM_SEPOLIA_CHAIN_ID) {
            return arbSys.arbBlockNumber();
        }
        return block.number;
    }
}
