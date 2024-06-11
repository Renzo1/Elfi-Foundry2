
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseSetup} from "@chimera/BaseSetup.sol";
import {MockAggregatorV3} from "../mocks/MockAggregatorV3.sol";
import "../constants/ChainConfig.sol";
import "../constants/MarketConfig.sol";
import "../constants/RolesAndPools.sol";
import "../constants/StakeConfig.sol";
import "../constants/TradeConfig.sol";
import "../constants/UsdcTradeConfig.sol";
import "../constants/WbtcTradeConfig.sol";
import "../constants/WethTradeConfig.sol";
import "../FacetDeployer.sol";

import "src/storage/UsdPool.sol";
import "src/vault/TradeVault.sol";
import "src/interfaces/IMarketManager.sol";
import "src/storage/Position.sol";
import "src/interfaces/IVault.sol";
import "src/process/OracleProcess.sol";
import "src/interfaces/IDiamond.sol";
import "src/interfaces/IStake.sol";
import "src/mock/MockToken.sol";
import "src/interfaces/IPool.sol";
import "src/interfaces/IOracle.sol";
import "src/vault/StakeToken.sol";
import "src/interfaces/IReferral.sol";
import "src/router/DiamondInit.sol";
import "src/interfaces/IRoleAccessControl.sol";
import "src/vault/LpVault.sol";
import "src/interfaces/IPosition.sol";
import "src/interfaces/ISwap.sol";
import "src/vault/PortfolioVault.sol";
import "src/interfaces/IFaucet.sol";
import "src/interfaces/IAccount.sol";
import "src/interfaces/IStakingAccount.sol";
import "src/interfaces/IDiamondCut.sol";
import "src/router/Diamond.sol";
import "src/interfaces/IDiamondLoupe.sol";
import "src/interfaces/IFee.sol";
import "src/interfaces/IMarket.sol";
import "src/interfaces/ILiquidation.sol";
import "src/mock/WETH.sol";
import "src/interfaces/IRebalance.sol";
import "src/interfaces/IOrder.sol";



interface IHevm {
  // Set block.timestamp to newTimestamp
  function warp(uint256 newTimestamp) external;

  // Sets the eth balance of usr to amt
  function deal(address usr, uint256 amt) external;

  // Gets address for a given private key
  function addr(uint256 privateKey) external returns (address addr);

  // Performs the next smart contract call with specified `msg.sender`
  function prank(address newSender) external;

  // Labels the address in traces
  // function label(address addr, string calldata label) external;
}

