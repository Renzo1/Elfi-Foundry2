// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


library TradeConfig {

    uint256 internal constant MIN_ORDER_MARGIN_USD = 10 * 1e18; // 10$
    uint256 internal constant AVAILABLE_COLLATERAL_RATIO = 12 * 1e4;
    uint256 internal constant CROSS_LTV_LIMIT = 12 * 1e4;
    uint256 internal constant MAX_MAINTENANCE_MARGIN_RATE = 1 * 1e3;
    uint256 internal constant FUNDING_FEE_BASE_RATE = 20_000_000_000;
    uint256 internal constant MAX_FUNDING_BASE_RATE = 200_000_000_000;
    uint256 internal constant TRADING_FEE_STAKING_REWARDS_RATIO = 27 * 1e3;
    uint256 internal constant TRADING_FEE_POOL_REWARDS_RATIO = 63 * 1e3;
    uint256 internal constant TRADING_FEE_USD_POOL_REWARDS_RATIO = 1 * 1e4;
    uint256 internal constant BORROWING_FEE_STAKING_REWARDS_RATIO = 27 * 1e3;
    uint256 internal constant BORROWING_FEE_POOL_REWARDS_RATIO = 63 * 1e3;
    uint256 internal constant AUTO_REDUCE_PROFIT_FACTOR = 0;
    uint256 internal constant AUTO_REDUCE_LIQUIDITY_FACTOR = 0;
    uint256 internal constant SWAP_SLIPPER_TOKEN_FACTOR = 5 * 1e3;
  
    uint256 internal constant ETH_INITIAL_ALLOWANCE = 100e18;
    uint256 internal constant USDC_INITIAL_BALANCE = 100_000;
    uint256 internal constant WETH_INITIAL_ALLOWANCE = 100;
    uint256 internal constant WBTC_INITIAL_ALLOWANCE = 10;

    
    function getMinOrderMarginUsd() internal pure returns (uint256) {
        return MIN_ORDER_MARGIN_USD;
    }
    
    function getAvailableCollateralRatio() internal pure returns (uint256) {
        return AVAILABLE_COLLATERAL_RATIO;
    }
    
    function getCrossLtvLimit() internal pure returns (uint256) {
        return CROSS_LTV_LIMIT;
    }
    
    function getMaxMaintenanceMarginRate() internal pure returns (uint256) {
        return MAX_MAINTENANCE_MARGIN_RATE;
    }
    
    function getFundingFeeBaseRate() internal pure returns (uint256) {
        return FUNDING_FEE_BASE_RATE;
    }
    
    function getMaxFundingBaseRate() internal pure returns (uint256) {
        return MAX_FUNDING_BASE_RATE;
    }
    
    function getTradingFeeStakingRewardsRatio() internal pure returns (uint256) {
        return TRADING_FEE_STAKING_REWARDS_RATIO;
    }
    
    function getTradingFeePoolRewardsRatio() internal pure returns (uint256) {
        return TRADING_FEE_POOL_REWARDS_RATIO;
    }
    
    function getTradingFeeUsdPoolRewardsRatio() internal pure returns (uint256) {
        return TRADING_FEE_USD_POOL_REWARDS_RATIO;
    }
    
    function getBorrowingFeeStakingRewardsRatio() internal pure returns (uint256) {
        return BORROWING_FEE_STAKING_REWARDS_RATIO;
    }
    
    function getBorrowingFeePoolRewardsRatio() internal pure returns (uint256) {
        return BORROWING_FEE_POOL_REWARDS_RATIO;
    }
    
    function getAutoReduceProfitFactor() internal pure returns (uint256) {
        return AUTO_REDUCE_PROFIT_FACTOR;
    }
    
    function getAutoReduceLiquidityFactor() internal pure returns (uint256) {
        return AUTO_REDUCE_LIQUIDITY_FACTOR;
    }
    
    function getSwapSlipperTokenFactor() internal pure returns (uint256) {
        return SWAP_SLIPPER_TOKEN_FACTOR;
    }
    
    function getEthInitialAllowance() internal pure returns (uint256) {
        return ETH_INITIAL_ALLOWANCE;
    }
    
    function getUsdcInitialBalance() internal pure returns (uint256) {
        return USDC_INITIAL_BALANCE;
    }
    
    function getWethInitialAllowance() internal pure returns (uint256) {
        return WETH_INITIAL_ALLOWANCE;
    }
    
    function getWbtcInitialAllowance() internal pure returns (uint256) {
        return WBTC_INITIAL_ALLOWANCE;
    }
    
}