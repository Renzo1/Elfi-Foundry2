// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// @audit change all functions to internal and param location to memory for easy testing
library AddressUtils {
    uint256 internal constant TEST = 1000;

    error AddressZero();

    function validEmpty(address addr) internal pure {
        if (addr == address(0)) {
            revert AddressZero();
        }
    }

}
