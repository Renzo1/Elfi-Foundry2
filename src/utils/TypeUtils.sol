// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// @audit change all functions to internal and param location to memory for easy testing
library TypeUtils {

    error Bytes32Empty();
    error StringEmpty();
    error IntZero();

    function bytes32Equals(bytes32 a, bytes32 b) internal pure returns (bool) {
        if (a.length != b.length) 
            return false;
        for (uint256 i; i < a.length; i++) {
            if (a[i] != b[i])
                return false;
        } 
        return true;      
    }
    
    function isBytes32Empty(bytes32 data) internal pure returns (bool){
        return data.length == 0;
    }

    function validNotZero(uint data) internal pure {
        if (data == 0) {
            revert IntZero();
        }
    }

    function validBytes32Empty(bytes32 data) internal pure {
        if (data.length == 0) {
            revert Bytes32Empty();
        }
    }

    function validStringEmpty(string memory data) internal pure {
        if (bytes(data).length == 0) {
            revert StringEmpty();
        }
    }


}