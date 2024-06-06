
pragma solidity ^0.8.18;


library ChainConfig {

  /// Chain Configurations
  uint256 internal constant MINT_GAS_FEE_LIMIT = 1_500_000;
  uint256 internal constant REDEEM_GAS_FEE_LIMIT = 1_500_000;
  uint256 internal constant PLACE_INCREASE_ORDER_GAS_FEE_LIMIT = 1_500_000;
  uint256 internal constant PLACE_DECREASE_ORDER_GAS_FEE_LIMIT = 1_500_000;
  uint256 internal constant POSITION_UPDATE_MARGIN_GAS_FEE_LIMIT = 1_500_000;
  uint256 internal constant POSITION_UPDATE_LEVERAGE_GAS_FEE_LIMIT = 1_500_000;
  uint256 internal constant WITHDRAW_GAS_FEE_LIMIT = 1_500_000;
  uint256 internal constant CLAIM_REWARDS_GAS_FEE_LIMIT = 1_500_000;

    function getMintGasFeeLimit() internal pure returns (uint256) {
        return MINT_GAS_FEE_LIMIT;
    }
    
    function getRedeemGasFeeLimit() internal pure returns (uint256) {
        return REDEEM_GAS_FEE_LIMIT;
    }
    
    function getPlaceIncreaseOrderGasFeeLimit() internal pure returns (uint256) {
        return PLACE_INCREASE_ORDER_GAS_FEE_LIMIT;
    }
    
    function getPlaceDecreaseOrderGasFeeLimit() internal pure returns (uint256) {
        return PLACE_DECREASE_ORDER_GAS_FEE_LIMIT;
    }
    
    function getPositionUpdateMarginGasFeeLimit() internal pure returns (uint256) {
        return POSITION_UPDATE_MARGIN_GAS_FEE_LIMIT;
    }
    
    function getPositionUpdateLeverageGasFeeLimit() internal pure returns (uint256) {
        return POSITION_UPDATE_LEVERAGE_GAS_FEE_LIMIT;
    }
    
    function getWithdrawGasFeeLimit() internal pure returns (uint256) {
        return WITHDRAW_GAS_FEE_LIMIT;
    }
    
    function getClaimRewardsGasFeeLimit() internal pure returns (uint256) {
        return CLAIM_REWARDS_GAS_FEE_LIMIT;
    }
    
}
