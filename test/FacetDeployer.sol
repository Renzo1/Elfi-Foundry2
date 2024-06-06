// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;


// import "src/interfaces/IWETH.sol";
import "src/interfaces/IMarketManager.sol";
import "src/facets/StakingAccountFacet.sol";
import "src/interfaces/IOrder.sol";
import "src/facets/PoolFacet.sol";
import "src/facets/RebalanceFacet.sol";
import "src/facets/FeeFacet.sol";
import "src/interfaces/IVault.sol";
import "src/facets/OrderFacet.sol";
import "src/facets/OracleFacet.sol";
import "src/facets/FaucetFacet.sol";
import "src/interfaces/IDiamond.sol";
import "src/facets/RoleAccessControlFacet.sol";
import "src/facets/StakeFacet.sol";
import "src/facets/MarketManagerFacet.sol";
import "src/facets/PositionFacet.sol";
import "src/facets/DiamondCutFacet.sol";
import "src/interfaces/IStake.sol";
import "src/interfaces/IPool.sol";
import "src/facets/VaultFacet.sol";
import "src/interfaces/IOracle.sol";
import "src/interfaces/ISwap.sol";
import "src/interfaces/IReferral.sol";
import "src/facets/AccountFacet.sol";
import "src/facets/DiamondLoupeFacet.sol";
import "src/facets/LiquidationFacet.sol";
import "src/facets/SwapFacet.sol";
import "src/interfaces/IRoleAccessControl.sol";
import "src/interfaces/IFaucet.sol";
import "src/interfaces/IPosition.sol";
import "src/interfaces/IAccount.sol";
import "src/interfaces/IFee.sol";
import "src/interfaces/ILiquidation.sol";
import "src/interfaces/IDiamondCut.sol";
import "src/facets/ReferralFacet.sol";
import "src/facets/MarketFacet.sol";
import "src/facets/ConfigFacet.sol";
import "src/interfaces/IMarket.sol";
import "src/interfaces/IRebalance.sol";
import "src/interfaces/IStakingAccount.sol";


