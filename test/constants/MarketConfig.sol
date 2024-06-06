// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


library MarketConfig {

  /// Market Configurations
  uint256 internal constant BASE_INTEREST_RATE = 6250000000;
  uint256 internal constant POOL_LIQUIDITY_LIMIT = 8 * 1e4;
  uint256 internal constant MINT_FEE_RATE = 120;
  uint256 internal constant REDEEM_FEE_RATE = 150;
  uint256 internal constant POOL_PNL_RATIO_LIMIT = 0;
  uint256 internal constant UNSETTLED_BASE_TOKEN_RATIO_LIMIT = 0;
  uint256 internal constant UNSETTLED_STABLE_TOKEN_RATIO_LIMIT = 0;
  uint256 internal constant POOL_STABLE_TOKEN_RATIO_LIMIT = 0;
  uint256 internal constant POOL_STABLE_TOKEN_LOSS_LIMIT = 0;
  
  bytes32 internal constant WETH_SYMBOL = "WETHUSDC";
  bytes32 internal constant WBTC_SYMBOL = "WBTCUSDC";

  uint256 internal constant MAX_LEVERAGE = 20 * 1e5;
  uint256 internal constant TICK_SIZE = 1_000_000;
  uint256 internal constant ETH_OPEN_FEE_RATE = 110;
  uint256 internal constant BTC_OPEN_FEE_RATE = 150;
  uint256 internal constant ETH_CLOSE_FEE_RATE = 130;
  uint256 internal constant BTC_CLOSE_FEE_RATE = 170;
  uint256 internal constant MAX_LONG_OPEN_INTEREST_CAP = 10_000_000 * 1e18;
  uint256 internal constant MAX_SHORT_OPEN_INTEREST_CAP = 10_000_000 * 1e18;
  uint256 internal constant LONG_SHORT_RATIO_LIMIT = 5 * 1e4;
  uint256 internal constant LONG_SHORT_OI_BOTTOM_LIMIT = 100_000 * 1e18;

  uint256 internal constant USDC_MINT_FEE_RATE = 10;
  uint256 internal constant USDC_REDEEM_FEE_RATE = 10;
  uint256 internal constant USDC_UNSETTLED_RATIO_LIMIT = 0;


    function getBaseInterestRate() internal pure returns (uint256) {
        return BASE_INTEREST_RATE;
    }

    function getPoolLiquidityLimit() internal pure returns (uint256) {
        return POOL_LIQUIDITY_LIMIT;
    }

    function getMintFeeRate() internal pure returns (uint256) {
        return MINT_FEE_RATE;
    }

    function getRedeemFeeRate() internal pure returns (uint256) {
        return REDEEM_FEE_RATE;
    }

    function getPoolPnlRatioLimit() internal pure returns (uint256) {
        return POOL_PNL_RATIO_LIMIT;
    }

    function getUnsettledBaseTokenRatioLimit() internal pure returns (uint256) {
        return UNSETTLED_BASE_TOKEN_RATIO_LIMIT;
    }

    function getUnsettledStableTokenRatioLimit() internal pure returns (uint256) {
        return UNSETTLED_STABLE_TOKEN_RATIO_LIMIT;
    }

    function getPoolStableTokenRatioLimit() internal pure returns (uint256) {
        return POOL_STABLE_TOKEN_RATIO_LIMIT;
    }

    function getPoolStableTokenLossLimit() internal pure returns (uint256) {
        return POOL_STABLE_TOKEN_LOSS_LIMIT;
    }

    function getWethSymbol() internal pure returns (bytes32) {
        return WETH_SYMBOL;
    }

    function getWbtcSymbol() internal pure returns (bytes32) {
        return WBTC_SYMBOL;
    }

    function getMaxLeverage() internal pure returns (uint256) {
        return MAX_LEVERAGE;
    }

    function getTickSize() internal pure returns (uint256) {
        return TICK_SIZE;
    }

    function getEthOpenFeeRate() internal pure returns (uint256) {
        return ETH_OPEN_FEE_RATE;
    }

    function getBtcOpenFeeRate() internal pure returns (uint256) {
        return BTC_OPEN_FEE_RATE;
    }

    function getEthCloseFeeRate() internal pure returns (uint256) {
        return ETH_CLOSE_FEE_RATE;
    }

    function getBtcCloseFeeRate() internal pure returns (uint256) {
        return BTC_CLOSE_FEE_RATE;
    }

    function getMaxLongOpenInterestCap() internal pure returns (uint256) {
        return MAX_LONG_OPEN_INTEREST_CAP;
    }

    function getMaxShortOpenInterestCap() internal pure returns (uint256) {
        return MAX_SHORT_OPEN_INTEREST_CAP;
    }

    function getLongShortRatioLimit() internal pure returns (uint256) {
        return LONG_SHORT_RATIO_LIMIT;
    }

    function getLongShortOiBottomLimit() internal pure returns (uint256) {
        return LONG_SHORT_OI_BOTTOM_LIMIT;
    }

    function getUsdcMintFeeRate() internal pure returns (uint256) {
        return USDC_MINT_FEE_RATE;
    }

    function getUsdcRedeemFeeRate() internal pure returns (uint256) {
        return USDC_REDEEM_FEE_RATE;
    }

    function getUsdcUnsettledRatioLimit() internal pure returns (uint256) {
        return USDC_UNSETTLED_RATIO_LIMIT;
    }

}
