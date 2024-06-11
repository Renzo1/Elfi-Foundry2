// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./AppStorage.sol";

// @audit change all functions to internal and param location to memory for easy testing
library AppConfig {
    using AppStorage for AppStorage.Props;

    // -- symbol config keys --
    bytes32 internal constant MAX_LEVERAGE = keccak256(abi.encode("MAX_LEVERAGE"));
    bytes32 internal constant TICK_SIZE = keccak256(abi.encode("TICK_SIZE"));
    bytes32 internal constant OPEN_FEE_RATE = keccak256(abi.encode("OPEN_FEE_RATE"));
    bytes32 internal constant CLOSE_FEE_RATE = keccak256(abi.encode("CLOSE_FEE_RATE"));
    bytes32 internal constant MAX_LONG_OPEN_INTEREST_CAP = keccak256(abi.encode("MAX_LONG_OPEN_INTEREST_CAP"));
    bytes32 internal constant MAX_SHORT_OPEN_INTEREST_CAP = keccak256(abi.encode("MAX_SHORT_OPEN_INTEREST_CAP"));
    bytes32 internal constant LONG_SHORT_RATIO_LIMIT = keccak256(abi.encode("LONG_SHORT_RATIO_LIMIT"));
    bytes32 internal constant LONG_SHORT_OI_BOTTOM_LIMIT = keccak256(abi.encode("LONG_SHORT_OI_BOTTOM_LIMIT"));

    // -- chain config keys --
    bytes32 internal constant WRAPPER_TOKEN = keccak256(abi.encode("WRAPPER_TOKEN"));
    bytes32 internal constant MINT_GAS_FEE_LIMIT = keccak256(abi.encode("MINT_GAS_FEE_LIMIT"));
    bytes32 internal constant REDEEM_GAS_FEE_LIMIT = keccak256(abi.encode("REDEEM_GAS_FEE_LIMIT"));
    bytes32 internal constant PLACE_INCREASE_ORDER_GAS_FEE_LIMIT =
        keccak256(abi.encode("PLACE_INCREASE_ORDER_GAS_FEE_LIMIT"));
    bytes32 internal constant PLACE_DECREASE_ORDER_GAS_FEE_LIMIT =
        keccak256(abi.encode("PLACE_DECREASE_ORDER_GAS_FEE_LIMIT"));
    bytes32 internal constant POSITION_UPDATE_MARGIN_GAS_FEE_LIMIT =
        keccak256(abi.encode("POSITION_UPDATE_MARGIN_GAS_FEE_LIMIT"));
    bytes32 internal constant POSITION_UPDATE_LEVERAGE_GAS_FEE_LIMIT =
        keccak256(abi.encode("POSITION_UPDATE_LEVERAGE_GAS_FEE_LIMIT"));
    bytes32 internal constant WITHDRAW_GAS_FEE_LIMIT = keccak256(abi.encode("WITHDRAW_GAS_FEE_LIMIT"));
    bytes32 internal constant CLAIM_REWARDS_GAS_FEE_LIMIT = keccak256(abi.encode("CLAIM_REWARDS_GAS_FEE_LIMIT"));

    bytes32 internal constant UNISWAP_ROUTER = keccak256(abi.encode("UNISWAP_ROUTER"));

    struct SymbolConfig {
        uint256 maxLeverage;
        uint256 tickSize;
        uint256 openFeeRate;
        uint256 closeFeeRate;
        uint256 maxLongOpenInterestCap;
        uint256 maxShortOpenInterestCap;
        uint256 longShortRatioLimit;
        uint256 longShortOiBottomLimit;
    }

    struct ChainConfig {
        address wrapperToken;
        uint256 mintGasFeeLimit;
        uint256 redeemGasFeeLimit;
        uint256 placeIncreaseOrderGasFeeLimit;
        uint256 placeDecreaseOrderGasFeeLimit;
        uint256 positionUpdateMarginGasFeeLimit;
        uint256 positionUpdateLeverageGasFeeLimit;
        uint256 withdrawGasFeeLimit;
        uint256 claimRewardsGasFeeLimit;
    }

    function getSymbolConfig(bytes32 symbol) internal view returns (SymbolConfig memory) {
        SymbolConfig memory config;
        AppStorage.Props storage app = AppStorage.load();
        bytes32 key = AppStorage.SYMBOL_CONFIG;
        if (!app.containsBytes32(key, symbol)) {
            return config;
        }
        config.maxLeverage = app.getUintValue(keccak256(abi.encode(key, symbol, MAX_LEVERAGE)));
        config.tickSize = app.getUintValue(keccak256(abi.encode(key, symbol, TICK_SIZE)));
        config.openFeeRate = app.getUintValue(keccak256(abi.encode(key, symbol, OPEN_FEE_RATE)));
        config.closeFeeRate = app.getUintValue(keccak256(abi.encode(key, symbol, CLOSE_FEE_RATE)));
        config.maxLongOpenInterestCap = app.getUintValue(
            keccak256(abi.encode(key, symbol, MAX_LONG_OPEN_INTEREST_CAP))
        );
        config.maxShortOpenInterestCap = app.getUintValue(
            keccak256(abi.encode(key, symbol, MAX_SHORT_OPEN_INTEREST_CAP))
        );
        config.longShortRatioLimit = app.getUintValue(keccak256(abi.encode(key, symbol, LONG_SHORT_RATIO_LIMIT)));
        config.longShortOiBottomLimit = app.getUintValue(
            keccak256(abi.encode(key, symbol, LONG_SHORT_OI_BOTTOM_LIMIT))
        );
        return config;
    }

    function setSymbolConfig(bytes32 symbol, SymbolConfig memory config) internal {
        AppStorage.Props storage app = AppStorage.load();
        bytes32 key = AppStorage.SYMBOL_CONFIG;
        app.addBytes32(key, symbol);
        app.setUintValue(keccak256(abi.encode(key, symbol, MAX_LEVERAGE)), config.maxLeverage);
        app.setUintValue(keccak256(abi.encode(key, symbol, TICK_SIZE)), config.tickSize);
        app.setUintValue(keccak256(abi.encode(key, symbol, OPEN_FEE_RATE)), config.openFeeRate);
        app.setUintValue(keccak256(abi.encode(key, symbol, CLOSE_FEE_RATE)), config.closeFeeRate);
        app.setUintValue(keccak256(abi.encode(key, symbol, MAX_LONG_OPEN_INTEREST_CAP)), config.maxLongOpenInterestCap);
        app.setUintValue(
            keccak256(abi.encode(key, symbol, MAX_SHORT_OPEN_INTEREST_CAP)),
            config.maxShortOpenInterestCap
        );
        app.setUintValue(keccak256(abi.encode(key, symbol, LONG_SHORT_RATIO_LIMIT)), config.longShortRatioLimit);
        app.setUintValue(keccak256(abi.encode(key, symbol, LONG_SHORT_OI_BOTTOM_LIMIT)), config.longShortOiBottomLimit);
    }

    function getChainConfig() internal view returns (ChainConfig memory chainConfig) {
        AppStorage.Props storage app = AppStorage.load();
        bytes32 key = AppStorage.CHAIN_CONFIG;
        chainConfig.wrapperToken = app.getAddressValue(keccak256(abi.encode(key, WRAPPER_TOKEN)));
        chainConfig.mintGasFeeLimit = app.getUintValue(keccak256(abi.encode(key, MINT_GAS_FEE_LIMIT)));
        chainConfig.redeemGasFeeLimit = app.getUintValue(keccak256(abi.encode(key, REDEEM_GAS_FEE_LIMIT)));
        chainConfig.placeIncreaseOrderGasFeeLimit = app.getUintValue(
            keccak256(abi.encode(key, PLACE_INCREASE_ORDER_GAS_FEE_LIMIT))
        );
        chainConfig.placeDecreaseOrderGasFeeLimit = app.getUintValue(
            keccak256(abi.encode(key, PLACE_DECREASE_ORDER_GAS_FEE_LIMIT))
        );
        chainConfig.positionUpdateMarginGasFeeLimit = app.getUintValue(
            keccak256(abi.encode(key, POSITION_UPDATE_MARGIN_GAS_FEE_LIMIT))
        );
        chainConfig.positionUpdateLeverageGasFeeLimit = app.getUintValue(
            keccak256(abi.encode(key, POSITION_UPDATE_LEVERAGE_GAS_FEE_LIMIT))
        );
        chainConfig.withdrawGasFeeLimit = app.getUintValue(keccak256(abi.encode(key, WITHDRAW_GAS_FEE_LIMIT)));
        chainConfig.claimRewardsGasFeeLimit = app.getUintValue(keccak256(abi.encode(key, CLAIM_REWARDS_GAS_FEE_LIMIT)));
    }

    function setChainConfig(ChainConfig memory chainConfig) internal {
        AppStorage.Props storage app = AppStorage.load();
        bytes32 key = AppStorage.CHAIN_CONFIG;
        app.setAddressValue(keccak256(abi.encode(key, WRAPPER_TOKEN)), chainConfig.wrapperToken);
        app.setUintValue(keccak256(abi.encode(key, MINT_GAS_FEE_LIMIT)), chainConfig.mintGasFeeLimit);
        app.setUintValue(keccak256(abi.encode(key, REDEEM_GAS_FEE_LIMIT)), chainConfig.redeemGasFeeLimit);
        app.setUintValue(
            keccak256(abi.encode(key, PLACE_INCREASE_ORDER_GAS_FEE_LIMIT)),
            chainConfig.placeIncreaseOrderGasFeeLimit
        );
        app.setUintValue(
            keccak256(abi.encode(key, PLACE_DECREASE_ORDER_GAS_FEE_LIMIT)),
            chainConfig.placeDecreaseOrderGasFeeLimit
        );
        app.setUintValue(
            keccak256(abi.encode(key, POSITION_UPDATE_MARGIN_GAS_FEE_LIMIT)),
            chainConfig.positionUpdateMarginGasFeeLimit
        );
        app.setUintValue(
            keccak256(abi.encode(key, POSITION_UPDATE_LEVERAGE_GAS_FEE_LIMIT)),
            chainConfig.positionUpdateLeverageGasFeeLimit
        );
        app.setUintValue(keccak256(abi.encode(key, WITHDRAW_GAS_FEE_LIMIT)), chainConfig.withdrawGasFeeLimit);
        app.setUintValue(keccak256(abi.encode(key, CLAIM_REWARDS_GAS_FEE_LIMIT)), chainConfig.claimRewardsGasFeeLimit);
    }

    function setUniswapRouter(address router) internal {
        AppStorage.Props storage app = AppStorage.load();
        app.setAddressValue(keccak256(abi.encode(AppStorage.COMMON_CONFIG, UNISWAP_ROUTER)), router);
    }

    function getUniswapRouter() internal view returns (address) {
        AppStorage.Props storage app = AppStorage.load();
        return app.getAddressValue(keccak256(abi.encode(AppStorage.COMMON_CONFIG, UNISWAP_ROUTER)));
    }
}