contract FacetDeployer {

    struct FacetVars {
        IDiamondCut.FacetCut[] cut;
    
        bytes4[] accountFunctionSelectors;
        bytes4[] configFunctionSelectors;
        bytes4[] faucetFunctionSelectors;
        bytes4[] feeFunctionSelectors;
        bytes4[] liquidationFunctionSelectors;
        bytes4[] marketFunctionSelectors;
        bytes4[] marketManagerFunctionSelectors;
        bytes4[] oracleFunctionSelectors;
        bytes4[] orderFunctionSelectors;
        bytes4[] poolFunctionSelectors;
        bytes4[] positionsFunctionSelectors;
        bytes4[] rebalanceFunctionSelectors;
        bytes4[] referralFunctionSelectors;
        bytes4[] roleAccessFunctionSelectors;
        bytes4[] stakeFunctionSelectors;
        bytes4[] stakingAccountFunctionSelectors;
        bytes4[] swapFunctionSelectors;
        bytes4[] vaultFunctionSelectors;
    }
    
    address public accountFacet;
    address public diamondCutFacet;
    address public diamondLoupeFacet;
    address public orderFacet;
    address public positionFacet;
    address public roleAccessControlFacet;
    address public stakeFacet;
    address public oracleFacet;
    address public stakingAccountFacet;
    address public poolFacet;
    address public rebalanceFacet;
    address public feeFacet;
    address public faucetFacet;
    address public marketManagerFacet;
    address public vaultFacet;
    address public liquidationFacet;
    address public swapFacet;
    address public referralFacet;
    address public marketFacet;
    address public configFacet;

    address public diamond;

    IDiamondCut diamondDiamondCutFacet;

    constructor(address _diamond, address _diamondCutFacet, address _diamondLoupeFacet) {
        diamond = _diamond;
        diamondCutFacet = _diamondCutFacet;
        diamondLoupeFacet = _diamondLoupeFacet;
        diamondDiamondCutFacet = IDiamondCut(_diamond);
        deployFacets();
    }


  function deployFacets() public {
    accountFacet = address(new AccountFacet());
    orderFacet = address(new OrderFacet());
    positionFacet = address(new PositionFacet());
    roleAccessControlFacet = address(new RoleAccessControlFacet());
    stakeFacet = address(new StakeFacet());
    oracleFacet = address(new OracleFacet());
    stakingAccountFacet = address(new StakingAccountFacet());
    poolFacet = address(new PoolFacet());
    rebalanceFacet = address(new RebalanceFacet());
    feeFacet = address(new FeeFacet());
    faucetFacet = address(new FaucetFacet());
    marketManagerFacet = address(new MarketManagerFacet());
    vaultFacet = address(new VaultFacet());
    liquidationFacet = address(new LiquidationFacet());
    swapFacet = address(new SwapFacet());
    referralFacet = address(new ReferralFacet());
    marketFacet = address(new MarketFacet());
    configFacet = address(new ConfigFacet());
  }


  function setupFacets() public view returns(FacetVars memory) {
    
    FacetVars memory facetVars;

    /// Prepare Cut
    facetVars.cut = new IDiamondCut.FacetCut[](18);

    /// Prepare AccountFacet Cut
    facetVars.accountFunctionSelectors = new bytes4[](7);
    // Write functions
    facetVars.accountFunctionSelectors[0] = IAccount.deposit.selector;
    facetVars.accountFunctionSelectors[1] = IAccount.createWithdrawRequest.selector;
    facetVars.accountFunctionSelectors[2] = IAccount.executeWithdraw.selector;
    facetVars.accountFunctionSelectors[3] = IAccount.cancelWithdraw.selector;
    facetVars.accountFunctionSelectors[4] = IAccount.batchUpdateAccountToken.selector;
    
    // Read functions
    facetVars.accountFunctionSelectors[5] = IAccount.getAccountInfo.selector;
    facetVars.accountFunctionSelectors[6] = IAccount.getAccountInfoWithOracles.selector;
    

    facetVars.cut[0] = IDiamond.FacetCut({
        facetAddress: accountFacet,
        action: IDiamond.FacetCutAction.Add,
        functionSelectors: facetVars.accountFunctionSelectors
    });


    /// Prepare ConfigFacet Cut 
    
    facetVars.configFunctionSelectors = new bytes4[](10);

    // Write functions - Dont add this functions in your fuzz handler
    facetVars.configFunctionSelectors[0] = ConfigFacet.setConfig.selector;
    facetVars.configFunctionSelectors[1] = ConfigFacet.setUniswapRouter.selector;
    facetVars.configFunctionSelectors[2] = ConfigFacet.setPoolConfig.selector;
    facetVars.configFunctionSelectors[3] = ConfigFacet.setUsdPoolConfig.selector;
    facetVars.configFunctionSelectors[4] = ConfigFacet.setSymbolConfig.selector;
    facetVars.configFunctionSelectors[5] = ConfigFacet.setVaultConfig.selector;
    
    // Read functions
    facetVars.configFunctionSelectors[6] = ConfigFacet.getConfig.selector;
    facetVars.configFunctionSelectors[7] = ConfigFacet.getPoolConfig.selector;
    facetVars.configFunctionSelectors[8] = ConfigFacet.getUsdPoolConfig.selector;
    facetVars.configFunctionSelectors[9] = ConfigFacet.getSymbolConfig.selector;
    

    facetVars.cut[1] = IDiamond.FacetCut({
        facetAddress: configFacet,
        action: IDiamond.FacetCutAction.Add,
        functionSelectors: facetVars.configFunctionSelectors
    });


    /// Prepare FaucetFacet Cut
    
    facetVars.faucetFunctionSelectors = new bytes4[](1);

    // Write functions
    facetVars.faucetFunctionSelectors[0] = IFaucet.requestTokens.selector;
    
    facetVars.cut[2] = IDiamond.FacetCut({
        facetAddress: faucetFacet,
        action: IDiamond.FacetCutAction.Add,
        functionSelectors: facetVars.faucetFunctionSelectors
    });


    /// Prepare FeeFacet Cut

    facetVars.feeFunctionSelectors = new bytes4[](11);

    // Write functions
    facetVars.feeFunctionSelectors[0] = IFee.distributeFeeRewards.selector;
    facetVars.feeFunctionSelectors[1] = IFee.createClaimRewards.selector;
    facetVars.feeFunctionSelectors[2] = IFee.executeClaimRewards.selector;
    
    // Read functions
    facetVars.feeFunctionSelectors[3] = IFee.getPoolTokenFee.selector;
    facetVars.feeFunctionSelectors[4] = IFee.getCumulativeRewardsPerStakeToken.selector;
    facetVars.feeFunctionSelectors[5] = IFee.getMarketTokenFee.selector;
    facetVars.feeFunctionSelectors[6] = IFee.getStakingTokenFee.selector;
    facetVars.feeFunctionSelectors[7] = IFee.getDaoTokenFee.selector;
    facetVars.feeFunctionSelectors[8] = IFee.getAccountFeeRewards.selector;
    facetVars.feeFunctionSelectors[9] = IFee.getAccountUsdFeeReward.selector;
    facetVars.feeFunctionSelectors[10] = IFee.getAccountsFeeRewards.selector;

    facetVars.cut[3] = IDiamond.FacetCut({
      facetAddress: feeFacet,
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetVars.feeFunctionSelectors
    });


    /// Prepare LiquidationFacet Cut

    facetVars.liquidationFunctionSelectors = new bytes4[](6);

    // Write functions
    facetVars.liquidationFunctionSelectors[0] = ILiquidation.liquidationPosition.selector;
    facetVars.liquidationFunctionSelectors[1] = ILiquidation.liquidationAccount.selector;
    facetVars.liquidationFunctionSelectors[2] = ILiquidation.liquidationLiability.selector;
    facetVars.liquidationFunctionSelectors[3] = ILiquidation.callLiabilityClean.selector;
    
    // Read functions
    facetVars.liquidationFunctionSelectors[4] = ILiquidation.getInsuranceFunds.selector;
    facetVars.liquidationFunctionSelectors[5] = ILiquidation.getAllCleanInfos.selector;

    facetVars.cut[4] = IDiamond.FacetCut({
      facetAddress: liquidationFacet,
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetVars.liquidationFunctionSelectors
    });

    
    /// Prepare MarketFacet Cut

    facetVars.marketFunctionSelectors = new bytes4[](6);

    // Read functions
    facetVars.marketFunctionSelectors[0] = IMarket.getAllSymbols.selector;
    facetVars.marketFunctionSelectors[1] = IMarket.getSymbol.selector;
    facetVars.marketFunctionSelectors[2] = IMarket.getStakeUsdToken.selector;
    facetVars.marketFunctionSelectors[3] = IMarket.getTradeTokenInfo.selector;
    facetVars.marketFunctionSelectors[4] = IMarket.getMarketInfo.selector;
    facetVars.marketFunctionSelectors[5] = IMarket.getLastUuid.selector;

    facetVars.cut[5] = IDiamond.FacetCut({
      facetAddress: marketFacet,
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetVars.marketFunctionSelectors
    });

    
    /// Prepare MarketManagerFacet Cut

    facetVars.marketManagerFunctionSelectors = new bytes4[](2);

    // Write functions
    facetVars.marketManagerFunctionSelectors[0] = IMarketManager.createMarket.selector;
    facetVars.marketManagerFunctionSelectors[1] = IMarketManager.createStakeUsdPool.selector;

    facetVars.cut[6] = IDiamond.FacetCut({
      facetAddress: marketManagerFacet,
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetVars.marketManagerFunctionSelectors
    });

    
    /// Prepare OracleFacet Cut

    facetVars.oracleFunctionSelectors = new bytes4[](2);

    // Write functions
    facetVars.oracleFunctionSelectors[0] = IOracle.getLatestUsdPrice.selector;

    // Read functions
    facetVars.oracleFunctionSelectors[1] = IOracle.setOraclePrices.selector;

    facetVars.cut[7] = IDiamond.FacetCut({
      facetAddress: oracleFacet,
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetVars.oracleFunctionSelectors
    });

    
    /// Prepare OrderFacet Cut

    facetVars.orderFunctionSelectors = new bytes4[](5);

    // Write functions
    facetVars.orderFunctionSelectors[0] = IOrder.createOrderRequest.selector;
    facetVars.orderFunctionSelectors[1] = IOrder.batchCreateOrderRequest.selector;
    facetVars.orderFunctionSelectors[2] = IOrder.executeOrder.selector;
    facetVars.orderFunctionSelectors[3] = IOrder.cancelOrder.selector;
    
    // Read functions
    facetVars.orderFunctionSelectors[4] = IOrder.getAccountOrders.selector;

    facetVars.cut[8] = IDiamond.FacetCut({
      facetAddress: orderFacet,
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetVars.orderFunctionSelectors
    });

    
    /// Prepare PoolFacet Cut

    facetVars.poolFunctionSelectors = new bytes4[](5);

    // Read functions
    facetVars.poolFunctionSelectors[0] = IPool.getPool.selector;
    facetVars.poolFunctionSelectors[1] = IPool.getUsdPool.selector;
    facetVars.poolFunctionSelectors[2] = IPool.getPoolWithOracle.selector;
    facetVars.poolFunctionSelectors[3] = IPool.getUsdPoolWithOracle.selector;
    facetVars.poolFunctionSelectors[4] = IPool.getAllPools.selector;


    facetVars.cut[9] = IDiamond.FacetCut({
      facetAddress: poolFacet,
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetVars.poolFunctionSelectors
    });

    
    /// Prepare PositionFacet Cut

    facetVars.positionsFunctionSelectors = new bytes4[](9);

    // Write functions
    facetVars.positionsFunctionSelectors[0] = IPosition.createUpdatePositionMarginRequest.selector;
    facetVars.positionsFunctionSelectors[1] = IPosition.executeUpdatePositionMarginRequest.selector;
    facetVars.positionsFunctionSelectors[2] = IPosition.cancelUpdatePositionMarginRequest.selector;
    facetVars.positionsFunctionSelectors[3] = IPosition.createUpdateLeverageRequest.selector;
    facetVars.positionsFunctionSelectors[4] = IPosition.executeUpdateLeverageRequest.selector;
    facetVars.positionsFunctionSelectors[5] = IPosition.cancelUpdateLeverageRequest.selector;
    facetVars.positionsFunctionSelectors[6] = IPosition.autoReducePositions.selector;
    
    // Read functions
    facetVars.positionsFunctionSelectors[7] = IPosition.getAllPositions.selector;
    facetVars.positionsFunctionSelectors[8] = IPosition.getSinglePosition.selector;

    facetVars.cut[10] = IDiamond.FacetCut({
      facetAddress: positionFacet,
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetVars.positionsFunctionSelectors
    });
    

    /// Prepare RebalanceFacet Cut

    facetVars.rebalanceFunctionSelectors = new bytes4[](1);

    // Write functions
    facetVars.rebalanceFunctionSelectors[0] = IRebalance.autoRebalance.selector;

    facetVars.cut[11] = IDiamond.FacetCut({
      facetAddress: rebalanceFacet,
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetVars.rebalanceFunctionSelectors
    });

    
    /// Prepare ReferralFacet Cut

    facetVars.referralFunctionSelectors = new bytes4[](2);

    // Read functions
    facetVars.referralFunctionSelectors[0] = IReferral.isCodeExists.selector;
    facetVars.referralFunctionSelectors[1] = IReferral.getAccountReferral.selector;

    facetVars.cut[12] = IDiamond.FacetCut({
      facetAddress: referralFacet,
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetVars.referralFunctionSelectors
    });

    
    /// Prepare roleAccessControlFacet Cut

    facetVars.roleAccessFunctionSelectors = new bytes4[](4);

    // Write functions
    facetVars.roleAccessFunctionSelectors[0] = IRoleAccessControl.grantRole.selector;
    facetVars.roleAccessFunctionSelectors[1] = IRoleAccessControl.revokeRole.selector;
    facetVars.roleAccessFunctionSelectors[2] = IRoleAccessControl.revokeAllRole.selector;
    
    // Read functions
    facetVars.roleAccessFunctionSelectors[3] = IRoleAccessControl.hasRole.selector;

    facetVars.cut[13] = IDiamond.FacetCut({
      facetAddress: roleAccessControlFacet,
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetVars.roleAccessFunctionSelectors
    });

    
    /// Prepare StakeFacet Cut

    facetVars.stakeFunctionSelectors = new bytes4[](6);

    // Write functions
    facetVars.stakeFunctionSelectors[0] = IStake.createMintStakeTokenRequest.selector;
    facetVars.stakeFunctionSelectors[1] = IStake.executeMintStakeToken.selector;
    facetVars.stakeFunctionSelectors[2] = IStake.cancelMintStakeToken.selector;
    facetVars.stakeFunctionSelectors[3] = IStake.createRedeemStakeTokenRequest.selector;
    facetVars.stakeFunctionSelectors[4] = IStake.executeRedeemStakeToken.selector;
    facetVars.stakeFunctionSelectors[5] = IStake.cancelRedeemStakeToken.selector;

    facetVars.cut[14] = IDiamond.FacetCut({
      facetAddress: stakeFacet,
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetVars.stakeFunctionSelectors
    });

    
    /// Prepare StakingAccountFacet Cut

    facetVars.stakingAccountFunctionSelectors = new bytes4[](3);

    // Read functions
    facetVars.stakingAccountFunctionSelectors[0] = IStakingAccount.getAccountPoolBalance.selector;
    facetVars.stakingAccountFunctionSelectors[1] = IStakingAccount.getAccountPoolCollateralAmount.selector;
    facetVars.stakingAccountFunctionSelectors[2] = IStakingAccount.getAccountUsdPoolAmount.selector;

    facetVars.cut[15] = IDiamond.FacetCut({
      facetAddress: stakingAccountFacet,
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetVars.stakingAccountFunctionSelectors
    });

    
    /// Prepare SwapFacet Cut

    facetVars.swapFunctionSelectors = new bytes4[](1);

    // Write functions
    facetVars.swapFunctionSelectors[0] = ISwap.swapPortfolioToPayLiability.selector;

    facetVars.cut[16] = IDiamond.FacetCut({
      facetAddress: swapFacet,
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetVars.swapFunctionSelectors
    });

    
    /// Prepare VaultFacet Cut

    facetVars.vaultFunctionSelectors = new bytes4[](6);

    // Read functions
    facetVars.vaultFunctionSelectors[0] = IVault.getTradeVault.selector;
    facetVars.vaultFunctionSelectors[1] = IVault.getLpVault.selector;
    facetVars.vaultFunctionSelectors[2] = IVault.getPortfolioVault.selector;
    facetVars.vaultFunctionSelectors[3] = IVault.getTradeVaultAddress.selector;
    facetVars.vaultFunctionSelectors[4] = IVault.getLpVaultAddress.selector;
    facetVars.vaultFunctionSelectors[5] = IVault.getPortfolioVaultAddress.selector;

    facetVars.cut[17] = IDiamond.FacetCut({
      facetAddress: vaultFacet,
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetVars.vaultFunctionSelectors
    });
    
    return facetVars;
  }

}
