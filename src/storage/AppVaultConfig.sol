// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./AppStorage.sol";

// @audit change all functions to internal and param location to memory for easy testing
library AppVaultConfig {
    using AppStorage for AppStorage.Props;

    // -- vault config keys --
    bytes32 internal constant TRADE_VAULT = keccak256(abi.encode("TRADE_VAULT"));
    bytes32 internal constant LP_VAULT = keccak256(abi.encode("LP_VAULT"));
    bytes32 internal constant PORTFOLIO_VAULT = keccak256(abi.encode("PORTFOLIO_VAULT"));

    function getTradeVault() internal view returns (address) {
        AppStorage.Props storage app = AppStorage.load();
        return app.getAddressValue(keccak256(abi.encode(AppStorage.VAULT_CONFIG, TRADE_VAULT)));
    }

    function setTradeVault(address vault) internal {
        AppStorage.Props storage app = AppStorage.load();
        app.setAddressValue(keccak256(abi.encode(AppStorage.VAULT_CONFIG, TRADE_VAULT)), vault);
    }

    function getLpVault() internal view returns (address) {
        AppStorage.Props storage app = AppStorage.load();
        return app.getAddressValue(keccak256(abi.encode(AppStorage.VAULT_CONFIG, LP_VAULT)));
    }

    function setLpVault(address vault) internal {
        AppStorage.Props storage app = AppStorage.load();
        app.setAddressValue(keccak256(abi.encode(AppStorage.VAULT_CONFIG, LP_VAULT)), vault);
    }

    function getPortfolioVault() internal view returns (address) {
        AppStorage.Props storage app = AppStorage.load();
        return app.getAddressValue(keccak256(abi.encode(AppStorage.VAULT_CONFIG, PORTFOLIO_VAULT)));
    }

    function setPortfolioVault(address vault) internal {
        AppStorage.Props storage app = AppStorage.load();
        app.setAddressValue(keccak256(abi.encode(AppStorage.VAULT_CONFIG, PORTFOLIO_VAULT)), vault);
    }
}
