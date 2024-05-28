
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseSetup} from "@chimera/BaseSetup.sol";
import {MockAggregatorV3} from "../mocks/MockAggregatorV3.sol";
// import {EchidnaUtils} from "../utils/EchidnaUtils.sol";

import "src/storage/UsdPool.sol";
import "src/vault/TradeVault.sol";
import "src/storage/InsuranceFund.sol";
import "src/interfaces/IWETH.sol";
import "src/interfaces/IMarketManager.sol";
import "src/storage/LiabilityClean.sol";
import "src/facets/StakingAccountFacet.sol";
import "src/utils/Errors.sol";
import "src/process/DecreasePositionProcess.sol";
import "src/storage/AppVaultConfig.sol";
import "src/storage/Position.sol";
import "src/interfaces/IOrder.sol";
import "src/facets/PoolFacet.sol";
import "src/facets/RebalanceFacet.sol";
import "src/facets/FeeFacet.sol";
import "src/storage/PermissionFlag.sol";
import "src/process/MintProcess.sol";
import "src/utils/ChainUtils.sol";
import "src/process/PositionMarginProcess.sol";
import "src/interfaces/IVault.sol";
import "src/facets/OrderFacet.sol";
import "src/facets/OracleFacet.sol";
import "src/facets/FaucetFacet.sol";
import "src/storage/Withdraw.sol";
import "src/utils/TokenUtils.sol";
import "src/process/OracleProcess.sol";
import "src/interfaces/IDiamond.sol";
import "src/process/OrderProcess.sol";
import "src/storage/UpdatePositionMargin.sol";
import "src/process/ClaimRewardsProcess.sol";
import "src/storage/ClaimRewards.sol";
import "src/facets/RoleAccessControlFacet.sol";
import "src/vault/Vault.sol";
import "src/facets/StakeFacet.sol";
import "src/storage/FeeRewards.sol";
import "src/process/PositionQueryProcess.sol";
import "src/process/FeeProcess.sol";
import "src/facets/MarketManagerFacet.sol";
import "src/storage/UuidCreator.sol";
import "src/process/VaultProcess.sol";
import "src/facets/PositionFacet.sol";
import "src/facets/DiamondCutFacet.sol";
import "src/interfaces/IStake.sol";
import "src/mock/MockToken.sol";
import "src/interfaces/IPool.sol";
import "src/facets/VaultFacet.sol";
import "src/storage/AppPoolConfig.sol";
import "src/process/MarketProcess.sol";
import "src/storage/AppTradeConfig.sol";
import "src/interfaces/IOracle.sol";
import "src/storage/CommonData.sol";
import "src/utils/CalUtils.sol";
import "src/mock/Multicall3.sol";
import "src/interfaces/ISwap.sol";
import "src/interfaces/IReferral.sol";
import "src/facets/AccountFacet.sol";
import "src/storage/Market.sol";
import "src/process/CancelOrderProcess.sol";
import "src/router/DiamondInit.sol";
import "src/process/RedeemProcess.sol";
import "src/storage/AppTradeTokenConfig.sol";
import "src/storage/Referral.sol";
import "src/process/LiquidationProcess.sol";
import "src/vault/LpVault.sol";
import "src/utils/TypeUtils.sol";
import "src/facets/DiamondLoupeFacet.sol";
import "src/storage/LibDiamond.sol";
import "src/storage/StakingAccount.sol";
import "src/process/ConfigProcess.sol";
import "src/facets/LiquidationFacet.sol";
import "src/process/LpPoolProcess.sol";
import "src/facets/SwapFacet.sol";
import "src/process/IncreasePositionProcess.sol";
import "src/vault/StakeToken.sol";
import "src/storage/Account.sol";
import "src/utils/AddressUtils.sol";
import "src/interfaces/IRoleAccessControl.sol";
import "src/process/MarketFactoryProcess.sol";
import "src/interfaces/IPosition.sol";
import "src/chain/ArbSys.sol";
import "src/interfaces/IFaucet.sol";
import "src/vault/PortfolioVault.sol";
import "src/storage/Redeem.sol";
import "src/interfaces/IAccount.sol";
import "src/storage/AppStorage.sol";
import "src/storage/Order.sol";
import "src/router/Diamond.sol";
import "src/interfaces/IFee.sol";
import "src/interfaces/ILiquidation.sol";
import "src/process/LpPoolQueryProcess.sol";
import "src/mock/WETH.sol";
import "src/storage/LpPool.sol";
import "src/storage/OracleFeed.sol";
import "src/interfaces/IDiamondCut.sol";
import "src/facets/ReferralFacet.sol";
import "src/facets/MarketFacet.sol";
import "src/facets/ConfigFacet.sol";
import "src/utils/TransferUtils.sol";
import "src/interfaces/IDiamondLoupe.sol";
import "src/storage/UpdateLeverage.sol";
import "src/interfaces/IMarket.sol";
import "src/storage/RoleAccessControl.sol";
import "src/storage/AppConfig.sol";
import "src/interfaces/IRebalance.sol";
import "src/process/FeeQueryProcess.sol";
import "src/process/AssetsProcess.sol";
import "src/storage/Mint.sol";
import "src/process/MarketQueryProcess.sol";
import "src/interfaces/IStakingAccount.sol";
import "src/process/GasProcess.sol";


