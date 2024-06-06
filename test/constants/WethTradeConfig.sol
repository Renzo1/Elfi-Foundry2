// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


library WethTradeConfig {

    bool internal constant WETH_IS_SUPPORT_COLLATERAL = true;
    uint256 internal constant WETH_PRECISION = 6; 
    uint256 internal constant WETH_DISCOUNT = 99 * 1e3; // TODO: change value to be different from wbtc values and test again
    uint256 internal constant WETH_COLLATERAL_USER_CAP = 100 * 1e18;
    uint256 internal constant WETH_COLLATERAL_TOTAL_CAP = 100_000 * 1e18; 
    uint256 internal constant WETH_LIABILITY_USER_CAP = 1 * 1e18; 
    uint256 internal constant WETH_LIABILITY_TOTAL_CAP = 50 * 1e18;
    uint256 internal constant WETH_INTEREST_RATE_FACTOR = 10; // TODO: change value to be different from wbtc values and test again
    uint256 internal constant WETH_LIQUIDATION_FACTOR = 5 * 1e3; // TODO: change value to be different from wbtc values and test again

    function getWethIsSupportCollateral() internal pure returns (bool) {
        return WETH_IS_SUPPORT_COLLATERAL;
    }
    
    function getWethPrecision() internal pure returns (uint256) {
        return WETH_PRECISION;
    }
    
    function getWethDiscount() internal pure returns (uint256) {
        return WETH_DISCOUNT;
    }
    
    function getWethCollateralUserCap() internal pure returns (uint256) {
        return WETH_COLLATERAL_USER_CAP;
    }
    
    function getWethCollateralTotalCap() internal pure returns (uint256) {
        return WETH_COLLATERAL_TOTAL_CAP;
    }
    
    function getWethLiabilityUserCap() internal pure returns (uint256) {
        return WETH_LIABILITY_USER_CAP;
    }
    
    function getWethLiabilityTotalCap() internal pure returns (uint256) {
        return WETH_LIABILITY_TOTAL_CAP;
    }
    
    function getWethInterestRateFactor() internal pure returns (uint256) {
        return WETH_INTEREST_RATE_FACTOR;
    }
    
    function getWethLiquidationFactor() internal pure returns (uint256) {
        return WETH_LIQUIDATION_FACTOR;
    }
}