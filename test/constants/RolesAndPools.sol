// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


library RolesAndPools {

  /// Roles Configurations
  bytes32 internal constant ROLE_ADMIN = "ADMIN";
  bytes32 internal constant ROLE_UPGRADE = "UPGRADE";
  bytes32 internal constant ROLE_CONFIG = "CONFIG";
  bytes32 internal constant ROLE_KEEPER = "KEEPER";


  /// Pools Configurations
  bytes32 internal constant codeHash1 = "WETHUSDC";
  bytes32 internal constant codeHash2 = "WBTCUSDC";
  string internal constant stakedWeth = "xETH";
  string internal constant stakedWbtc = "xBTC";
  string internal constant stakedUsdc = "xUSD";
  

    function getRoleAdmin() internal pure returns (bytes32) {
        return ROLE_ADMIN;
    }

    function getRoleUpgrade() internal pure returns (bytes32) {
        return ROLE_UPGRADE;
    }

    function getRoleConfig() internal pure returns (bytes32) {
        return ROLE_CONFIG;
    }

    function getRoleKeeper() internal pure returns (bytes32) {
        return ROLE_KEEPER;
    }

    function getCodeHash1() internal pure returns (bytes32) {
        return codeHash1;
    }

    function getCodeHash2() internal pure returns (bytes32) {
        return codeHash2;
    }

    function getStakedWeth() internal pure returns (string memory) {
        return stakedWeth;
    }

    function getStakedWbtc() internal pure returns (string memory) {
        return stakedWbtc;
    }

    function getStakedUsdc() internal pure returns (string memory) {
        return stakedUsdc;
    }

}