interface IHevm {
  // Set block.timestamp to newTimestamp
  function warp(uint256 newTimestamp) external;

  // Set block.number to newNumber
  function roll(uint256 newNumber) external;

  // Add the condition b to the assumption base for the current branch
  // This function is almost identical to require
  function assume(bool b) external;

  // Sets the eth balance of usr to amt
  function deal(address usr, uint256 amt) external;

  // Signs data (privateKey, digest) => (v, r, s)
  function sign(uint256 privateKey, bytes32 digest) external returns (uint8 v, bytes32 r, bytes32 s);

  // Gets address for a given private key
  function addr(uint256 privateKey) external returns (address addr);

  // Performs the next smart contract call with specified `msg.sender`
  function prank(address newSender) external;

  // Labels the address in traces
  function label(address addr, string calldata label) external;
}
abstract contract Setup is BaseSetup {
  IHevm hevm = IHevm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
  
  ///////// Network Assets ////////
  WETH weth;
  MockToken wbtc;
  MockToken usdc;
  address ETH_ADDRESS;
  address[] internal tokens;
  
  
  StakeToken stakedETH;
  StakeToken stakedBTC;
  StakeToken stakedUSD;
  address[] internal stakedTokens;
  
  ///////// Oracle PriceFeeds ////////
  MockAggregatorV3 public wethFeed;
  MockAggregatorV3 public usdcFeed;
  MockAggregatorV3 public btcFeed;

  uint8 public wethFeedDecimals = 8; // Arb: 8, Base: 8
  uint8 public usdcFeedDecimals = 8; // Arb: 8, Base: 8
  uint8 public btcFeedDecimals = 8; // Arb: 8, Base: 8 // Try Testing with 6 to assess how the protocol behaves in this scenario

  ///////// Facets ////////
  AccountFacet accountFacet;
  DiamondCutFacet diamondCutFacet;
  DiamondLoupeFacet diamondLoupeFacet;
  OrderFacet orderFacet;
  PositionFacet positionFacet;
  RoleAccessControlFacet roleAccessControlFacet;
  StakeFacet stakeFacet;
  OracleFacet oracleFacet;
  StakingAccountFacet stakingAccountFacet;
  PoolFacet poolFacet;
  RebalanceFacet rebalanceFacet;
  FeeFacet feeFacet;
  FaucetFacet faucetFacet;
  MarketManagerFacet marketManagerFacet;
  VaultFacet vaultFacet;
  LiquidationFacet liquidationFacet;
  SwapFacet swapFacet;
  ReferralFacet referralFacet;
  MarketFacet marketFacet;
  ConfigFacet configFacet;

  ///////// Diamond Facets ////////
  IAccount diamondAccountFacet;
  IDiamondCut diamondDiamondCutFacet;
  IDiamondLoupe diamondDiamondLoupeFacet;
  IOrder diamondOrderFacet;
  IPosition diamondPositionFacet;
  IRoleAccessControl diamondRoleAccessControlFacet;
  IStake diamondStakeFacet;
  IOracle diamondOracleFacet;
  
  ConfigFacet diamondConfigFacet;
  IStakingAccount diamondStakingAccountFacet;
  IPool diamondPoolFacet;
  IRebalance diamondRebalanceFacet;
  IFee diamondFeeFacet;
  IFaucet diamondFaucetFacet;
  IMarketManager diamondMarketManagerFacet;
  IVault diamondVaultFacet;
  ILiquidation diamondLiquidationFacet;
  ISwap diamondSwapFacet;
  IReferral diamondReferralFacet;
  IMarket diamondMarketFacet;


  ///////// Router ////////
  DiamondInit diamondInit;
  Diamond diamond;
  address diamondAddress;

  ///////// Vault ////////
  LpVault lpVault;
  PortfolioVault portfolioVault;
  TradeVault tradeVault;
  
  ///////// Facets ////////
  address internal keeper = address(this);
  address internal admin = address(this);
  
  ///////// Util ////////
  // Multicall3 multicall3;
  
  ///////// Network Configurations ////////
  
  /// Roles Configurations
  bytes32 ROLE_ADMIN = "ADMIN";
  bytes32 ROLE_UPGRADE = "UPGRADE";
  bytes32 ROLE_CONFIG = "CONFIG";
  bytes32 ROLE_KEEPER = "KEEPER";


  /// Pools Configurations
  bytes32 codeHash1 = "WETHUSDC";
  bytes32 codeHash2 = "WBTCUSDC";
  string stakedWeth = "xETH";
  string stakedWbtc = "xBTC";
  string stakedUsdc = "xUSD";
  
  /// Market Configurations
  uint256 BASE_INTEREST_RATE = 6250000000;
  uint256 POOL_LIQUIDITY_LIMIT = 8 * 1e4;
  uint256 MINT_FEE_RATE = 120;
  uint256 REDEEM_FEE_RATE = 150;
  uint256 POOL_PNL_RATIO_LIMIT = 0;
  uint256 UNSETTLED_BASE_TOKEN_RATIO_LIMIT = 0;
  uint256 UNSETTLED_STABLE_TOKEN_RATIO_LIMIT = 0;
  uint256 POOL_STABLE_TOKEN_RATIO_LIMIT = 0;
  uint256 POOL_STABLE_TOKEN_LOSS_LIMIT = 0;
  
  
  bytes32 WETH_SYMBOL = "WETHUSDC";
  bytes32 WBTC_SYMBOL = "WBTCUSDC";

  uint256 MAX_LEVERAGE = 20 * 1e5;
  uint256 TICK_SIZE = 1_000_000;
  uint256 ETH_OPEN_FEE_RATE = 110;
  uint256 BTC_OPEN_FEE_RATE = 150;
  uint256 ETH_CLOSE_FEE_RATE = 130;
  uint256 BTC_CLOSE_FEE_RATE = 170;
  uint256 MAX_LONG_OPEN_INTEREST_CAP = 10_000_000 * 1e18;
  uint256 MAX_SHORT_OPEN_INTEREST_CAP = 10_000_000 * 1e18;
  uint256 LONG_SHORT_RATIO_LIMIT = 5 * 1e4;
  uint256 LONG_SHORT_OI_BOTTOM_LIMIT = 100_000 * 1e18;

  uint256 USDC_MINT_FEE_RATE = 10;
  uint256 USDC_REDEEM_FEE_RATE = 10;
  uint256 USDC_UNSETTLED_RATIO_LIMIT = 0;

  /// Chain Configurations
  uint256 MINT_GAS_FEE_LIMIT = 1_500_000;
  uint256 REDEEM_GAS_FEE_LIMIT = 1_500_000;
  uint256 PLACE_INCREASE_ORDER_GAS_FEE_LIMIT = 1_500_000;
  uint256 PLACE_DECREASE_ORDER_GAS_FEE_LIMIT = 1_500_000;
  uint256 POSITION_UPDATE_MARGIN_GAS_FEE_LIMIT = 1_500_000;
  uint256 POSITION_UPDATE_LEVERAGE_GAS_FEE_LIMIT = 1_500_000;
  uint256 WITHDRAW_GAS_FEE_LIMIT = 1_500_000;
  uint256 CLAIM_REWARDS_GAS_FEE_LIMIT = 1_500_000;

  /// Stake Configurations
  uint256 COLLATERAL_PROTECT_FACTOR = 5 * 1e2;
  uint256 COLLATERAL_FACTOR = 5 * 1e3;
  uint256 MIN_PRECISION_MULTIPLE = 11;
  uint256 MINT_FEE_STAKING_REWARDS_RATIO = 27 * 1e3;
  uint256 MINT_FEE_POOL_REWARDS_RATIO = 63 * 1e3;
  uint256 REDEEM_FEE_STAKING_REWARDS_RATIO = 27 * 1e3;
  uint256 REDEEM_FEE_POOL_REWARDS_RATIO = 63 * 1e3;
  uint256 POOL_REWARDS_INTERVAL_LIMIT = 0;
  uint256 MIN_APR = 2 * 1e4;
  uint256 MAX_APR = 20 * 1e5;

  /// Trade Configurations
  bool USDC_IS_SUPPORT_COLLATERAL = true;
  uint256 USDC_PRECISION = 2;
  uint256 USDC_DISCOUNT = 99 * 1e3;
  uint256 USDC_COLLATERAL_USER_CAP = 200_000 * 1e6;
  uint256 USDC_COLLATERAL_TOTAL_CAP = 200_000_000 * 1e6;
  uint256 USDC_LIABILITY_USER_CAP = 5_000 * 1e6;
  uint256 USDC_LIABILITY_TOTAL_CAP = 1_000_000 * 1e6;
  uint256 USDC_INTEREST_RATE_FACTOR = 10;
  uint256 USDC_LIQUIDATION_FACTOR = 5 * 1e3;

  bool WETH_IS_SUPPORT_COLLATERAL = true;
  uint256 WETH_PRECISION = 6; 
  uint256 WETH_DISCOUNT = 99 * 1e3; // TODO: change value to be different from wbtc values and test again
  uint256 WETH_COLLATERAL_USER_CAP = 100 * 1e18;
  uint256 WETH_COLLATERAL_TOTAL_CAP = 100_000 * 1e18; 
  uint256 WETH_LIABILITY_USER_CAP = 1 * 1e18; 
  uint256 WETH_LIABILITY_TOTAL_CAP = 50 * 1e18;
  uint256 WETH_INTEREST_RATE_FACTOR = 10; // TODO: change value to be different from wbtc values and test again
  uint256 WETH_LIQUIDATION_FACTOR = 5 * 1e3; // TODO: change value to be different from wbtc values and test again

  bool WBTC_IS_SUPPORT_COLLATERAL = true;
  uint256 WBTC_PRECISION = 6;
  uint256 WBTC_DISCOUNT = 99 * 1e3;
  uint256 WBTC_COLLATERAL_USER_CAP = 10 * 1e18;
  uint256 WBTC_COLLATERAL_TOTAL_CAP = 10_000 * 1e18;
  uint256 WBTC_LIABILITY_USER_CAP = 1 * 1e17;
  uint256 WBTC_LIABILITY_TOTAL_CAP = 5 * 1e18;
  uint256 WBTC_INTEREST_RATE_FACTOR = 10;
  uint256 WBTC_LIQUIDATION_FACTOR = 5 * 1e3;

  uint256 MIN_ORDER_MARGIN_USD = 10 * 1e18; // 10$
  uint256 AVAILABLE_COLLATERAL_RATIO = 12 * 1e4;
  uint256 CROSS_LTV_LIMIT = 12 * 1e4;
  uint256 MAX_MAINTENANCE_MARGIN_RATE = 1 * 1e3;
  uint256 FUNDING_FEE_BASE_RATE = 20_000_000_000;
  uint256 MAX_FUNDING_BASE_RATE = 200_000_000_000;
  uint256 TRADING_FEE_STAKING_REWARDS_RATIO = 27 * 1e3;
  uint256 TRADING_FEE_POOL_REWARDS_RATIO = 63 * 1e3;
  uint256 TRADING_FEE_USD_POOL_REWARDS_RATIO = 1 * 1e4;
  uint256 BORROWING_FEE_STAKING_REWARDS_RATIO = 27 * 1e3;
  uint256 BORROWING_FEE_POOL_REWARDS_RATIO = 63 * 1e3;
  uint256 AUTO_REDUCE_PROFIT_FACTOR = 0;
  uint256 AUTO_REDUCE_LIQUIDITY_FACTOR = 0;
  uint256 SWAP_SLIPPER_TOKEN_FACTOR = 5 * 1e3;


  address internal BOB; // vm.addr(0x01); // 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf  
  address internal ALICE; // vm.addr(0x02); // 0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF  
  address internal JAKE; // vm.addr(0x03); // 0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69  

  address[] internal USERS;

  uint256  ETH_INITIAL_ALLOWANCE = 100e18;
  uint256 USDC_INITIAL_BALANCE = 100_000;
  uint256  WETH_INITIAL_ALLOWANCE = 100;
  uint256  WBTC_INITIAL_ALLOWANCE = 10;

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

    /// Deploy Facets
    deployFacets();

    /// Deploy Router
    diamondInit = new DiamondInit();
    diamond = new Diamond(address(diamondCutFacet), address(diamondLoupeFacet), address(diamondInit), address(this));
    diamondAddress = address(diamond);

    /// Setup DiamondFacets with Facet Interfaces
    setupDiamondFacets();

    /// Add Facets to the Router
    setupFacets();

    /// System Configurations
    configVaultAdmin(); // Configure Vaults Admin Role

    // Configure roleAccessControlFacet Roles
    // set all privileged roles to address(this)
    configDiamondRoles(); 
    assert(diamondRoleAccessControlFacet.hasRole(address(this), ROLE_ADMIN));
    assert(diamondRoleAccessControlFacet.hasRole(address(this), ROLE_UPGRADE));
    assert(diamondRoleAccessControlFacet.hasRole(address(this), ROLE_CONFIG));
    assert(diamondRoleAccessControlFacet.hasRole(address(this), ROLE_KEEPER));

    // Configure setVaultConfig
    setElfiVaultConfig();

    // Configure Markets
    createMarketsAndPools();

    setLpPoolConfig();

    setCommonConfig();

    stakedTokens = new address[](3);
    stakedTokens[0] = address(stakedETH);
    stakedTokens[1] = address(stakedBTC);
    stakedTokens[2] = address(stakedUSD);

    // TODO assert wrapper token is set to weth diamondConfigFacet.getChainConfig() == address(weth);

    /// Setup Actors and deal them some tokens
    setupActors();
  }


  function deployFacets() internal {
    accountFacet = new AccountFacet();
    diamondCutFacet = new DiamondCutFacet();
    diamondLoupeFacet = new DiamondLoupeFacet();
    orderFacet = new OrderFacet();
    positionFacet = new PositionFacet();
    roleAccessControlFacet = new RoleAccessControlFacet();
    stakeFacet = new StakeFacet();
    oracleFacet = new OracleFacet();
    stakingAccountFacet = new StakingAccountFacet();
    poolFacet = new PoolFacet();
    rebalanceFacet = new RebalanceFacet();
    feeFacet = new FeeFacet();
    faucetFacet = new FaucetFacet();
    marketManagerFacet = new MarketManagerFacet();
    vaultFacet = new VaultFacet();
    liquidationFacet = new LiquidationFacet();
    swapFacet = new SwapFacet();
    referralFacet = new ReferralFacet();
    marketFacet = new MarketFacet();
    configFacet = new ConfigFacet();
  }

  function setupDiamondFacets() internal {
    diamondAccountFacet = IAccount(address(diamond));
    diamondDiamondCutFacet = IDiamondCut(address(diamond));
    diamondDiamondLoupeFacet = IDiamondLoupe(address(diamond));
    diamondOrderFacet = IOrder(address(diamond));
    diamondPositionFacet = IPosition(address(diamond));
    diamondRoleAccessControlFacet = IRoleAccessControl(address(diamond));
    diamondStakeFacet = IStake(address(diamond));
    diamondOracleFacet = IOracle(address(diamond));
    diamondStakingAccountFacet = IStakingAccount(address(diamond));
    diamondPoolFacet = IPool(address(diamond));
    diamondRebalanceFacet = IRebalance(address(diamond));
    diamondFeeFacet = IFee(address(diamond));
    diamondFaucetFacet = IFaucet(address(diamond));
    diamondMarketManagerFacet = IMarketManager(address(diamond));
    diamondVaultFacet = IVault(address(diamond));
    diamondLiquidationFacet = ILiquidation(address(diamond));
    diamondSwapFacet = ISwap(address(diamond));
    diamondReferralFacet = IReferral(address(diamond));
    diamondMarketFacet = IMarket(address(diamond));
    diamondConfigFacet = ConfigFacet(address(diamond));
  }
  
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

  // DiamondCutFacet and DiamondLoupeFacet

  function setupFacets() internal {
    
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
        facetAddress: address(accountFacet),
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
        facetAddress: address(configFacet),
        action: IDiamond.FacetCutAction.Add,
        functionSelectors: facetVars.configFunctionSelectors
    });


    /// Prepare FaucetFacet Cut
    
    facetVars.faucetFunctionSelectors = new bytes4[](1);

    // Write functions
    facetVars.faucetFunctionSelectors[0] = IFaucet.requestTokens.selector;
    
    facetVars.cut[2] = IDiamond.FacetCut({
        facetAddress: address(faucetFacet),
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
      facetAddress: address(feeFacet),
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
      facetAddress: address(liquidationFacet),
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
      facetAddress: address(marketFacet),
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetVars.marketFunctionSelectors
    });

    
    /// Prepare MarketManagerFacet Cut

    facetVars.marketManagerFunctionSelectors = new bytes4[](2);

    // Write functions
    facetVars.marketManagerFunctionSelectors[0] = IMarketManager.createMarket.selector;
    facetVars.marketManagerFunctionSelectors[1] = IMarketManager.createStakeUsdPool.selector;

    facetVars.cut[6] = IDiamond.FacetCut({
      facetAddress: address(marketManagerFacet),
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
      facetAddress: address(oracleFacet),
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
      facetAddress: address(orderFacet),
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
      facetAddress: address(poolFacet),
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
      facetAddress: address(positionFacet),
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetVars.positionsFunctionSelectors
    });
    

    /// Prepare RebalanceFacet Cut

    facetVars.rebalanceFunctionSelectors = new bytes4[](1);

    // Write functions
    facetVars.rebalanceFunctionSelectors[0] = IRebalance.autoRebalance.selector;

    facetVars.cut[11] = IDiamond.FacetCut({
      facetAddress: address(rebalanceFacet),
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetVars.rebalanceFunctionSelectors
    });

    
    /// Prepare ReferralFacet Cut

    facetVars.referralFunctionSelectors = new bytes4[](2);

    // Read functions
    facetVars.referralFunctionSelectors[0] = IReferral.isCodeExists.selector;
    facetVars.referralFunctionSelectors[1] = IReferral.getAccountReferral.selector;

    facetVars.cut[12] = IDiamond.FacetCut({
      facetAddress: address(referralFacet),
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
      facetAddress: address(roleAccessControlFacet),
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
      facetAddress: address(stakeFacet),
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
      facetAddress: address(stakingAccountFacet),
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetVars.stakingAccountFunctionSelectors
    });

    
    /// Prepare SwapFacet Cut

    facetVars.swapFunctionSelectors = new bytes4[](1);

    // Write functions
    facetVars.swapFunctionSelectors[0] = ISwap.swapPortfolioToPayLiability.selector;

    facetVars.cut[16] = IDiamond.FacetCut({
      facetAddress: address(swapFacet),
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
      facetAddress: address(vaultFacet),
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetVars.vaultFunctionSelectors
    });
    
    diamondDiamondCutFacet.diamondCut(facetVars.cut, address(0), "");
  }

  function configVaultAdmin() internal {
    lpVault.grantAdmin(diamondAddress);
    portfolioVault.grantAdmin(diamondAddress);
    tradeVault.grantAdmin(diamondAddress);
  }

  function configDiamondRoles() internal {
    diamondRoleAccessControlFacet.grantRole(address(this), ROLE_UPGRADE);
    diamondRoleAccessControlFacet.grantRole(address(this), ROLE_CONFIG);
    diamondRoleAccessControlFacet.grantRole(address(this), ROLE_KEEPER);
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
      code: codeHash1,
      stakeTokenName: stakedWeth,
      indexToken: address(weth),
      baseToken: address(weth) // according to the deploy script its not address(usdc)
    });

    params2 = MarketFactoryProcess.CreateMarketParams({
      code: codeHash2,
      stakeTokenName: stakedWbtc,
      indexToken: address(wbtc),
      baseToken: address(wbtc)
    });

    address stakeWethTokenAddress = diamondMarketManagerFacet.createMarket(params1);
    address stakeWbtcTokenAddress = diamondMarketManagerFacet.createMarket(params2);
    stakedETH = StakeToken(stakeWethTokenAddress);
    stakedBTC = StakeToken(stakeWbtcTokenAddress);
        
    address stakeUsdTokenAddress = diamondMarketManagerFacet.createStakeUsdPool(stakedUsdc, 18);
    stakedUSD = StakeToken(stakeUsdTokenAddress);
  }

  function setLpPoolConfig() internal {
    /// Market Pool Config

    address[] memory wethAssetTokens = new address[](1);
    wethAssetTokens[0] = address(weth);

    AppPoolConfig.LpPoolConfig memory wethLpPoolConfig;
    wethLpPoolConfig = AppPoolConfig.LpPoolConfig({
      baseInterestRate: BASE_INTEREST_RATE,
      poolLiquidityLimit: POOL_LIQUIDITY_LIMIT,
      mintFeeRate: MINT_FEE_RATE,
      redeemFeeRate: REDEEM_FEE_RATE,
      poolPnlRatioLimit: POOL_PNL_RATIO_LIMIT,
      unsettledBaseTokenRatioLimit: UNSETTLED_BASE_TOKEN_RATIO_LIMIT,
      unsettledStableTokenRatioLimit: UNSETTLED_STABLE_TOKEN_RATIO_LIMIT,
      poolStableTokenRatioLimit: POOL_STABLE_TOKEN_RATIO_LIMIT,
      poolStableTokenLossLimit: POOL_STABLE_TOKEN_LOSS_LIMIT,
      assetTokens: wethAssetTokens
    });

    IConfig.LpPoolConfigParams memory wethConfigParams;
    wethConfigParams = IConfig.LpPoolConfigParams({
      stakeToken: address(stakedETH),
      config: wethLpPoolConfig
    });

    diamondConfigFacet.setPoolConfig(wethConfigParams);

    address[] memory btcAssetTokens = new address[](1);
    btcAssetTokens[0] = address(wbtc);

    AppPoolConfig.LpPoolConfig memory btcLpPoolConfig;
    wethLpPoolConfig = AppPoolConfig.LpPoolConfig({
      baseInterestRate: BASE_INTEREST_RATE,
      poolLiquidityLimit: POOL_LIQUIDITY_LIMIT,
      mintFeeRate: MINT_FEE_RATE,
      redeemFeeRate: REDEEM_FEE_RATE,
      poolPnlRatioLimit: POOL_PNL_RATIO_LIMIT,
      unsettledBaseTokenRatioLimit: UNSETTLED_BASE_TOKEN_RATIO_LIMIT,
      unsettledStableTokenRatioLimit: UNSETTLED_STABLE_TOKEN_RATIO_LIMIT,
      poolStableTokenRatioLimit: POOL_STABLE_TOKEN_RATIO_LIMIT,
      poolStableTokenLossLimit: POOL_STABLE_TOKEN_LOSS_LIMIT,
      assetTokens:btcAssetTokens
    });

    IConfig.LpPoolConfigParams memory btcConfigParams;
    btcConfigParams = IConfig.LpPoolConfigParams({
      stakeToken: address(stakedBTC),
      config: btcLpPoolConfig
    });

    diamondConfigFacet.setPoolConfig(btcConfigParams);

    /// Symbol Pool Config

    AppConfig.SymbolConfig memory wethSymbolConfig;
    wethSymbolConfig = AppConfig.SymbolConfig({
      maxLeverage: MAX_LEVERAGE,
      tickSize: TICK_SIZE, // 0.01$
      openFeeRate: ETH_OPEN_FEE_RATE,
      closeFeeRate: ETH_CLOSE_FEE_RATE,
      maxLongOpenInterestCap: MAX_LONG_OPEN_INTEREST_CAP,
      maxShortOpenInterestCap: MAX_SHORT_OPEN_INTEREST_CAP,
      longShortRatioLimit: LONG_SHORT_RATIO_LIMIT,
      longShortOiBottomLimit: LONG_SHORT_OI_BOTTOM_LIMIT
    });

    IConfig.SymbolConfigParams memory wethParams;
    wethParams = IConfig.SymbolConfigParams({
      symbol: WETH_SYMBOL,
      config: wethSymbolConfig
    });

    diamondConfigFacet.setSymbolConfig(wethParams);


    AppConfig.SymbolConfig memory btcSymbolConfig;
    btcSymbolConfig = AppConfig.SymbolConfig({
      maxLeverage: MAX_LEVERAGE,
      tickSize: TICK_SIZE, // 0.01$
      openFeeRate: BTC_OPEN_FEE_RATE,
      closeFeeRate: BTC_CLOSE_FEE_RATE,
      maxLongOpenInterestCap: MAX_LONG_OPEN_INTEREST_CAP,
      maxShortOpenInterestCap: MAX_SHORT_OPEN_INTEREST_CAP,
      longShortRatioLimit: LONG_SHORT_RATIO_LIMIT,
      longShortOiBottomLimit: LONG_SHORT_OI_BOTTOM_LIMIT
    });

    IConfig.SymbolConfigParams memory btcParams;
    btcParams = IConfig.SymbolConfigParams({
      symbol: WBTC_SYMBOL,
      config: btcSymbolConfig
    });

    diamondConfigFacet.setSymbolConfig(btcParams);
    
    
    /// stakedUsd Pool Config
    /*
    struct UsdPoolConfig {
        uint256 poolLiquidityLimit;
        uint256 mintFeeRate;
        uint256 redeemFeeRate;
        uint256 unsettledRatioLimit;
        address[] supportStableTokens;
        uint256[] stableTokensBorrowingInterestRate;
    }

    */

    IConfig.UsdPoolConfigParams memory UsdParams;

    address[] memory supportStableTokens_ = new address[](1);
    supportStableTokens_[0] = address(usdc);

    uint256[] memory stableTokensBorrowingInterestRate_ = new uint256[](1);
    stableTokensBorrowingInterestRate_[0] = 625000000;

    AppPoolConfig.UsdPoolConfig memory usdPoolConfig_;
    usdPoolConfig_ = AppPoolConfig.UsdPoolConfig({
      poolLiquidityLimit: POOL_LIQUIDITY_LIMIT, // 8 * 1e4,
      mintFeeRate: USDC_MINT_FEE_RATE, // 10
      redeemFeeRate: USDC_REDEEM_FEE_RATE, // 10
      unsettledRatioLimit: USDC_UNSETTLED_RATIO_LIMIT, // 0
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
      mintGasFeeLimit: MINT_GAS_FEE_LIMIT,
      redeemGasFeeLimit: REDEEM_GAS_FEE_LIMIT,
      placeIncreaseOrderGasFeeLimit: PLACE_INCREASE_ORDER_GAS_FEE_LIMIT,
      placeDecreaseOrderGasFeeLimit: PLACE_DECREASE_ORDER_GAS_FEE_LIMIT,
      positionUpdateMarginGasFeeLimit: POSITION_UPDATE_MARGIN_GAS_FEE_LIMIT,
      positionUpdateLeverageGasFeeLimit: POSITION_UPDATE_LEVERAGE_GAS_FEE_LIMIT,
      withdrawGasFeeLimit: WITHDRAW_GAS_FEE_LIMIT,
      claimRewardsGasFeeLimit: CLAIM_REWARDS_GAS_FEE_LIMIT
    });

    /// Trade Token Config
    address[] memory tradeTokens_ = new address[](3);
    tradeTokens_[0] = address(usdc);
    tradeTokens_[1] = address(weth);
    tradeTokens_[2] = address(wbtc);

    AppTradeTokenConfig.TradeTokenConfig[] memory tradeTokenConfigs_ = new AppTradeTokenConfig.TradeTokenConfig[](3);
    tradeTokenConfigs_[0] = AppTradeTokenConfig.TradeTokenConfig({
      isSupportCollateral: USDC_IS_SUPPORT_COLLATERAL,
      precision: USDC_PRECISION,
      discount: USDC_DISCOUNT,
      collateralUserCap: USDC_COLLATERAL_USER_CAP,
      collateralTotalCap: USDC_COLLATERAL_TOTAL_CAP,
      liabilityUserCap: USDC_LIABILITY_USER_CAP,
      liabilityTotalCap: USDC_LIABILITY_TOTAL_CAP,
      interestRateFactor: USDC_INTEREST_RATE_FACTOR,
      liquidationFactor: USDC_LIQUIDATION_FACTOR
    });

    tradeTokenConfigs_[1] = AppTradeTokenConfig.TradeTokenConfig({
      isSupportCollateral: WETH_IS_SUPPORT_COLLATERAL,
      precision: WETH_PRECISION,
      discount: WETH_DISCOUNT,
      collateralUserCap: WETH_COLLATERAL_USER_CAP,
      collateralTotalCap: WETH_COLLATERAL_TOTAL_CAP,
      liabilityUserCap: WETH_LIABILITY_USER_CAP,
      liabilityTotalCap: WETH_LIABILITY_TOTAL_CAP,
      interestRateFactor: WETH_INTEREST_RATE_FACTOR,
      liquidationFactor: WETH_LIQUIDATION_FACTOR
    });

    tradeTokenConfigs_[2] = AppTradeTokenConfig.TradeTokenConfig({
      isSupportCollateral: WBTC_IS_SUPPORT_COLLATERAL,
      precision: WBTC_PRECISION,
      discount: WBTC_DISCOUNT,
      collateralUserCap: WBTC_COLLATERAL_USER_CAP,
      collateralTotalCap: WBTC_COLLATERAL_TOTAL_CAP,
      liabilityUserCap: WBTC_LIABILITY_USER_CAP,
      liabilityTotalCap: WBTC_LIABILITY_TOTAL_CAP,
      interestRateFactor: WBTC_INTEREST_RATE_FACTOR,
      liquidationFactor: WBTC_LIQUIDATION_FACTOR
    });

    AppTradeConfig.TradeConfig memory tradeConfig_;
    tradeConfig_ = AppTradeConfig.TradeConfig({
      tradeTokens: tradeTokens_,
      tradeTokenConfigs: tradeTokenConfigs_,
      minOrderMarginUSD: MIN_ORDER_MARGIN_USD,
      availableCollateralRatio: AVAILABLE_COLLATERAL_RATIO,
      crossLtvLimit: CROSS_LTV_LIMIT,
      maxMaintenanceMarginRate: MAX_MAINTENANCE_MARGIN_RATE,
      fundingFeeBaseRate: FUNDING_FEE_BASE_RATE,
      maxFundingBaseRate: MAX_FUNDING_BASE_RATE,
      tradingFeeStakingRewardsRatio: TRADING_FEE_STAKING_REWARDS_RATIO,
      tradingFeePoolRewardsRatio: TRADING_FEE_POOL_REWARDS_RATIO,
      tradingFeeUsdPoolRewardsRatio: TRADING_FEE_USD_POOL_REWARDS_RATIO,
      borrowingFeeStakingRewardsRatio: BORROWING_FEE_STAKING_REWARDS_RATIO,
      borrowingFeePoolRewardsRatio: BORROWING_FEE_POOL_REWARDS_RATIO,
      autoReduceProfitFactor: AUTO_REDUCE_PROFIT_FACTOR,
      autoReduceLiquidityFactor: AUTO_REDUCE_LIQUIDITY_FACTOR,
      swapSlipperTokenFactor: SWAP_SLIPPER_TOKEN_FACTOR
    });


    /// Stake Configurations
    AppPoolConfig.StakeConfig memory stakeConfig_;
    stakeConfig_ = AppPoolConfig.StakeConfig({
      collateralProtectFactor: COLLATERAL_PROTECT_FACTOR,
      collateralFactor: COLLATERAL_FACTOR,
      minPrecisionMultiple: MIN_PRECISION_MULTIPLE,
      mintFeeStakingRewardsRatio: MINT_FEE_STAKING_REWARDS_RATIO,
      mintFeePoolRewardsRatio: MINT_FEE_POOL_REWARDS_RATIO,
      redeemFeeStakingRewardsRatio: REDEEM_FEE_STAKING_REWARDS_RATIO,
      redeemFeePoolRewardsRatio: REDEEM_FEE_POOL_REWARDS_RATIO,
      poolRewardsIntervalLimit: POOL_REWARDS_INTERVAL_LIMIT,
      minApr: MIN_APR,
      maxApr: MAX_APR
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
    BOB = hevm.addr(0x01); // 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf  
    ALICE = hevm.addr(0x02); // 0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF  
    JAKE = hevm.addr(0x03); // 0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69  
    
    hevm.label(BOB, "Bob");
    hevm.label(ALICE, "Alice");
    hevm.label(JAKE, "Jake");

    USERS = new address[](3);
    USERS[0] = BOB;
    USERS[1] = ALICE;
    USERS[2] = JAKE;

    for (uint8 i = 0; i < USERS.length; i++) {
      address user = USERS[i];

      hevm.deal(user, ETH_INITIAL_ALLOWANCE); // Sets the eth balance of user to amt
      usdc.mint(user, USDC_INITIAL_BALANCE * (10 ** usdc.decimals())); // Sets the usdc balance of user to amt
      weth.mint(user, WETH_INITIAL_ALLOWANCE * (10 ** weth.decimals())); // Sets the weth balance of user to amt
      wbtc.mint(user, WBTC_INITIAL_ALLOWANCE * (10 ** wbtc.decimals())); // Sets the wbtc balance of user to amt

      for (uint8 j = 0; j < tokens.length; j++) {
          hevm.prank(user);
          IERC20(tokens[j]).approve(diamondAddress, type(uint256).max);
      }
    }

    assert(usdc.balanceOf(address(BOB)) == USDC_INITIAL_BALANCE * (10 ** usdc.decimals()));
    assert(usdc.balanceOf(address(ALICE)) == USDC_INITIAL_BALANCE * (10 ** usdc.decimals()));
    assert(usdc.balanceOf(address(JAKE)) == USDC_INITIAL_BALANCE * (10 ** usdc.decimals()));

    assert(weth.balanceOf(address(BOB)) == WETH_INITIAL_ALLOWANCE * (10 ** weth.decimals()));
    assert(weth.balanceOf(address(ALICE)) == WETH_INITIAL_ALLOWANCE * (10 ** weth.decimals()));
    assert(weth.balanceOf(address(JAKE)) == WETH_INITIAL_ALLOWANCE * (10 ** weth.decimals()));

    assert(wbtc.balanceOf(address(BOB)) == WBTC_INITIAL_ALLOWANCE * (10 ** wbtc.decimals()));
    assert(wbtc.balanceOf(address(ALICE)) == WBTC_INITIAL_ALLOWANCE * (10 ** wbtc.decimals()));
    assert(wbtc.balanceOf(address(JAKE)) == WBTC_INITIAL_ALLOWANCE * (10 ** wbtc.decimals()));

    assert(BOB.balance == ETH_INITIAL_ALLOWANCE);
    assert(ALICE.balance == ETH_INITIAL_ALLOWANCE);
    assert(JAKE.balance == ETH_INITIAL_ALLOWANCE);
  }
}
