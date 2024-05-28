// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// @audit change all functions to internal and param location to memory for easy testing
library OracleFeed {

    // enum OracleFrom {
    //     NONE, CHAINLINK
    // }

    struct Props {
        // OracleFrom from;
        mapping(address => address) feedUsdAddresses;
    }

    function load() internal pure returns(Props storage self) {
        bytes32 s = keccak256(abi.encode("xyz.elfi.storage.OracleFeed"));
        assembly {
            self.slot := s
        }
    }

    function create(address[] memory tokens, address[] memory usdFeeds) internal returns(Props storage feed) {
        feed = load();
        for (uint256 i; i < tokens.length; i++) {
            feed.feedUsdAddresses[tokens[i]] = usdFeeds[i];
        }
    }

    function getFeedUsdAddress(address token) internal view returns (address){
        Props storage feedProps = load();
        return feedProps.feedUsdAddresses[token];
    }

}
