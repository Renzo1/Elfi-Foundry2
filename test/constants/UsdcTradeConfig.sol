// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


library UsdcTradeConfig {

    bool internal constant USDC_IS_SUPPORT_COLLATERAL = true;
    uint256 internal constant USDC_PRECISION = 2;
    uint256 internal constant USDC_DISCOUNT = 99 * 1e3;
    uint256 internal constant USDC_COLLATERAL_USER_CAP = 200_000 * 1e6;
    uint256 internal constant USDC_COLLATERAL_TOTAL_CAP = 200_000_000 * 1e6;
    uint256 internal constant USDC_LIABILITY_USER_CAP = 5_000 * 1e6;
    uint256 internal constant USDC_LIABILITY_TOTAL_CAP = 1_000_000 * 1e6;
    uint256 internal constant USDC_INTEREST_RATE_FACTOR = 10;
    uint256 internal constant USDC_LIQUIDATION_FACTOR = 5 * 1e3;

    function getUsdcIsSupportCollateral() internal pure returns (bool) {
        return USDC_IS_SUPPORT_COLLATERAL;
    }
    
    function getUsdcPrecision() internal pure returns (uint256) {
        return USDC_PRECISION;
    }
    
    function getUsdcDiscount() internal pure returns (uint256) {
        return USDC_DISCOUNT;
    }
    
    function getUsdcCollateralUserCap() internal pure returns (uint256) {
        return USDC_COLLATERAL_USER_CAP;
    }
    
    function getUsdcCollateralTotalCap() internal pure returns (uint256) {
        return USDC_COLLATERAL_TOTAL_CAP;
    }
    
    function getUsdcLiabilityUserCap() internal pure returns (uint256) {
        return USDC_LIABILITY_USER_CAP;
    }
    
    function getUsdcLiabilityTotalCap() internal pure returns (uint256) {
        return USDC_LIABILITY_TOTAL_CAP;
    }
    
    function getUsdcInterestRateFactor() internal pure returns (uint256) {
        return USDC_INTEREST_RATE_FACTOR;
    }
    
    function getUsdcLiquidationFactor() internal pure returns (uint256) {
        return USDC_LIQUIDATION_FACTOR;
    }
    
}