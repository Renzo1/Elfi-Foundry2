// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


library StakeConfig {

  /// Stake Configurations
  uint256 internal constant COLLATERAL_PROTECT_FACTOR = 5 * 1e2;
  uint256 internal constant COLLATERAL_FACTOR = 5 * 1e3;
  uint256 internal constant MIN_PRECISION_MULTIPLE = 11;
  uint256 internal constant MINT_FEE_STAKING_REWARDS_RATIO = 27 * 1e3;
  uint256 internal constant MINT_FEE_POOL_REWARDS_RATIO = 63 * 1e3;
  uint256 internal constant REDEEM_FEE_STAKING_REWARDS_RATIO = 27 * 1e3;
  uint256 internal constant REDEEM_FEE_POOL_REWARDS_RATIO = 63 * 1e3;
  uint256 internal constant POOL_REWARDS_INTERVAL_LIMIT = 0;
  uint256 internal constant MIN_APR = 2 * 1e4;
  uint256 internal constant MAX_APR = 20 * 1e5;


    function getCollateralProtectFactor() internal pure returns (uint256) {
        return COLLATERAL_PROTECT_FACTOR;
    }

    function getCollateralFactor() internal pure returns (uint256) {
        return COLLATERAL_FACTOR;
    }

    function getMinPrecisionMultiple() internal pure returns (uint256) {
        return MIN_PRECISION_MULTIPLE;
    }

    function getMintFeeStakingRewardsRatio() internal pure returns (uint256) {
        return MINT_FEE_STAKING_REWARDS_RATIO;
    }

    function getMintFeePoolRewardsRatio() internal pure returns (uint256) {
        return MINT_FEE_POOL_REWARDS_RATIO;
    }

    function getRedeemFeeStakingRewardsRatio() internal pure returns (uint256) {
        return REDEEM_FEE_STAKING_REWARDS_RATIO;
    }

    function getRedeemFeePoolRewardsRatio() internal pure returns (uint256) {
        return REDEEM_FEE_POOL_REWARDS_RATIO;
    }

    function getPoolRewardsIntervalLimit() internal pure returns (uint256) {
        return POOL_REWARDS_INTERVAL_LIMIT;
    }

    function getMinApr() internal pure returns (uint256) {
        return MIN_APR;
    }

    function getMaxApr() internal pure returns (uint256) {
        return MAX_APR;
    }

}