// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


library WbtcTradeConfig {

    bool internal constant WBTC_IS_SUPPORT_COLLATERAL = true;
    uint256 internal constant WBTC_PRECISION = 6;
    uint256 internal constant WBTC_DISCOUNT = 99 * 1e3;
    uint256 internal constant WBTC_COLLATERAL_USER_CAP = 10 * 1e18;
    uint256 internal constant WBTC_COLLATERAL_TOTAL_CAP = 10_000 * 1e18;
    uint256 internal constant WBTC_LIABILITY_USER_CAP = 1 * 1e17;
    uint256 internal constant WBTC_LIABILITY_TOTAL_CAP = 5 * 1e18;
    uint256 internal constant WBTC_INTEREST_RATE_FACTOR = 10;
    uint256 internal constant WBTC_LIQUIDATION_FACTOR = 5 * 1e3;

    
    function getWbtcIsSupportCollateral() internal pure returns (bool) {
        return WBTC_IS_SUPPORT_COLLATERAL;
    }
    
    function getWbtcPrecision() internal pure returns (uint256) {
        return WBTC_PRECISION;
    }
    
    function getWbtcDiscount() internal pure returns (uint256) {
        return WBTC_DISCOUNT;
    }
    
    function getWbtcCollateralUserCap() internal pure returns (uint256) {
        return WBTC_COLLATERAL_USER_CAP;
    }
    
    function getWbtcCollateralTotalCap() internal pure returns (uint256) {
        return WBTC_COLLATERAL_TOTAL_CAP;
    }
    
    function getWbtcLiabilityUserCap() internal pure returns (uint256) {
        return WBTC_LIABILITY_USER_CAP;
    }
    
    function getWbtcLiabilityTotalCap() internal pure returns (uint256) {
        return WBTC_LIABILITY_TOTAL_CAP;
    }
    
    function getWbtcInterestRateFactor() internal pure returns (uint256) {
        return WBTC_INTEREST_RATE_FACTOR;
    }
    
    function getWbtcLiquidationFactor() internal pure returns (uint256) {
        return WBTC_LIQUIDATION_FACTOR;
    }
    
}