abstract contract Setup is BaseSetup {
  IHevm hevm = IHevm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
  
  ///////// Network Assets ////////
  WETH weth;
  MockToken wbtc;
  MockToken usdc;
  address ETH_ADDRESS;
  address[] internal tokens;
  
  address[] internal stakedTokens;

  address[] internal USERS;

  FacetDeployer facetDeployer;

  ///////// Diamond Facets ////////
  IAccount diamondAccountFacet;
  IOrder diamondOrderFacet;
  IPosition diamondPositionFacet;
  IRoleAccessControl diamondRoleAccessControlFacet;
  IStake diamondStakeFacet;
  ConfigFacet diamondConfigFacet;
  
  IStakingAccount diamondStakingAccountFacet;
  IPool diamondPoolFacet;
  IRebalance diamondRebalanceFacet;
  IMarketManager diamondMarketManagerFacet;
  IVault diamondVaultFacet;
  ILiquidation diamondLiquidationFacet;
  IMarket diamondMarketFacet;
  IDiamondCut diamondDiamondCutFacet;
  // IReferral diamondReferralFacet;
  // ISwap diamondSwapFacet;
  // IFaucet diamondFaucetFacet;
  // IFee diamondFeeFacet;
  // IOracle diamondOracleFacet;
  // IDiamondLoupe diamondDiamondLoupeFacet;


  ///////// Router ////////
  address diamondAddress;

  ///////// Vault ////////
  LpVault lpVault;
  PortfolioVault portfolioVault;
  TradeVault tradeVault;

  ///////////////////////
  //// Setup Network ////
  ///////////////////////

  function setup() internal virtual override {
    /// Deploy Tokens
    weth = new WETH();
    usdc = new MockToken("USDC", 18); // toggle between 6 and 18
    wbtc = new MockToken("WBTC", 8); 
    ETH_ADDRESS = hevm.addr(0x122333444455555);

    tokens = new address[](3);
    tokens[0] = address(weth); 
    tokens[1] = address(usdc); 
    tokens[2] = address(wbtc);

    /// Deploy Vaults
    tradeVault = new TradeVault(address(this));
    lpVault = new LpVault(address(this));
    portfolioVault = new PortfolioVault(address(this));

    /// Deploy Diamond
    address diamondCutFacet = address(new DiamondCutFacet());
    address diamondLoupeFacet = address(new DiamondLoupeFacet());
    address diamondInit = address(new DiamondInit());
    // Diamond diamond = new Diamond(facetDeployer.diamondCutFacet(), facetDeployer.diamondLoupeFacet(), address(diamondInit), address(this));
    diamondAddress = address(new Diamond(diamondCutFacet, diamondLoupeFacet, diamondInit, address(this)));
    
    /// Deploy Facets
    facetDeployer = new FacetDeployer(diamondAddress, diamondCutFacet, diamondLoupeFacet);
    // facetDeployer.deployFacets(); // deploy facets
    FacetDeployer.FacetVars memory cutData = facetDeployer.setupFacets(); // setup facets for diamond cut
    setupDiamondFacets(); // Setup DiamondFacets with Facet Interfaces
    diamondDiamondCutFacet.diamondCut(cutData.cut, address(0), ""); // cut diamond

    /// System Configurations
    configVaultAdmin(); // Configure Vaults Admin Role

    // Configure roleAccessControlFacet Roles
    // set all privileged roles to address(this)
    configDiamondRoles(); 
    assert(diamondRoleAccessControlFacet.hasRole(address(this), RolesAndPools.getRoleAdmin()));
    assert(diamondRoleAccessControlFacet.hasRole(address(this), RolesAndPools.getRoleUpgrade()));
    assert(diamondRoleAccessControlFacet.hasRole(address(this), RolesAndPools.getRoleConfig()));
    assert(diamondRoleAccessControlFacet.hasRole(address(this), RolesAndPools.getRoleKeeper()));

    // Configure setVaultConfig
    setElfiVaultConfig();
    assert(address(diamondVaultFacet.getLpVault()) == address(lpVault));
    assert(address(diamondVaultFacet.getTradeVault()) == address(tradeVault));
    assert(address(diamondVaultFacet.getPortfolioVault()) == address(portfolioVault));

    // Configure Markets
    createMarketsAndPools();

    setLpPoolConfig();

    assert(diamondPoolFacet.getUsdPool().stableTokens[0] == address(usdc));
    assert(diamondPoolFacet.getPool(stakedTokens[0]).baseToken == address(weth));
    assert(diamondPoolFacet.getPool(stakedTokens[1]).baseToken == address(wbtc));

    setCommonConfig();

    
    IConfig.CommonConfigParams memory config = diamondConfigFacet.getConfig();

    // chainConfig
    assert(config.chainConfig.wrapperToken == address(weth));
    assert(config.chainConfig.mintGasFeeLimit == ChainConfig.getMintGasFeeLimit());
    assert(config.chainConfig.redeemGasFeeLimit == ChainConfig.getRedeemGasFeeLimit());
    assert(config.chainConfig.placeIncreaseOrderGasFeeLimit == ChainConfig.getPlaceIncreaseOrderGasFeeLimit());
    assert(config.chainConfig.placeDecreaseOrderGasFeeLimit == ChainConfig.getPlaceDecreaseOrderGasFeeLimit());
    assert(config.chainConfig.positionUpdateMarginGasFeeLimit == ChainConfig.getPositionUpdateMarginGasFeeLimit());
    assert(config.chainConfig.positionUpdateLeverageGasFeeLimit == ChainConfig.getPositionUpdateLeverageGasFeeLimit());
    assert(config.chainConfig.withdrawGasFeeLimit == ChainConfig.getWithdrawGasFeeLimit());
    assert(config.chainConfig.claimRewardsGasFeeLimit == ChainConfig.getClaimRewardsGasFeeLimit());

    // tradeConfig
    assert(config.tradeConfig.tradeTokens.length == 3);
    assert(config.tradeConfig.tradeTokenConfigs.length == 3);
    assert(config.tradeConfig.minOrderMarginUSD == TradeConfig.getMinOrderMarginUsd());
    assert(config.tradeConfig.availableCollateralRatio == TradeConfig.getAvailableCollateralRatio());
    assert(config.tradeConfig.crossLtvLimit == TradeConfig.getCrossLtvLimit());
    assert(config.tradeConfig.maxMaintenanceMarginRate == TradeConfig.getMaxMaintenanceMarginRate());
    assert(config.tradeConfig.fundingFeeBaseRate == TradeConfig.getFundingFeeBaseRate());
    assert(config.tradeConfig.maxFundingBaseRate == TradeConfig.getMaxFundingBaseRate());
    assert(config.tradeConfig.tradingFeeStakingRewardsRatio == TradeConfig.getTradingFeeStakingRewardsRatio());
    assert(config.tradeConfig.tradingFeePoolRewardsRatio == TradeConfig.getTradingFeePoolRewardsRatio());
    assert(config.tradeConfig.tradingFeeUsdPoolRewardsRatio == TradeConfig.getTradingFeeUsdPoolRewardsRatio());
    assert(config.tradeConfig.borrowingFeeStakingRewardsRatio == TradeConfig.getBorrowingFeeStakingRewardsRatio());
    assert(config.tradeConfig.borrowingFeePoolRewardsRatio == TradeConfig.getBorrowingFeePoolRewardsRatio());
    assert(config.tradeConfig.autoReduceProfitFactor == TradeConfig.getAutoReduceProfitFactor());
    assert(config.tradeConfig.autoReduceLiquidityFactor == TradeConfig.getAutoReduceLiquidityFactor());
    assert(config.tradeConfig.swapSlipperTokenFactor == TradeConfig.getSwapSlipperTokenFactor());

    // stakeConfig
    assert(config.stakeConfig.collateralProtectFactor == StakeConfig.getCollateralProtectFactor());
    assert(config.stakeConfig.collateralFactor == StakeConfig.getCollateralFactor());
    assert(config.stakeConfig.minPrecisionMultiple == StakeConfig.getMinPrecisionMultiple());
    assert(config.stakeConfig.mintFeeStakingRewardsRatio == StakeConfig.getMintFeeStakingRewardsRatio());
    assert(config.stakeConfig.mintFeePoolRewardsRatio == StakeConfig.getMintFeePoolRewardsRatio());
    assert(config.stakeConfig.redeemFeeStakingRewardsRatio == StakeConfig.getRedeemFeeStakingRewardsRatio());
    assert(config.stakeConfig.redeemFeePoolRewardsRatio == StakeConfig.getRedeemFeePoolRewardsRatio());
    assert(config.stakeConfig.poolRewardsIntervalLimit == StakeConfig.getPoolRewardsIntervalLimit());
    assert(config.stakeConfig.minApr == StakeConfig.getMinApr());
    assert(config.stakeConfig.maxApr == StakeConfig.getMaxApr());

    /// Setup Actors and deal them some tokens
    setupActors();
  }


  function setupDiamondFacets() internal {
    diamondAccountFacet = IAccount(diamondAddress);
    diamondOrderFacet = IOrder(diamondAddress);
    diamondPositionFacet = IPosition(diamondAddress);
    diamondRoleAccessControlFacet = IRoleAccessControl(diamondAddress);
    diamondStakeFacet = IStake(diamondAddress);
    diamondStakingAccountFacet = IStakingAccount(diamondAddress);
    diamondPoolFacet = IPool(diamondAddress);
    diamondMarketManagerFacet = IMarketManager(diamondAddress);
    diamondVaultFacet = IVault(diamondAddress);
    diamondLiquidationFacet = ILiquidation(diamondAddress);
    diamondMarketFacet = IMarket(diamondAddress);
    diamondConfigFacet = ConfigFacet(diamondAddress);
    diamondDiamondCutFacet = IDiamondCut(diamondAddress);

    // diamondReferralFacet = IReferral(diamondAddress);
    // diamondSwapFacet = ISwap(diamondAddress);
    // diamondFaucetFacet = IFaucet(diamondAddress);
    // diamondFeeFacet = IFee(diamondAddress);
    // diamondRebalanceFacet = IRebalance(diamondAddress);
    // diamondOracleFacet = IOracle(diamondAddress);
    // diamondDiamondLoupeFacet = IDiamondLoupe(diamondAddress);
  }
  

  function configVaultAdmin() internal {
    lpVault.grantAdmin(diamondAddress);
    portfolioVault.grantAdmin(diamondAddress);
    tradeVault.grantAdmin(diamondAddress);
  }

  function configDiamondRoles() internal {
    diamondRoleAccessControlFacet.grantRole(address(this), RolesAndPools.getRoleUpgrade());
    diamondRoleAccessControlFacet.grantRole(address(this), RolesAndPools.getRoleConfig());
    diamondRoleAccessControlFacet.grantRole(address(this), RolesAndPools.getRoleKeeper());
  }

  function setElfiVaultConfig() internal {
    IConfig.VaultConfigParams memory vaultConfig; 

    vaultConfig = IConfig.VaultConfigParams({
      lpVault: address(lpVault),
      tradeVault: address(tradeVault),
      portfolioVault: address(portfolioVault)
    });

    diamondConfigFacet.setVaultConfig(vaultConfig);
  }

  function createMarketsAndPools() internal {
    
    MarketFactoryProcess.CreateMarketParams memory params1;
    MarketFactoryProcess.CreateMarketParams memory params2;


    params1 = MarketFactoryProcess.CreateMarketParams({
      code: RolesAndPools.getCodeHash1(),
      stakeTokenName: RolesAndPools.getStakedWeth(),
      indexToken: address(weth),
      baseToken: address(weth) // according to the deploy script its not address(usdc)
    });

    params2 = MarketFactoryProcess.CreateMarketParams({
      code: RolesAndPools.getCodeHash2(),
      stakeTokenName: RolesAndPools.getStakedWbtc(),
      indexToken: address(wbtc),
      baseToken: address(wbtc)
    });

    stakedTokens = new address[](3);

    stakedTokens[0] = diamondMarketManagerFacet.createMarket(params1); // weth
    stakedTokens[1] = diamondMarketManagerFacet.createMarket(params2); // wbtc
        
    stakedTokens[2] = diamondMarketManagerFacet.createStakeUsdPool(RolesAndPools.getStakedUsdc(), 18);
    // StakeToken stakedUSD = StakeToken(stakeUsdTokenAddress);
  }

  function setLpPoolConfig() internal {
    /// Market Pool Config

    address[] memory wethAssetTokens = new address[](1);
    wethAssetTokens[0] = address(weth);

    AppPoolConfig.LpPoolConfig memory wethLpPoolConfig;
    wethLpPoolConfig = AppPoolConfig.LpPoolConfig({
      baseInterestRate: MarketConfig.getBaseInterestRate(),
      poolLiquidityLimit: MarketConfig.getPoolLiquidityLimit(),
      mintFeeRate: MarketConfig.getMintFeeRate(),
      redeemFeeRate: MarketConfig.getRedeemFeeRate(),
      poolPnlRatioLimit: MarketConfig.getPoolPnlRatioLimit(),
      unsettledBaseTokenRatioLimit: MarketConfig.getUnsettledBaseTokenRatioLimit(),
      unsettledStableTokenRatioLimit: MarketConfig.getUnsettledStableTokenRatioLimit(),
      poolStableTokenRatioLimit: MarketConfig.getPoolStableTokenRatioLimit(),
      poolStableTokenLossLimit: MarketConfig.getPoolStableTokenLossLimit(),
      assetTokens: wethAssetTokens
    });

    IConfig.LpPoolConfigParams memory wethConfigParams;
    wethConfigParams = IConfig.LpPoolConfigParams({
      stakeToken: stakedTokens[0],
      config: wethLpPoolConfig
    });

    diamondConfigFacet.setPoolConfig(wethConfigParams);

    address[] memory btcAssetTokens = new address[](1);
    btcAssetTokens[0] = address(wbtc);

    AppPoolConfig.LpPoolConfig memory btcLpPoolConfig;
    wethLpPoolConfig = AppPoolConfig.LpPoolConfig({
      baseInterestRate: MarketConfig.getBaseInterestRate(),
      poolLiquidityLimit: MarketConfig.getPoolLiquidityLimit(),
      mintFeeRate: MarketConfig.getMintFeeRate(),
      redeemFeeRate: MarketConfig.getRedeemFeeRate(),
      poolPnlRatioLimit: MarketConfig.getPoolPnlRatioLimit(),
      unsettledBaseTokenRatioLimit: MarketConfig.getUnsettledBaseTokenRatioLimit(),
      unsettledStableTokenRatioLimit: MarketConfig.getUnsettledStableTokenRatioLimit(),
      poolStableTokenRatioLimit: MarketConfig.getPoolStableTokenRatioLimit(),
      poolStableTokenLossLimit: MarketConfig.getPoolStableTokenLossLimit(),
      assetTokens:btcAssetTokens
    });

    IConfig.LpPoolConfigParams memory btcConfigParams;
    btcConfigParams = IConfig.LpPoolConfigParams({
      stakeToken: stakedTokens[1],
      config: btcLpPoolConfig
    });

    diamondConfigFacet.setPoolConfig(btcConfigParams);

    /// Symbol Pool Config

    AppConfig.SymbolConfig memory wethSymbolConfig;
    wethSymbolConfig = AppConfig.SymbolConfig({
      maxLeverage: MarketConfig.getMaxLeverage(),
      tickSize: MarketConfig.getTickSize(), // 0.01$
      openFeeRate: MarketConfig.getEthOpenFeeRate(),
      closeFeeRate: MarketConfig.getEthCloseFeeRate(),
      maxLongOpenInterestCap: MarketConfig.getMaxLongOpenInterestCap(),
      maxShortOpenInterestCap: MarketConfig.getMaxShortOpenInterestCap(),
      longShortRatioLimit: MarketConfig.getLongShortRatioLimit(),
      longShortOiBottomLimit: MarketConfig.getLongShortOiBottomLimit()
    });

    IConfig.SymbolConfigParams memory wethParams;
    wethParams = IConfig.SymbolConfigParams({
      symbol: MarketConfig.getWethSymbol(),
      config: wethSymbolConfig
    });

    diamondConfigFacet.setSymbolConfig(wethParams);


    AppConfig.SymbolConfig memory btcSymbolConfig;
    btcSymbolConfig = AppConfig.SymbolConfig({
      maxLeverage: MarketConfig.getMaxLeverage(),
      tickSize: MarketConfig.getTickSize(), // 0.01$
      openFeeRate: MarketConfig.getBtcOpenFeeRate(),
      closeFeeRate: MarketConfig.getBtcCloseFeeRate(),
      maxLongOpenInterestCap: MarketConfig.getMaxLongOpenInterestCap(),
      maxShortOpenInterestCap: MarketConfig.getMaxShortOpenInterestCap(),
      longShortRatioLimit: MarketConfig.getLongShortRatioLimit(),
      longShortOiBottomLimit: MarketConfig.getLongShortOiBottomLimit()
    });

    IConfig.SymbolConfigParams memory btcParams;
    btcParams = IConfig.SymbolConfigParams({
      symbol: MarketConfig.getWbtcSymbol(),
      config: btcSymbolConfig
    });

    diamondConfigFacet.setSymbolConfig(btcParams);
    
    
    /// stakedUsd Pool Config

    IConfig.UsdPoolConfigParams memory UsdParams;

    address[] memory supportStableTokens_ = new address[](1);
    supportStableTokens_[0] = address(usdc);

    uint256[] memory stableTokensBorrowingInterestRate_ = new uint256[](1);
    stableTokensBorrowingInterestRate_[0] = 625000000;

    AppPoolConfig.UsdPoolConfig memory usdPoolConfig_;
    usdPoolConfig_ = AppPoolConfig.UsdPoolConfig({
      poolLiquidityLimit: MarketConfig.getPoolLiquidityLimit(), // 8 * 1e4,
      mintFeeRate: MarketConfig.getUsdcMintFeeRate(), // 10
      redeemFeeRate: MarketConfig.getUsdcRedeemFeeRate(), // 10
      unsettledRatioLimit: MarketConfig.getUsdcUnsettledRatioLimit(), // 0
      supportStableTokens: supportStableTokens_,
      stableTokensBorrowingInterestRate: stableTokensBorrowingInterestRate_
    });

    UsdParams = IConfig.UsdPoolConfigParams({
      config: usdPoolConfig_
    });

    diamondConfigFacet.setUsdPoolConfig(UsdParams);
  }

  function setCommonConfig() internal {
    /// Chain Config
    AppConfig.ChainConfig memory chainConfig_;
    chainConfig_ = AppConfig.ChainConfig({
      wrapperToken: address(weth),
      mintGasFeeLimit: ChainConfig.getMintGasFeeLimit(),
      redeemGasFeeLimit: ChainConfig.getRedeemGasFeeLimit(),
      placeIncreaseOrderGasFeeLimit: ChainConfig.getPlaceIncreaseOrderGasFeeLimit(),
      placeDecreaseOrderGasFeeLimit: ChainConfig.getPlaceDecreaseOrderGasFeeLimit(),
      positionUpdateMarginGasFeeLimit: ChainConfig.getPositionUpdateMarginGasFeeLimit(),
      positionUpdateLeverageGasFeeLimit: ChainConfig.getPositionUpdateLeverageGasFeeLimit(),
      withdrawGasFeeLimit: ChainConfig.getWithdrawGasFeeLimit(),
      claimRewardsGasFeeLimit: ChainConfig.getClaimRewardsGasFeeLimit()
    });

    /// Trade Token Config
    address[] memory tradeTokens_ = new address[](3);
    tradeTokens_[0] = address(usdc);
    tradeTokens_[1] = address(weth);
    tradeTokens_[2] = address(wbtc);

    AppTradeTokenConfig.TradeTokenConfig[] memory tradeTokenConfigs_ = new AppTradeTokenConfig.TradeTokenConfig[](3);
    tradeTokenConfigs_[0] = AppTradeTokenConfig.TradeTokenConfig({
      isSupportCollateral: UsdcTradeConfig.getUsdcIsSupportCollateral(),
      precision: UsdcTradeConfig.getUsdcPrecision(),
      discount: UsdcTradeConfig.getUsdcDiscount(),
      collateralUserCap: UsdcTradeConfig.getUsdcCollateralUserCap(),
      collateralTotalCap: UsdcTradeConfig.getUsdcCollateralTotalCap(),
      liabilityUserCap: UsdcTradeConfig.getUsdcLiabilityUserCap(),
      liabilityTotalCap: UsdcTradeConfig.getUsdcLiabilityTotalCap(),
      interestRateFactor: UsdcTradeConfig.getUsdcInterestRateFactor(),
      liquidationFactor: UsdcTradeConfig.getUsdcLiquidationFactor()
    });

    tradeTokenConfigs_[1] = AppTradeTokenConfig.TradeTokenConfig({
      isSupportCollateral: WethTradeConfig.getWethIsSupportCollateral(),
      precision: WethTradeConfig.getWethPrecision(),
      discount: WethTradeConfig.getWethDiscount(),
      collateralUserCap: WethTradeConfig.getWethCollateralUserCap(),
      collateralTotalCap: WethTradeConfig.getWethCollateralTotalCap(),
      liabilityUserCap: WethTradeConfig.getWethLiabilityUserCap(),
      liabilityTotalCap: WethTradeConfig.getWethLiabilityTotalCap(),
      interestRateFactor: WethTradeConfig.getWethInterestRateFactor(),
      liquidationFactor: WethTradeConfig.getWethLiquidationFactor()
    });

    tradeTokenConfigs_[2] = AppTradeTokenConfig.TradeTokenConfig({
      isSupportCollateral: WbtcTradeConfig.getWbtcIsSupportCollateral(),
      precision: WbtcTradeConfig.getWbtcPrecision(),
      discount: WbtcTradeConfig.getWbtcDiscount(),
      collateralUserCap: WbtcTradeConfig.getWbtcCollateralUserCap(),
      collateralTotalCap: WbtcTradeConfig.getWbtcCollateralTotalCap(),
      liabilityUserCap: WbtcTradeConfig.getWbtcLiabilityUserCap(),
      liabilityTotalCap: WbtcTradeConfig.getWbtcLiabilityTotalCap(),
      interestRateFactor: WbtcTradeConfig.getWbtcInterestRateFactor(),
      liquidationFactor: WbtcTradeConfig.getWbtcLiquidationFactor()
    });

    AppTradeConfig.TradeConfig memory tradeConfig_;
    tradeConfig_ = AppTradeConfig.TradeConfig({
      tradeTokens: tradeTokens_,
      tradeTokenConfigs: tradeTokenConfigs_,
      minOrderMarginUSD: TradeConfig.getMinOrderMarginUsd(),
      availableCollateralRatio: TradeConfig.getAvailableCollateralRatio(),
      crossLtvLimit: TradeConfig.getCrossLtvLimit(),
      maxMaintenanceMarginRate: TradeConfig.getMaxMaintenanceMarginRate(),
      fundingFeeBaseRate: TradeConfig.getFundingFeeBaseRate(),
      maxFundingBaseRate: TradeConfig.getMaxFundingBaseRate(),
      tradingFeeStakingRewardsRatio: TradeConfig.getTradingFeeStakingRewardsRatio(),
      tradingFeePoolRewardsRatio: TradeConfig.getTradingFeePoolRewardsRatio(),
      tradingFeeUsdPoolRewardsRatio: TradeConfig.getTradingFeeUsdPoolRewardsRatio(),
      borrowingFeeStakingRewardsRatio: TradeConfig.getBorrowingFeeStakingRewardsRatio(),
      borrowingFeePoolRewardsRatio: TradeConfig.getBorrowingFeePoolRewardsRatio(),
      autoReduceProfitFactor: TradeConfig.getAutoReduceProfitFactor(),
      autoReduceLiquidityFactor: TradeConfig.getAutoReduceLiquidityFactor(),
      swapSlipperTokenFactor: TradeConfig.getSwapSlipperTokenFactor()
    });


    /// Stake Configurations
    AppPoolConfig.StakeConfig memory stakeConfig_;
    stakeConfig_ = AppPoolConfig.StakeConfig({
      collateralProtectFactor: StakeConfig.getCollateralProtectFactor(),
      collateralFactor: StakeConfig.getCollateralFactor(),
      minPrecisionMultiple: StakeConfig.getMinPrecisionMultiple(),
      mintFeeStakingRewardsRatio: StakeConfig.getMintFeeStakingRewardsRatio(),
      mintFeePoolRewardsRatio: StakeConfig.getMintFeePoolRewardsRatio(),
      redeemFeeStakingRewardsRatio: StakeConfig.getRedeemFeeStakingRewardsRatio(),
      redeemFeePoolRewardsRatio: StakeConfig.getRedeemFeePoolRewardsRatio(),
      poolRewardsIntervalLimit: StakeConfig.getPoolRewardsIntervalLimit(),
      minApr: StakeConfig.getMinApr(),
      maxApr: StakeConfig.getMaxApr()
    });

    IConfig.CommonConfigParams memory params;
    params = IConfig.CommonConfigParams({
      chainConfig: chainConfig_,
      tradeConfig: tradeConfig_,
      stakeConfig: stakeConfig_,
      uniswapRouter: address(0) // uniswap router not set
    });

    diamondConfigFacet.setConfig(params);
  }


  function setupActors() internal {
    address BOB = hevm.addr(0x01); // 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf  
    address ALICE = hevm.addr(0x02); // 0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF  
    address JAKE = hevm.addr(0x03); // 0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69  
    
    // hevm.label(BOB, "Bob");
    // hevm.label(ALICE, "Alice");
    // hevm.label(JAKE, "Jake");

    USERS = new address[](3);
    USERS[0] = BOB;
    USERS[1] = ALICE;
    USERS[2] = JAKE;

    for (uint8 i = 0; i < USERS.length; i++) {
      address user = USERS[i];

      hevm.deal(user, TradeConfig.getEthInitialAllowance()); // Sets the eth balance of user to amt
      usdc.mint(user, TradeConfig.getUsdcInitialBalance() * (10 ** usdc.decimals())); // Sets the usdc balance of user to amt
      weth.mint(user, TradeConfig.getWethInitialAllowance() * (10 ** weth.decimals())); // Sets the weth balance of user to amt
      wbtc.mint(user, TradeConfig.getWbtcInitialAllowance() * (10 ** wbtc.decimals())); // Sets the wbtc balance of user to amt

      for (uint8 j = 0; j < tokens.length; j++) {
          hevm.prank(user);
          IERC20(tokens[j]).approve(diamondAddress, type(uint256).max);
      }

      for (uint8 j = 0; j < stakedTokens.length; j++) {
        hevm.prank(user);
        IERC20(stakedTokens[j]).approve(diamondAddress, type(uint256).max);
      }
    }

    assert(usdc.balanceOf(address(BOB)) == TradeConfig.getUsdcInitialBalance() * (10 ** usdc.decimals()));
    assert(usdc.balanceOf(address(ALICE)) == TradeConfig.getUsdcInitialBalance() * (10 ** usdc.decimals()));
    assert(usdc.balanceOf(address(JAKE)) == TradeConfig.getUsdcInitialBalance() * (10 ** usdc.decimals()));

    assert(weth.balanceOf(address(BOB)) == TradeConfig.getWethInitialAllowance() * (10 ** weth.decimals()));
    assert(weth.balanceOf(address(ALICE)) == TradeConfig.getWethInitialAllowance() * (10 ** weth.decimals()));
    assert(weth.balanceOf(address(JAKE)) == TradeConfig.getWethInitialAllowance() * (10 ** weth.decimals()));

    assert(wbtc.balanceOf(address(BOB)) == TradeConfig.getWbtcInitialAllowance() * (10 ** wbtc.decimals()));
    assert(wbtc.balanceOf(address(ALICE)) == TradeConfig.getWbtcInitialAllowance() * (10 ** wbtc.decimals()));
    assert(wbtc.balanceOf(address(JAKE)) == TradeConfig.getWbtcInitialAllowance() * (10 ** wbtc.decimals()));

    assert(BOB.balance == TradeConfig.getEthInitialAllowance());
    assert(ALICE.balance == TradeConfig.getEthInitialAllowance());
    assert(JAKE.balance == TradeConfig.getEthInitialAllowance());
  }


    ///////// OracleProcess /////////

    function getOracleParam(uint16 _answer) internal view returns(OracleProcess.OracleParam[] memory) {

      OracleProcess.OracleParam[] memory oracles;
        
      // use clamp to prevent overflow
      uint256 wethPrice = uint256(((_answer % 5_000) + 900) * 1e8);
      uint256 btcPrice = uint256(((_answer % 40_000) + 20_000) * 1e8);
      uint256 usdcPrice = 1e8;

      //   address[] memory tokens = new address[](2);
      //   tokens[0] = address(weth);
      //   tokens[1] = address(wbtc);
      //   OracleProcess.OracleParam[] oracles_ = new OracleProcess.OracleParam[](tokens.length);

      oracles = new OracleProcess.OracleParam[](tokens.length);


      for(uint256 i = 0; i < oracles.length; i++) {
        oracles[i].token = tokens[i];
        if(tokens[i] == address(weth)) {
            oracles[i].minPrice = int256(wethPrice);
            oracles[i].maxPrice = int256(wethPrice);    
        } else if(tokens[i] == address(wbtc)) {
            oracles[i].minPrice = int256(btcPrice);
            oracles[i].maxPrice = int256(btcPrice);  
        }else{
            oracles[i].minPrice = int256(usdcPrice);
            oracles[i].maxPrice = int256(usdcPrice);
        }
      }

      return oracles;
    }

}
