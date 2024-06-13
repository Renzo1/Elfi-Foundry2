
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Setup} from "./Setup.sol";

import "src/interfaces/IOrder.sol"; 
import "src/storage/Order.sol";
import "src/storage/Account.sol"; 
import "src/storage/Symbol.sol"; 
import "src/interfaces/IPosition.sol"; 
import "src/interfaces/IAccount.sol"; 
import "src/interfaces/IStakingAccount.sol";
import "src/interfaces/IFee.sol";
import "src/interfaces/IPool.sol";
import "src/interfaces/IMarket.sol";

import "../constants/ChainConfig.sol";
import "../constants/MarketConfig.sol";
import "../constants/RolesAndPools.sol";
import "../constants/StakeConfig.sol";
import "../constants/TradeConfig.sol";
import "../constants/UsdcTradeConfig.sol";
import "../constants/WbtcTradeConfig.sol";
import "../constants/WethTradeConfig.sol";
import "../FacetDeployer.sol";

abstract contract BeforeAfter is Setup {

    struct Vars {

        ///////// AccountFacet /////////
        /// getAccountInfo deconstructed values
        address accountOwner;
        // Account.TokenBalance[] accountTokenBalances;
        address[] accountTokens;
        bytes32[] accountPositions;
        uint256 accountPortfolioNetValue;
        uint256 accountTotalUsedValue;
        int256 accountAvailableValue;
        uint256 accountOrderHoldInUsd;
        int256 accountCrossMMR;
        int256 accountCrossNetValue;
        uint256 accountTotalMM;

        /// Account.TokenBalance[] deconstructed values
        uint256[] accountTokenBalancesAmount;
        uint256[] accountTokenBalancesUsedAmount;
        uint256[] accountTokenBalancesInterest;
        uint256[] accountTokenBalancesLiability;
        

        /// getAccountInfoWithOracles deconstructed values
        address accountOwnerWithOracles;
        // Account.TokenBalance[] accountTokenBalancesWithOracles;
        address[] accountTokensWithOracles;
        bytes32[] accountPositionsWithOracles;
        uint256 accountPortfolioNetValueWithOracles;
        uint256 accountTotalUsedValueWithOracles;
        int256 accountAvailableValueWithOracles;
        uint256 accountOrderHoldInUsdWithOracles;
        int256 accountCrossMMRWithOracles;
        int256 accountCrossNetValueWithOracles;
        uint256 accountTotalMMWithOracles;

        /// Account.TokenBalance[] deconstructed values
        uint256[] accountTokenBalancesAmountWithOracles;
        uint256[] accountTokenBalancesUsedAmountWithOracles;
        uint256[] accountTokenBalancesInterestWithOracles;
        uint256[] accountTokenBalancesLiabilityWithOracles;

        ///////// OrderFacet /////////
        // IOrder.AccountOrder[] accountOrders;
        uint256[] orderId;

        /// Order.OrderInfo deconstructed values
        address[] orderAccount;
        bytes32[] symbol;
        Order.Side[] orderSide;
        Order.PositionSide[] posSide;
        Order.Type[] orderType;
        Order.StopType[] stopType;
        bool[] isCrossMargin;
        bool[] isExecutionFeeFromTradeVault;
        address[] marginToken;
        uint256[] qty;
        uint256[] leverage; //position leverage
        uint256[] orderMargin;
        uint256[] triggerPrice; // for limit & stop order
        uint256[] acceptablePrice; //for market & stop order
        uint256[] placeTime;
        uint256[] executionFee;
        uint256[] lastBlock;

        ///////// PositionFacet /////////
        // IPosition.PositionInfo deconstructed values
        uint256[] positionLiquidationPrice;
        uint256[] positionCurrentTimestamp;
        
        // Props deconstructed values
        bytes32[] positionKey;
        bytes32[] positionSymbol;
        bool[] positionIsLong;
        bool[] positionIsCrossMargin;
        address[] positionAccount;
        address[] positionMarginToken;
        address[] positionIndexToken;
        uint256[] positionQty;
        uint256[] positionEntryPrice;
        uint256[] positionLeverage;
        uint256[] positionInitialMargin;
        uint256[] positionInitialMarginInUsd;
        uint256[] positionInitialMarginInUsdFromBalance;
        uint256[] positionHoldPoolAmount;
        int256[] positionRealizedPnl;
        uint256[] positionLastUpdateTime;

        // PositionFee deconstructed values
        uint256[] positionCloseFeeInUsd;
        uint256[] positionOpenBorrowingFeePerToken;
        uint256[] positionRealizedBorrowingFee;
        uint256[] positionRealizedBorrowingFeeInUsd;
        int256[] positionOpenFundingFeePerQty;
        int256[] positionRealizedFundingFee;
        int256[] positionRealizedFundingFeeInUsd;


        ///////// StakingAccountFacet Computations /////////
        uint256 stakingAccountFacet_getAccountPoolCollateralAmount;
        uint256 stakingAccountFacet_getAccountUsdPoolAmount;
        
        // stakingAccountFacet_getAccountPoolBalance deconstructed values
        uint256 stakingAccount_AccountPoolBalance_stakeAmount;
        address[] stakingAccount_AccountPoolBalance_collateralTokens;
        uint256[] stakingAccount_AccountPoolBalance_collateralAmounts;
        uint256[] stakingAccount_AccountPoolBalance_collateralStakeLiability;


        // ///////// FeeFacet Computations /////////
        uint256 feeFacet_getCumulativeRewardsPerStakeToken;
        uint256 feeFacet_getDaoTokenFee;
        uint256 feeFacet_getMarketTokenFee;
        uint256 feeFacet_getPoolTokenFee;
        uint256 feeFacet_getStakingTokenFee;
        
        // feeFacet_getAccountUsdFeeReward deconstructed values
        address accountUsdFeeReward_Account;
        address accountUsdFeeReward_StakeToken;
        uint256 accountUsdFeeReward_Reward;
        

        // tuple feeFacet_getAccountFeeRewards;
        address accountFeeRewards_Account;
        address[] accountFeeRewards_StakeTokens;
        address[] accountFeeRewards_Tokens;
        uint256[] accountFeeRewards_Rewards;


        ///////// PoolFacet Computations /////////
        /// poolFacet_getPool deconstructed values
        address pool_stakeToken;
        string pool_stakeTokenName;
        address pool_baseToken;
        bytes32 pool_symbol;
        address[] pool_stableTokens;
        uint256 pool_poolValue;
        uint256 pool_availableLiquidity;
        int256 pool_poolPnl;
        uint256 pool_totalSupply;
        uint256 pool_apr;
        uint256 pool_totalClaimedRewards;
        
        // baseTokenBalance deconstructed values
        uint256 pool_baseTokenBalance_amount;
        uint256 pool_baseTokenBalance_liability;
        uint256 pool_baseTokenBalance_holdAmount;
        int256 pool_baseTokenBalance_unsettledAmount;
        uint256 pool_baseTokenBalance_lossAmount;
        address[] pool_baseTokenBalance_collateralTokens;
        uint256[] pool_baseTokenBalance_collateralAmounts;

        // MintTokenBalance[] stableTokenBalances;
        uint256[] pool_stableTokenBalances_amount;
        uint256[] pool_stableTokenBalances_liability;
        uint256[] pool_stableTokenBalances_holdAmount;
        int256[] pool_stableTokenBalances_unsettledAmount;
        uint256[] pool_stableTokenBalances_lossAmount;
        address[][] pool_stableTokenBalances_collateralTokens;
        uint256[][] pool_stableTokenBalances_collateralAmounts;

        // LpPool.BorrowingFee borrowingFee;
        uint256 pool_borrowingFee_totalBorrowingFee;
        uint256 pool_borrowingFee_totalRealizedBorrowingFee;
        uint256 pool_borrowingFee_cumulativeBorrowingFeePerToken;
        uint256 pool_borrowingFee_lastUpdateTime;


        /// poolFacet_getUsdPool deconstructed values
        address[] usdPool_StableTokens;
        uint256[] usdPool_StableTokenMaxWithdraws;
        uint256 usdPool_PoolValue;
        uint256 usdPool_TotalSupply;
        uint256[] usdPool_TokensAvailableLiquidity;
        uint256 usdPool_Apr;
        uint256 usdPool_TotalClaimedRewards;

        // UsdPool.TokenBalance[] stableTokenBalances;
        uint256[] usdPool_stableTokenBalances_amount;
        uint256[] usdPool_stableTokenBalances_holdAmount;
        uint256[] usdPool_stableTokenBalances_unsettledAmount;

        // UsdPool.BorrowingFee[] borrowingFees;
        uint256[] usdPool_BorrowingFee_totalBorrowingFee;
        uint256[] usdPool_BorrowingFee_totalRealizedBorrowingFee;
        uint256[] usdPool_BorrowingFee_cumulativeBorrowingFeePerToken;
        uint256[] usdPool_BorrowingFee_lastUpdateTime;

        ///////// MarketFacet Computations /////////
        address marketFacet_getStakeUsdToken;

        /// marketFacet_getTradeTokenInfo deconstructed values
        uint256 market_TradeTokenInfo_TradeTokenCollateral;
        uint256 market_TradeTokenInfo_TradeTokenLiability;


        // marketFacet_getMarketInfo deconstructed values
        uint256 market_MarketInfo_LongPositionInterest;
        uint256 market_MarketInfo_LongPositionEntryPrice;
        uint256 market_MarketInfo_TotalShortPositionInterest;
        uint256 market_MarketInfo_AvailableLiquidity;

        // Symbol.Props symbolInfo;
        bytes32 market_MarketInfo_SymbolInfo_Code;
        Symbol.Status market_MarketInfo_SymbolInfo_Status;
        address market_MarketInfo_SymbolInfo_StakeToken;
        address market_MarketInfo_SymbolInfo_IndexToken;
        address market_MarketInfo_SymbolInfo_BaseToken;
        string market_MarketInfo_SymbolInfo_BaseTokenName;


        // Market.MarketPosition[] shortPositions;
        uint256[] market_MarketInfo_ShortPositions_openInterest;
        uint256[] market_MarketInfo_ShortPositions_entryPrice;

        // Market.FundingFee fundingFee;
        int256 market_MarketInfo_FundingFee_longFundingFeePerQty;
        int256 market_MarketInfo_FundingFee_shortFundingFeePerQty;
        int256 market_MarketInfo_FundingFee_totalLongFundingFee;
        int256 market_MarketInfo_FundingFee_totalShortFundingFee;
        int256 market_MarketInfo_FundingFee_longFundingFeeRate;
        int256 market_MarketInfo_FundingFee_shortFundingFeeRate;
        uint256 market_MarketInfo_FundingFee_lastUpdateTime;


        ///////// Custom Computations /////////
        /// PortfolioVault Balances
        uint256 portfolioVaultRawEthBalance;
        uint256 portfolioVaultWethBalance;
        uint256 portfolioVaultUsdcBalance;
        uint256 portfolioVaultBtcBalance;

        /// TradeVault Balances
        uint256 tradeVaultRawEthBalance;
        uint256 tradeVaultWethBalance;
        uint256 tradeVaultUsdcBalance;
        uint256 tradeVaultBtcBalance;

        /// LpVault Balances
        uint256 lpVaultRawEthBalance;
        uint256 lpVaultWethBalance;
        uint256 lpVaultUsdcBalance;
        uint256 lpVaultBtcBalance;
    }

    Vars internal _before;
    Vars internal _after;


    function __before(address _user, OracleProcess.OracleParam[] memory _oracles, address _stakeToken, address _collateralToken, address _token, bytes32 _code) internal {
       
        _resetBefore();

        ///////// AccountFacet /////////
        hevm.prank(_user);
        IAccount.AccountInfo memory account = diamondAccountFacet.getAccountInfo(_user);
        _before.accountOwner = account.owner;
        // _before.accountTokenBalances = account.tokenBalances;
        for(uint256 i = 0; i < account.tokenBalances.length; i++) {
            _before.accountTokenBalancesAmount[i] = account.tokenBalances[i].amount;
            _before.accountTokenBalancesUsedAmount[i] = account.tokenBalances[i].usedAmount;
            _before.accountTokenBalancesInterest[i] = account.tokenBalances[i].interest;
            _before.accountTokenBalancesLiability[i] = account.tokenBalances[i].liability;
        }

        _before.accountTokens = account.tokens;
        _before.accountPositions = account.positions;
        _before.accountPortfolioNetValue = account.portfolioNetValue;
        _before.accountTotalUsedValue = account.totalUsedValue;
        _before.accountAvailableValue = account.availableValue;
        _before.accountOrderHoldInUsd = account.orderHoldInUsd;
        _before.accountCrossMMR = account.crossMMR;
        _before.accountCrossNetValue = account.crossNetValue;
        _before.accountTotalMM = account.totalMM;

        hevm.prank(_user);
        IAccount.AccountInfo memory accountWithOracles = diamondAccountFacet.getAccountInfoWithOracles(_user, _oracles);
        _before.accountOwnerWithOracles = accountWithOracles.owner;

        // _before.accountTokenBalancesWithOracles = accountWithOracles.tokenBalances;
        for(uint256 i = 0; i < accountWithOracles.tokenBalances.length; i++) {
            _before.accountTokenBalancesAmountWithOracles[i] = accountWithOracles.tokenBalances[i].amount;
            _before.accountTokenBalancesUsedAmountWithOracles[i] = accountWithOracles.tokenBalances[i].usedAmount;
            _before.accountTokenBalancesInterestWithOracles[i] = accountWithOracles.tokenBalances[i].interest;
            _before.accountTokenBalancesLiabilityWithOracles[i] = accountWithOracles.tokenBalances[i].liability;
        }

        _before.accountTokensWithOracles = accountWithOracles.tokens;
        _before.accountPositionsWithOracles = accountWithOracles.positions;
        _before.accountPortfolioNetValueWithOracles = accountWithOracles.portfolioNetValue;
        _before.accountTotalUsedValueWithOracles = accountWithOracles.totalUsedValue;
        _before.accountAvailableValueWithOracles = accountWithOracles.availableValue;
        _before.accountOrderHoldInUsdWithOracles = accountWithOracles.orderHoldInUsd;
        _before.accountCrossMMRWithOracles = accountWithOracles.crossMMR;
        _before.accountCrossNetValueWithOracles = accountWithOracles.crossNetValue;
        _before.accountTotalMMWithOracles = accountWithOracles.totalMM;

        ///////// OrderFacet /////////
        // _before.accountOrders = diamondOrderFacet.getAccountOrders(_user);
        hevm.prank(_user);
        IOrder.AccountOrder[] memory orders= diamondOrderFacet.getAccountOrders(_user);
        for(uint256 i = 0; i < orders.length; i++) {
            _before.orderId[i] = orders[i].orderId;
            _before.orderAccount[i] = orders[i].orderInfo.account;
            _before.symbol[i] = orders[i].orderInfo.symbol;
            _before.orderSide[i] = orders[i].orderInfo.orderSide;
            _before.posSide[i] = orders[i].orderInfo.posSide;
            _before.orderType[i] = orders[i].orderInfo.orderType;
            _before.stopType[i] = orders[i].orderInfo.stopType;
            _before.isCrossMargin[i] = orders[i].orderInfo.isCrossMargin;
            _before.isExecutionFeeFromTradeVault[i] = orders[i].orderInfo.isExecutionFeeFromTradeVault;
            _before.marginToken[i] = orders[i].orderInfo.marginToken;
            _before.qty[i] = orders[i].orderInfo.qty;
            _before.leverage[i] = orders[i].orderInfo.leverage;
            _before.orderMargin[i] = orders[i].orderInfo.orderMargin;
            _before.triggerPrice[i] = orders[i].orderInfo.triggerPrice;
            _before.acceptablePrice[i] = orders[i].orderInfo.acceptablePrice;
            _before.placeTime[i] = orders[i].orderInfo.placeTime;
            _before.executionFee[i] = orders[i].orderInfo.executionFee;
            _before.lastBlock[i] = orders[i].orderInfo.lastBlock;
            
        }

        ///////// PositionFacet /////////
        // _before.accountPositionsInfo = diamondPositionFacet.getAllPositions(_user);
        hevm.prank(_user);
        IPosition.PositionInfo[] memory positions = diamondPositionFacet.getAllPositions(_user);
        for (uint256 i = 0; i < positions.length; i++) {
            _before.positionLiquidationPrice[i] = positions[i].liquidationPrice;
            _before.positionCurrentTimestamp[i] = positions[i].currentTimestamp;

            _before.positionKey[i] = positions[i].position.key;
            _before.positionSymbol[i] = positions[i].position.symbol;
            _before.positionIsLong[i] = positions[i].position.isLong;
            _before.positionIsCrossMargin[i] = positions[i].position.isCrossMargin;
            _before.positionAccount[i] = positions[i].position.account;
            _before.positionMarginToken[i] = positions[i].position.marginToken;
            _before.positionIndexToken[i] = positions[i].position.indexToken;
            _before.positionQty[i] = positions[i].position.qty;
            _before.positionEntryPrice[i] = positions[i].position.entryPrice;
            _before.positionLeverage[i] = positions[i].position.leverage;
            _before.positionInitialMargin[i] = positions[i].position.initialMargin;
            _before.positionInitialMarginInUsd[i] = positions[i].position.initialMarginInUsd;
            _before.positionInitialMarginInUsdFromBalance[i] = positions[i].position.initialMarginInUsdFromBalance;
            _before.positionHoldPoolAmount[i] = positions[i].position.holdPoolAmount;
            _before.positionRealizedPnl[i] = positions[i].position.realizedPnl;
            _before.positionLastUpdateTime[i] = positions[i].position.lastUpdateTime;
            _before.positionCloseFeeInUsd[i] = positions[i].position.positionFee.closeFeeInUsd;
            _before.positionOpenBorrowingFeePerToken[i] = positions[i].position.positionFee.openBorrowingFeePerToken;
            _before.positionRealizedBorrowingFee[i] = positions[i].position.positionFee.realizedBorrowingFee;
            _before.positionRealizedBorrowingFeeInUsd[i] = positions[i].position.positionFee.realizedBorrowingFeeInUsd;
            _before.positionOpenFundingFeePerQty[i] = positions[i].position.positionFee.openFundingFeePerQty;
            _before.positionRealizedFundingFee[i] = positions[i].position.positionFee.realizedFundingFee;
            _before.positionRealizedFundingFeeInUsd[i] = positions[i].position.positionFee.realizedFundingFeeInUsd;
        }

        ///////// StakingAccountFacet Computations /////////

        if(_stakeToken != address(0) || _collateralToken != address(0)) {
            hevm.prank(_user);
            _before.stakingAccountFacet_getAccountPoolCollateralAmount = diamondStakingAccountFacet.getAccountPoolCollateralAmount(_user, _stakeToken, _collateralToken);
            hevm.prank(_user);
            _before.stakingAccountFacet_getAccountUsdPoolAmount = diamondStakingAccountFacet.getAccountUsdPoolAmount(_user);

            hevm.prank(_user);
            IStakingAccount.TokenBalance memory accountPoolBalance = diamondStakingAccountFacet.getAccountPoolBalance(_user, _stakeToken);
            _before.stakingAccount_AccountPoolBalance_stakeAmount = accountPoolBalance.stakeAmount;
            _before.stakingAccount_AccountPoolBalance_collateralTokens = accountPoolBalance.collateralTokens;
            _before.stakingAccount_AccountPoolBalance_collateralAmounts = accountPoolBalance.collateralAmounts;
            _before.stakingAccount_AccountPoolBalance_collateralStakeLiability = accountPoolBalance.collateralStakeLiability;
        }

        // struct BefterParamHelper{
        //     address feeToken
        // }
        
        ///////// FeeFacet Computations /////////
        address feeToken_;
        bytes32 symbol_;

        if(_stakeToken != address(0)) {

            if(_stakeToken == address(stakedTokens[0])){
                feeToken_ = address(weth);
                symbol_ = MarketConfig.getWethSymbol();
            }else if(_stakeToken == address(stakedTokens[1])){
                feeToken_ = address(wbtc);
                symbol_ = MarketConfig.getWbtcSymbol();
            }else{
                feeToken_ = address(usdc);
                symbol_ = "";
            }

            hevm.prank(_user);
            _before.feeFacet_getCumulativeRewardsPerStakeToken = diamondFeeFacet.getCumulativeRewardsPerStakeToken(_stakeToken);
            hevm.prank(_user);
            _before.feeFacet_getDaoTokenFee = diamondFeeFacet.getDaoTokenFee(_stakeToken, feeToken_);
            hevm.prank(_user);
            _before.feeFacet_getMarketTokenFee = diamondFeeFacet.getMarketTokenFee(symbol_, feeToken_);
            hevm.prank(_user);
            _before.feeFacet_getPoolTokenFee = diamondFeeFacet.getPoolTokenFee(_stakeToken, feeToken_);
            hevm.prank(_user);
            _before.feeFacet_getStakingTokenFee = diamondFeeFacet.getStakingTokenFee(_stakeToken, feeToken_);
            
            
            // feeFacet_getAccountUsdFeeReward deconstructed values
            hevm.prank(_user);
            IFee.AccountUsdFeeReward memory feeAccountUsdFeeReward = diamondFeeFacet.getAccountUsdFeeReward(_user);
            _before.accountUsdFeeReward_Account = feeAccountUsdFeeReward.account;
            _before.accountUsdFeeReward_StakeToken = feeAccountUsdFeeReward.stakeToken;
            _before.accountUsdFeeReward_Reward = feeAccountUsdFeeReward.reward;
            
            // feeFacet_getAccountFeeRewards deconstructed values
            hevm.prank(_user);
            IFee.AccountFeeRewards memory feeAccountFeeReward = diamondFeeFacet.getAccountFeeRewards(_user);
            _before.accountFeeRewards_Account = feeAccountFeeReward.account;
            _before.accountFeeRewards_StakeTokens = feeAccountFeeReward.stakeTokens;
            _before.accountFeeRewards_Tokens = feeAccountFeeReward.tokens;
            _before.accountFeeRewards_Rewards = feeAccountFeeReward.rewards;
        }


        ///////// PoolFacet Computations /////////
        if(_stakeToken != address(0)) {
            hevm.prank(_user);
            IPool.PoolInfo memory pool = diamondPoolFacet.getPool(_stakeToken);

            _before.pool_stakeToken = pool.stakeToken;
            _before.pool_stakeTokenName = pool.stakeTokenName;
            _before.pool_baseToken = pool.baseToken;
            _before.pool_symbol = pool.symbol;
            _before.pool_stableTokens = pool.stableTokens;
            _before.pool_poolValue = pool.poolValue;
            _before.pool_availableLiquidity = pool.availableLiquidity;
            _before.pool_poolPnl = pool.poolPnl;
            _before.pool_totalSupply = pool.totalSupply;
            _before.pool_apr = pool.apr;
            _before.pool_totalClaimedRewards = pool.totalClaimedRewards;

            // baseTokenBalance deconstructed values
            _before.pool_baseTokenBalance_amount = pool.baseTokenBalance.amount;
            _before.pool_baseTokenBalance_liability = pool.baseTokenBalance.liability;
            _before.pool_baseTokenBalance_holdAmount = pool.baseTokenBalance.holdAmount;
            _before.pool_baseTokenBalance_unsettledAmount = pool.baseTokenBalance.unsettledAmount;
            _before.pool_baseTokenBalance_lossAmount = pool.baseTokenBalance.lossAmount;
            _before.pool_baseTokenBalance_collateralTokens = pool.baseTokenBalance.collateralTokens;
            _before.pool_baseTokenBalance_collateralAmounts = pool.baseTokenBalance.collateralAmounts;

            for(uint256 i = 0; i < pool.stableTokenBalances.length; i++) {
                _before.pool_stableTokenBalances_amount[i] = pool.stableTokenBalances[i].amount;
                _before.pool_stableTokenBalances_liability[i] = pool.stableTokenBalances[i].liability;
                _before.pool_stableTokenBalances_holdAmount[i] = pool.stableTokenBalances[i].holdAmount;
                _before.pool_stableTokenBalances_unsettledAmount[i] = pool.stableTokenBalances[i].unsettledAmount;
                _before.pool_stableTokenBalances_lossAmount[i] = pool.stableTokenBalances[i].lossAmount;
                _before.pool_stableTokenBalances_collateralTokens[i] = pool.stableTokenBalances[i].collateralTokens;
                _before.pool_stableTokenBalances_collateralAmounts[i] = pool.stableTokenBalances[i].collateralAmounts;
            }

            // LpPool.BorrowingFee borrowingFee;
            _before.pool_borrowingFee_totalBorrowingFee = pool.borrowingFee.totalBorrowingFee;
            _before.pool_borrowingFee_totalRealizedBorrowingFee = pool.borrowingFee.totalRealizedBorrowingFee;
            _before.pool_borrowingFee_cumulativeBorrowingFeePerToken = pool.borrowingFee.cumulativeBorrowingFeePerToken;
            _before.pool_borrowingFee_lastUpdateTime = pool.borrowingFee.lastUpdateTime;


            /// poolFacet_getUsdPool deconstructed values
            hevm.prank(_user);
            IPool.UsdPoolInfo memory usdPool = diamondPoolFacet.getUsdPool();

            _before.usdPool_StableTokens = usdPool.stableTokens;
            _before.usdPool_StableTokenMaxWithdraws = usdPool.stableTokenMaxWithdraws;
            _before.usdPool_PoolValue = usdPool.poolValue;
            _before.usdPool_TotalSupply = usdPool.totalSupply;
            _before.usdPool_TokensAvailableLiquidity = usdPool.tokensAvailableLiquidity;
            _before.usdPool_Apr = usdPool.apr;
            _before.usdPool_TotalClaimedRewards = usdPool.totalClaimedRewards;

            // UsdPool.TokenBalance[] stableTokenBalances;
            for(uint256 i = 0; i < usdPool.stableTokenBalances.length; i++) {
                _before.usdPool_stableTokenBalances_amount[i] = usdPool.stableTokenBalances[i].amount;
                _before.usdPool_stableTokenBalances_holdAmount[i] = usdPool.stableTokenBalances[i].holdAmount;
                _before.usdPool_stableTokenBalances_unsettledAmount[i] = usdPool.stableTokenBalances[i].unsettledAmount;
            }

            // UsdPool.BorrowingFee[] borrowingFees;
            for(uint256 i = 0; i < usdPool.borrowingFees.length; i++) {
                _before.usdPool_BorrowingFee_totalBorrowingFee[i] = usdPool.borrowingFees[i].totalBorrowingFee;
                _before.usdPool_BorrowingFee_totalRealizedBorrowingFee[i] = usdPool.borrowingFees[i].totalRealizedBorrowingFee;
                _before.usdPool_BorrowingFee_cumulativeBorrowingFeePerToken[i] = usdPool.borrowingFees[i].cumulativeBorrowingFeePerToken;
                _before.usdPool_BorrowingFee_lastUpdateTime[i] = usdPool.borrowingFees[i].lastUpdateTime;
            }
        }


        ///////// MarketFacet Computations /////////

        // address marketFacet_getStakeUsdToken;
        hevm.prank(_user);
        _before.marketFacet_getStakeUsdToken = diamondMarketFacet.getStakeUsdToken();
        
        
        /// marketFacet_getTradeTokenInfo deconstructed values
        if (_token != address(0)) {
            hevm.prank(_user);
            IMarket.TradeTokenInfo memory tokenInfo = diamondMarketFacet.getTradeTokenInfo(_token);
            
            _before.market_TradeTokenInfo_TradeTokenCollateral = tokenInfo.tradeTokenCollateral;
            _before.market_TradeTokenInfo_TradeTokenLiability = tokenInfo.tradeTokenLiability;
        }
            
            
        if (_code.length > 0) {
            hevm.prank(_user);
            IMarket.MarketInfo memory marketInfo = diamondMarketFacet.getMarketInfo(_code, _oracles);

            _before.market_MarketInfo_LongPositionInterest = marketInfo.longPositionInterest;
            _before.market_MarketInfo_LongPositionEntryPrice = marketInfo.longPositionEntryPrice;
            _before.market_MarketInfo_TotalShortPositionInterest = marketInfo.totalShortPositionInterest;
            _before.market_MarketInfo_AvailableLiquidity = marketInfo.availableLiquidity;

            _before.market_MarketInfo_SymbolInfo_Code = marketInfo.symbolInfo.code;
            _before.market_MarketInfo_SymbolInfo_Status = marketInfo.symbolInfo.status;
            _before.market_MarketInfo_SymbolInfo_StakeToken = marketInfo.symbolInfo.stakeToken;
            _before.market_MarketInfo_SymbolInfo_IndexToken = marketInfo.symbolInfo.indexToken;
            _before.market_MarketInfo_SymbolInfo_BaseToken = marketInfo.symbolInfo.baseToken;
            _before.market_MarketInfo_SymbolInfo_BaseTokenName = marketInfo.symbolInfo.baseTokenName;

            _before.market_MarketInfo_FundingFee_longFundingFeePerQty = marketInfo.fundingFee.longFundingFeePerQty;
            _before.market_MarketInfo_FundingFee_shortFundingFeePerQty = marketInfo.fundingFee.shortFundingFeePerQty;
            _before.market_MarketInfo_FundingFee_totalLongFundingFee = marketInfo.fundingFee.totalLongFundingFee;
            _before.market_MarketInfo_FundingFee_totalShortFundingFee = marketInfo.fundingFee.totalShortFundingFee;
            _before.market_MarketInfo_FundingFee_longFundingFeeRate = marketInfo.fundingFee.longFundingFeeRate;
            _before.market_MarketInfo_FundingFee_shortFundingFeeRate = marketInfo.fundingFee.shortFundingFeeRate;
            _before.market_MarketInfo_FundingFee_lastUpdateTime = marketInfo.fundingFee.lastUpdateTime;

            for (uint256 i = 0; i < marketInfo.shortPositions.length; i++) {
                _before.market_MarketInfo_ShortPositions_openInterest[i] = marketInfo.shortPositions[i].openInterest;
                _before.market_MarketInfo_ShortPositions_entryPrice[i] = marketInfo.shortPositions[i].entryPrice;
            }

        }

        ///////// Custom Computations /////////
        
        /// PortfolioVault Balances
        hevm.prank(_user);
        _before.portfolioVaultRawEthBalance = diamondVaultFacet.getPortfolioVaultAddress().balance;
        hevm.prank(_user);
        _before.portfolioVaultWethBalance = weth.balanceOf(diamondVaultFacet.getPortfolioVaultAddress());
        hevm.prank(_user);
        _before.portfolioVaultUsdcBalance = usdc.balanceOf(diamondVaultFacet.getPortfolioVaultAddress());
        hevm.prank(_user);
        _before.portfolioVaultBtcBalance = wbtc.balanceOf(diamondVaultFacet.getPortfolioVaultAddress());

        /// TradeVault Balances
        hevm.prank(_user);
        _before.tradeVaultRawEthBalance = diamondVaultFacet.getTradeVaultAddress().balance;
        hevm.prank(_user);
        _before.tradeVaultWethBalance = weth.balanceOf(diamondVaultFacet.getTradeVaultAddress());
        hevm.prank(_user);
        _before.tradeVaultUsdcBalance = usdc.balanceOf(diamondVaultFacet.getTradeVaultAddress());
        hevm.prank(_user);
        _before.tradeVaultBtcBalance = wbtc.balanceOf(diamondVaultFacet.getTradeVaultAddress());

        /// LpVault Balances
        hevm.prank(_user);
        _before.lpVaultRawEthBalance = diamondVaultFacet.getLpVaultAddress().balance;
        hevm.prank(_user);
        _before.lpVaultWethBalance = weth.balanceOf(diamondVaultFacet.getLpVaultAddress());
        hevm.prank(_user);
        _before.lpVaultUsdcBalance = usdc.balanceOf(diamondVaultFacet.getLpVaultAddress());
        hevm.prank(_user);
        _before.lpVaultBtcBalance = wbtc.balanceOf(diamondVaultFacet.getLpVaultAddress());
    }

    function __after(address _user, OracleProcess.OracleParam[] memory _oracles, address _stakeToken, address _collateralToken, address _token, bytes32 _code) internal {
        _resetAfter();

        ///////// AccountFacet /////////
        hevm.prank(_user);
        IAccount.AccountInfo memory account = diamondAccountFacet.getAccountInfo(_user);
        _after.accountOwner = account.owner;
        // _after.accountTokenBalances = account.tokenBalances;
        for(uint256 i = 0; i < account.tokenBalances.length; i++) {
            _after.accountTokenBalancesAmount[i] = account.tokenBalances[i].amount;
            _after.accountTokenBalancesUsedAmount[i] = account.tokenBalances[i].usedAmount;
            _after.accountTokenBalancesInterest[i] = account.tokenBalances[i].interest;
            _after.accountTokenBalancesLiability[i] = account.tokenBalances[i].liability;
        }

        _after.accountTokens = account.tokens;
        _after.accountPositions = account.positions;
        _after.accountPortfolioNetValue = account.portfolioNetValue;
        _after.accountTotalUsedValue = account.totalUsedValue;
        _after.accountAvailableValue = account.availableValue;
        _after.accountOrderHoldInUsd = account.orderHoldInUsd;
        _after.accountCrossMMR = account.crossMMR;
        _after.accountCrossNetValue = account.crossNetValue;
        _after.accountTotalMM = account.totalMM;

        hevm.prank(_user);
        IAccount.AccountInfo memory accountWithOracles = diamondAccountFacet.getAccountInfoWithOracles(_user, _oracles);
        _after.accountOwnerWithOracles = accountWithOracles.owner;

        // _after.accountTokenBalancesWithOracles = accountWithOracles.tokenBalances;
        for(uint256 i = 0; i < accountWithOracles.tokenBalances.length; i++) {
            _after.accountTokenBalancesAmountWithOracles[i] = accountWithOracles.tokenBalances[i].amount;
            _after.accountTokenBalancesUsedAmountWithOracles[i] = accountWithOracles.tokenBalances[i].usedAmount;
            _after.accountTokenBalancesInterestWithOracles[i] = accountWithOracles.tokenBalances[i].interest;
            _after.accountTokenBalancesLiabilityWithOracles[i] = accountWithOracles.tokenBalances[i].liability;
        }

        _after.accountTokensWithOracles = accountWithOracles.tokens;
        _after.accountPositionsWithOracles = accountWithOracles.positions;
        _after.accountPortfolioNetValueWithOracles = accountWithOracles.portfolioNetValue;
        _after.accountTotalUsedValueWithOracles = accountWithOracles.totalUsedValue;
        _after.accountAvailableValueWithOracles = accountWithOracles.availableValue;
        _after.accountOrderHoldInUsdWithOracles = accountWithOracles.orderHoldInUsd;
        _after.accountCrossMMRWithOracles = accountWithOracles.crossMMR;
        _after.accountCrossNetValueWithOracles = accountWithOracles.crossNetValue;
        _after.accountTotalMMWithOracles = accountWithOracles.totalMM;

        ///////// OrderFacet /////////
        // _after.accountOrders = diamondOrderFacet.getAccountOrders(_user);
        hevm.prank(_user);
        IOrder.AccountOrder[] memory orders= diamondOrderFacet.getAccountOrders(_user);
        for(uint256 i = 0; i < orders.length; i++) {
            _after.orderId[i] = orders[i].orderId;
            _after.orderAccount[i] = orders[i].orderInfo.account;
            _after.symbol[i] = orders[i].orderInfo.symbol;
            _after.orderSide[i] = orders[i].orderInfo.orderSide;
            _after.posSide[i] = orders[i].orderInfo.posSide;
            _after.orderType[i] = orders[i].orderInfo.orderType;
            _after.stopType[i] = orders[i].orderInfo.stopType;
            _after.isCrossMargin[i] = orders[i].orderInfo.isCrossMargin;
            _after.isExecutionFeeFromTradeVault[i] = orders[i].orderInfo.isExecutionFeeFromTradeVault;
            _after.marginToken[i] = orders[i].orderInfo.marginToken;
            _after.qty[i] = orders[i].orderInfo.qty;
            _after.leverage[i] = orders[i].orderInfo.leverage;
            _after.orderMargin[i] = orders[i].orderInfo.orderMargin;
            _after.triggerPrice[i] = orders[i].orderInfo.triggerPrice;
            _after.acceptablePrice[i] = orders[i].orderInfo.acceptablePrice;
            _after.placeTime[i] = orders[i].orderInfo.placeTime;
            _after.executionFee[i] = orders[i].orderInfo.executionFee;
            _after.lastBlock[i] = orders[i].orderInfo.lastBlock;
            
        }

        ///////// PositionFacet /////////
        // _after.accountPositionsInfo = diamondPositionFacet.getAllPositions(_user);
        hevm.prank(_user);
        IPosition.PositionInfo[] memory positions = diamondPositionFacet.getAllPositions(_user);
        for (uint256 i = 0; i < positions.length; i++) {
            _after.positionLiquidationPrice[i] = positions[i].liquidationPrice;
            _after.positionCurrentTimestamp[i] = positions[i].currentTimestamp;

            _after.positionKey[i] = positions[i].position.key;
            _after.positionSymbol[i] = positions[i].position.symbol;
            _after.positionIsLong[i] = positions[i].position.isLong;
            _after.positionIsCrossMargin[i] = positions[i].position.isCrossMargin;
            _after.positionAccount[i] = positions[i].position.account;
            _after.positionMarginToken[i] = positions[i].position.marginToken;
            _after.positionIndexToken[i] = positions[i].position.indexToken;
            _after.positionQty[i] = positions[i].position.qty;
            _after.positionEntryPrice[i] = positions[i].position.entryPrice;
            _after.positionLeverage[i] = positions[i].position.leverage;
            _after.positionInitialMargin[i] = positions[i].position.initialMargin;
            _after.positionInitialMarginInUsd[i] = positions[i].position.initialMarginInUsd;
            _after.positionInitialMarginInUsdFromBalance[i] = positions[i].position.initialMarginInUsdFromBalance;
            _after.positionHoldPoolAmount[i] = positions[i].position.holdPoolAmount;
            _after.positionRealizedPnl[i] = positions[i].position.realizedPnl;
            _after.positionLastUpdateTime[i] = positions[i].position.lastUpdateTime;
            _after.positionCloseFeeInUsd[i] = positions[i].position.positionFee.closeFeeInUsd;
            _after.positionOpenBorrowingFeePerToken[i] = positions[i].position.positionFee.openBorrowingFeePerToken;
            _after.positionRealizedBorrowingFee[i] = positions[i].position.positionFee.realizedBorrowingFee;
            _after.positionRealizedBorrowingFeeInUsd[i] = positions[i].position.positionFee.realizedBorrowingFeeInUsd;
            _after.positionOpenFundingFeePerQty[i] = positions[i].position.positionFee.openFundingFeePerQty;
            _after.positionRealizedFundingFee[i] = positions[i].position.positionFee.realizedFundingFee;
            _after.positionRealizedFundingFeeInUsd[i] = positions[i].position.positionFee.realizedFundingFeeInUsd;
        }

        ///////// StakingAccountFacet Computations /////////

        if(_stakeToken != address(0) || _collateralToken != address(0)) {
            hevm.prank(_user);
            _after.stakingAccountFacet_getAccountPoolCollateralAmount = diamondStakingAccountFacet.getAccountPoolCollateralAmount(_user, _stakeToken, _collateralToken);
            hevm.prank(_user);
            _after.stakingAccountFacet_getAccountUsdPoolAmount = diamondStakingAccountFacet.getAccountUsdPoolAmount(_user);

            hevm.prank(_user);
            IStakingAccount.TokenBalance memory accountPoolBalance = diamondStakingAccountFacet.getAccountPoolBalance(_user, _stakeToken);
            _after.stakingAccount_AccountPoolBalance_stakeAmount = accountPoolBalance.stakeAmount;
            _after.stakingAccount_AccountPoolBalance_collateralTokens = accountPoolBalance.collateralTokens;
            _after.stakingAccount_AccountPoolBalance_collateralAmounts = accountPoolBalance.collateralAmounts;
            _after.stakingAccount_AccountPoolBalance_collateralStakeLiability = accountPoolBalance.collateralStakeLiability;
        }

        // struct BefterParamHelper{
        //     address feeToken
        // }
        
        ///////// FeeFacet Computations /////////
        address feeToken_;
        bytes32 symbol_;

        if(_stakeToken != address(0)) {

            if(_stakeToken == address(stakedTokens[0])){
                feeToken_ = address(weth);
                symbol_ = MarketConfig.getWethSymbol();
            }else if(_stakeToken == address(stakedTokens[1])){
                feeToken_ = address(wbtc);
                symbol_ = MarketConfig.getWbtcSymbol();
            }else{
                feeToken_ = address(usdc);
                symbol_ = "";
            }

            hevm.prank(_user);
            _after.feeFacet_getCumulativeRewardsPerStakeToken = diamondFeeFacet.getCumulativeRewardsPerStakeToken(_stakeToken);
            hevm.prank(_user);
            _after.feeFacet_getDaoTokenFee = diamondFeeFacet.getDaoTokenFee(_stakeToken, feeToken_);
            hevm.prank(_user);
            _after.feeFacet_getMarketTokenFee = diamondFeeFacet.getMarketTokenFee(symbol_, feeToken_);
            hevm.prank(_user);
            _after.feeFacet_getPoolTokenFee = diamondFeeFacet.getPoolTokenFee(_stakeToken, feeToken_);
            hevm.prank(_user);
            _after.feeFacet_getStakingTokenFee = diamondFeeFacet.getStakingTokenFee(_stakeToken, feeToken_);
            
            
            // feeFacet_getAccountUsdFeeReward deconstructed values
            hevm.prank(_user);
            IFee.AccountUsdFeeReward memory feeAccountUsdFeeReward = diamondFeeFacet.getAccountUsdFeeReward(_user);
            _after.accountUsdFeeReward_Account = feeAccountUsdFeeReward.account;
            _after.accountUsdFeeReward_StakeToken = feeAccountUsdFeeReward.stakeToken;
            _after.accountUsdFeeReward_Reward = feeAccountUsdFeeReward.reward;
            
            // feeFacet_getAccountFeeRewards deconstructed values
            hevm.prank(_user);
            IFee.AccountFeeRewards memory feeAccountFeeReward = diamondFeeFacet.getAccountFeeRewards(_user);
            _after.accountFeeRewards_Account = feeAccountFeeReward.account;
            _after.accountFeeRewards_StakeTokens = feeAccountFeeReward.stakeTokens;
            _after.accountFeeRewards_Tokens = feeAccountFeeReward.tokens;
            _after.accountFeeRewards_Rewards = feeAccountFeeReward.rewards;
        }


        ///////// PoolFacet Computations /////////
        if(_stakeToken != address(0)) {
            hevm.prank(_user);
            IPool.PoolInfo memory pool = diamondPoolFacet.getPool(_stakeToken);

            _after.pool_stakeToken = pool.stakeToken;
            _after.pool_stakeTokenName = pool.stakeTokenName;
            _after.pool_baseToken = pool.baseToken;
            _after.pool_symbol = pool.symbol;
            _after.pool_stableTokens = pool.stableTokens;
            _after.pool_poolValue = pool.poolValue;
            _after.pool_availableLiquidity = pool.availableLiquidity;
            _after.pool_poolPnl = pool.poolPnl;
            _after.pool_totalSupply = pool.totalSupply;
            _after.pool_apr = pool.apr;
            _after.pool_totalClaimedRewards = pool.totalClaimedRewards;

            // baseTokenBalance deconstructed values
            _after.pool_baseTokenBalance_amount = pool.baseTokenBalance.amount;
            _after.pool_baseTokenBalance_liability = pool.baseTokenBalance.liability;
            _after.pool_baseTokenBalance_holdAmount = pool.baseTokenBalance.holdAmount;
            _after.pool_baseTokenBalance_unsettledAmount = pool.baseTokenBalance.unsettledAmount;
            _after.pool_baseTokenBalance_lossAmount = pool.baseTokenBalance.lossAmount;
            _after.pool_baseTokenBalance_collateralTokens = pool.baseTokenBalance.collateralTokens;
            _after.pool_baseTokenBalance_collateralAmounts = pool.baseTokenBalance.collateralAmounts;

            for(uint256 i = 0; i < pool.stableTokenBalances.length; i++) {
                _after.pool_stableTokenBalances_amount[i] = pool.stableTokenBalances[i].amount;
                _after.pool_stableTokenBalances_liability[i] = pool.stableTokenBalances[i].liability;
                _after.pool_stableTokenBalances_holdAmount[i] = pool.stableTokenBalances[i].holdAmount;
                _after.pool_stableTokenBalances_unsettledAmount[i] = pool.stableTokenBalances[i].unsettledAmount;
                _after.pool_stableTokenBalances_lossAmount[i] = pool.stableTokenBalances[i].lossAmount;
                _after.pool_stableTokenBalances_collateralTokens[i] = pool.stableTokenBalances[i].collateralTokens;
                _after.pool_stableTokenBalances_collateralAmounts[i] = pool.stableTokenBalances[i].collateralAmounts;
            }

            // LpPool.BorrowingFee borrowingFee;
            _after.pool_borrowingFee_totalBorrowingFee = pool.borrowingFee.totalBorrowingFee;
            _after.pool_borrowingFee_totalRealizedBorrowingFee = pool.borrowingFee.totalRealizedBorrowingFee;
            _after.pool_borrowingFee_cumulativeBorrowingFeePerToken = pool.borrowingFee.cumulativeBorrowingFeePerToken;
            _after.pool_borrowingFee_lastUpdateTime = pool.borrowingFee.lastUpdateTime;


            /// poolFacet_getUsdPool deconstructed values
            hevm.prank(_user);
            IPool.UsdPoolInfo memory usdPool = diamondPoolFacet.getUsdPool();

            _after.usdPool_StableTokens = usdPool.stableTokens;
            _after.usdPool_StableTokenMaxWithdraws = usdPool.stableTokenMaxWithdraws;
            _after.usdPool_PoolValue = usdPool.poolValue;
            _after.usdPool_TotalSupply = usdPool.totalSupply;
            _after.usdPool_TokensAvailableLiquidity = usdPool.tokensAvailableLiquidity;
            _after.usdPool_Apr = usdPool.apr;
            _after.usdPool_TotalClaimedRewards = usdPool.totalClaimedRewards;

            // UsdPool.TokenBalance[] stableTokenBalances;
            for(uint256 i = 0; i < usdPool.stableTokenBalances.length; i++) {
                _after.usdPool_stableTokenBalances_amount[i] = usdPool.stableTokenBalances[i].amount;
                _after.usdPool_stableTokenBalances_holdAmount[i] = usdPool.stableTokenBalances[i].holdAmount;
                _after.usdPool_stableTokenBalances_unsettledAmount[i] = usdPool.stableTokenBalances[i].unsettledAmount;
            }

            // UsdPool.BorrowingFee[] borrowingFees;
            for(uint256 i = 0; i < usdPool.borrowingFees.length; i++) {
                _after.usdPool_BorrowingFee_totalBorrowingFee[i] = usdPool.borrowingFees[i].totalBorrowingFee;
                _after.usdPool_BorrowingFee_totalRealizedBorrowingFee[i] = usdPool.borrowingFees[i].totalRealizedBorrowingFee;
                _after.usdPool_BorrowingFee_cumulativeBorrowingFeePerToken[i] = usdPool.borrowingFees[i].cumulativeBorrowingFeePerToken;
                _after.usdPool_BorrowingFee_lastUpdateTime[i] = usdPool.borrowingFees[i].lastUpdateTime;
            }
        }


        ///////// MarketFacet Computations /////////

        // address marketFacet_getStakeUsdToken;
        hevm.prank(_user);
        _after.marketFacet_getStakeUsdToken = diamondMarketFacet.getStakeUsdToken();
        
        
        /// marketFacet_getTradeTokenInfo deconstructed values
        if (_token != address(0)) {
            hevm.prank(_user);
            IMarket.TradeTokenInfo memory tokenInfo = diamondMarketFacet.getTradeTokenInfo(_token);
            
            _after.market_TradeTokenInfo_TradeTokenCollateral = tokenInfo.tradeTokenCollateral;
            _after.market_TradeTokenInfo_TradeTokenLiability = tokenInfo.tradeTokenLiability;
        }
            
            
        if (_code.length > 0) {
            hevm.prank(_user);
            IMarket.MarketInfo memory marketInfo = diamondMarketFacet.getMarketInfo(_code, _oracles);

            _after.market_MarketInfo_LongPositionInterest = marketInfo.longPositionInterest;
            _after.market_MarketInfo_LongPositionEntryPrice = marketInfo.longPositionEntryPrice;
            _after.market_MarketInfo_TotalShortPositionInterest = marketInfo.totalShortPositionInterest;
            _after.market_MarketInfo_AvailableLiquidity = marketInfo.availableLiquidity;

            _after.market_MarketInfo_SymbolInfo_Code = marketInfo.symbolInfo.code;
            _after.market_MarketInfo_SymbolInfo_Status = marketInfo.symbolInfo.status;
            _after.market_MarketInfo_SymbolInfo_StakeToken = marketInfo.symbolInfo.stakeToken;
            _after.market_MarketInfo_SymbolInfo_IndexToken = marketInfo.symbolInfo.indexToken;
            _after.market_MarketInfo_SymbolInfo_BaseToken = marketInfo.symbolInfo.baseToken;
            _after.market_MarketInfo_SymbolInfo_BaseTokenName = marketInfo.symbolInfo.baseTokenName;

            _after.market_MarketInfo_FundingFee_longFundingFeePerQty = marketInfo.fundingFee.longFundingFeePerQty;
            _after.market_MarketInfo_FundingFee_shortFundingFeePerQty = marketInfo.fundingFee.shortFundingFeePerQty;
            _after.market_MarketInfo_FundingFee_totalLongFundingFee = marketInfo.fundingFee.totalLongFundingFee;
            _after.market_MarketInfo_FundingFee_totalShortFundingFee = marketInfo.fundingFee.totalShortFundingFee;
            _after.market_MarketInfo_FundingFee_longFundingFeeRate = marketInfo.fundingFee.longFundingFeeRate;
            _after.market_MarketInfo_FundingFee_shortFundingFeeRate = marketInfo.fundingFee.shortFundingFeeRate;
            _after.market_MarketInfo_FundingFee_lastUpdateTime = marketInfo.fundingFee.lastUpdateTime;

            for (uint256 i = 0; i < marketInfo.shortPositions.length; i++) {
                _after.market_MarketInfo_ShortPositions_openInterest[i] = marketInfo.shortPositions[i].openInterest;
                _after.market_MarketInfo_ShortPositions_entryPrice[i] = marketInfo.shortPositions[i].entryPrice;
            }

        }

        ///////// Custom Computations /////////
        
        /// PortfolioVault Balances
        hevm.prank(_user);
        _after.portfolioVaultRawEthBalance = diamondVaultFacet.getPortfolioVaultAddress().balance;
        hevm.prank(_user);
        _after.portfolioVaultWethBalance = weth.balanceOf(diamondVaultFacet.getPortfolioVaultAddress());
        hevm.prank(_user);
        _after.portfolioVaultUsdcBalance = usdc.balanceOf(diamondVaultFacet.getPortfolioVaultAddress());
        hevm.prank(_user);
        _after.portfolioVaultBtcBalance = wbtc.balanceOf(diamondVaultFacet.getPortfolioVaultAddress());

        /// TradeVault Balances
        hevm.prank(_user);
        _after.tradeVaultRawEthBalance = diamondVaultFacet.getTradeVaultAddress().balance;
        hevm.prank(_user);
        _after.tradeVaultWethBalance = weth.balanceOf(diamondVaultFacet.getTradeVaultAddress());
        hevm.prank(_user);
        _after.tradeVaultUsdcBalance = usdc.balanceOf(diamondVaultFacet.getTradeVaultAddress());
        hevm.prank(_user);
        _after.tradeVaultBtcBalance = wbtc.balanceOf(diamondVaultFacet.getTradeVaultAddress());

        /// LpVault Balances
        hevm.prank(_user);
        _after.lpVaultRawEthBalance = diamondVaultFacet.getLpVaultAddress().balance;
        hevm.prank(_user);
        _after.lpVaultWethBalance = weth.balanceOf(diamondVaultFacet.getLpVaultAddress());
        hevm.prank(_user);
        _after.lpVaultUsdcBalance = usdc.balanceOf(diamondVaultFacet.getLpVaultAddress());
        hevm.prank(_user);
        _after.lpVaultBtcBalance = wbtc.balanceOf(diamondVaultFacet.getLpVaultAddress());
    }

    function _resetBefore() internal {
        ///////// AccountFacet /////////
        _before.accountOwner = address(0);
        delete _before.accountTokens;
        delete _before.accountPositions;
        _before.accountPortfolioNetValue = 0;
        _before.accountTotalUsedValue = 0;
        _before.accountAvailableValue = 0;
        _before.accountOrderHoldInUsd = 0;
        _before.accountCrossMMR = 0;
        _before.accountCrossNetValue = 0;
        _before.accountTotalMM = 0;

        /// Account.TokenBalance[] deconstructed values
        delete _before.accountTokenBalancesAmount;
        delete _before.accountTokenBalancesUsedAmount;
        delete _before.accountTokenBalancesInterest;
        delete _before.accountTokenBalancesLiability;
        
        /// getAccountInfoWithOracles deconstructed values
        _before.accountOwnerWithOracles = address(0);
        delete _before.accountTokensWithOracles;
        delete _before.accountPositionsWithOracles;
        _before.accountPortfolioNetValueWithOracles = 0;
        _before.accountTotalUsedValueWithOracles = 0;
        _before.accountAvailableValueWithOracles = 0;
        _before.accountOrderHoldInUsdWithOracles = 0;
        _before.accountCrossMMRWithOracles = 0;
        _before.accountCrossNetValueWithOracles = 0;
        _before.accountTotalMMWithOracles = 0;

        /// Account.TokenBalance[] deconstructed values
        delete _before.accountTokenBalancesAmountWithOracles;
        delete _before.accountTokenBalancesUsedAmountWithOracles;
        delete _before.accountTokenBalancesInterestWithOracles;
        delete _before.accountTokenBalancesLiabilityWithOracles;

        ///////// OrderFacet /////////
        delete _before.orderId;
        delete _before.orderAccount;
        delete _before.symbol;
        delete _before.orderSide;
        delete _before.posSide;
        delete _before.orderType;
        delete _before.stopType;
        delete _before.isCrossMargin;
        delete _before.isExecutionFeeFromTradeVault;
        delete _before.marginToken;
        delete _before.qty;
        delete _before.leverage;
        delete _before.orderMargin;
        delete _before.triggerPrice;
        delete _before.acceptablePrice;
        delete _before.placeTime;
        delete _before.executionFee;
        delete _before.lastBlock;

        ///////// PositionFacet /////////
        delete _before.positionLiquidationPrice;
        delete _before.positionCurrentTimestamp;
        delete _before.positionKey;
        delete _before.positionSymbol;
        delete _before.positionIsLong;
        delete _before.positionIsCrossMargin;
        delete _before.positionAccount;
        delete _before.positionMarginToken;
        delete _before.positionIndexToken;
        delete _before.positionQty;
        delete _before.positionEntryPrice;
        delete _before.positionLeverage;
        delete _before.positionInitialMargin;
        delete _before.positionInitialMarginInUsd;
        delete _before.positionInitialMarginInUsdFromBalance;
        delete _before.positionHoldPoolAmount;
        delete _before.positionRealizedPnl;
        delete _before.positionLastUpdateTime;
        delete _before.positionCloseFeeInUsd;
        delete _before.positionOpenBorrowingFeePerToken;
        delete _before.positionRealizedBorrowingFee;
        delete _before.positionRealizedBorrowingFeeInUsd;
        delete _before.positionOpenFundingFeePerQty;
        delete _before.positionRealizedFundingFee;
        delete _before.positionRealizedFundingFeeInUsd;

        ///////// StakingAccountFacet Computations /////////
        // _before.stakingAccountPoolCollateralAmount = 0;
        // _before.stakingAccountUsdPoolAmount = 0;
        
        // stakingAccountFacet_getAccountPoolBalance deconstructed values
        // _before.stakingAccountUsdPoolCollateralAmount = 0;
        delete _before.stakingAccount_AccountPoolBalance_collateralTokens;
        delete _before.stakingAccount_AccountPoolBalance_collateralAmounts;
        delete _before.stakingAccount_AccountPoolBalance_collateralStakeLiability;


        ///////// FeeFacet Computations /////////
        _before.feeFacet_getCumulativeRewardsPerStakeToken = 0;
        _before.feeFacet_getDaoTokenFee = 0;
        _before.feeFacet_getMarketTokenFee = 0;
        _before.feeFacet_getPoolTokenFee = 0;
        _before.feeFacet_getStakingTokenFee = 0;
        
        // feeFacet_getAccountUsdFeeReward deconstructed values
        _before.accountUsdFeeReward_Account = address(0);
        _before.accountUsdFeeReward_StakeToken = address(0);
        _before.accountUsdFeeReward_Reward = 0;
        
        // tuple feeFacet_getAccountFeeRewards;
        _before.accountFeeRewards_Account = address(0);
        delete _before.accountFeeRewards_StakeTokens;
        delete _before.accountFeeRewards_Tokens;
        delete _before.accountFeeRewards_Rewards;


        // ///////// PoolFacet Computations /////////
        _before.pool_stakeToken = address(0);
        _before.pool_stakeTokenName = "";
        _before.pool_baseToken = address(0);
        _before.pool_symbol = "";
        delete _before.pool_stableTokens;
        _before.pool_poolValue = 0;
        _before.pool_availableLiquidity = 0;
        _before.pool_poolPnl = 0;
        _before.pool_totalSupply = 0;
        _before.pool_apr = 0;
        _before.pool_totalClaimedRewards = 0;
        
        _before.pool_baseTokenBalance_amount = 0;
        _before.pool_baseTokenBalance_liability = 0;
        _before.pool_baseTokenBalance_holdAmount = 0;
        _before.pool_baseTokenBalance_unsettledAmount = 0;
        _before.pool_baseTokenBalance_lossAmount = 0;
        delete _before.pool_baseTokenBalance_collateralTokens;
        delete _before.pool_baseTokenBalance_collateralAmounts;

        delete _before.pool_stableTokenBalances_amount;
        delete _before.pool_stableTokenBalances_liability;
        delete _before.pool_stableTokenBalances_holdAmount;
        delete _before.pool_stableTokenBalances_unsettledAmount;
        delete _before.pool_stableTokenBalances_lossAmount;
        delete _before.pool_stableTokenBalances_collateralTokens;
        delete _before.pool_stableTokenBalances_collateralAmounts;

        _before.pool_borrowingFee_totalBorrowingFee = 0;
        _before.pool_borrowingFee_totalRealizedBorrowingFee = 0;
        _before.pool_borrowingFee_cumulativeBorrowingFeePerToken = 0;
        _before.pool_borrowingFee_lastUpdateTime = 0;

        delete _before.usdPool_StableTokens;
        delete _before.usdPool_StableTokenMaxWithdraws;
        delete _before.usdPool_TokensAvailableLiquidity;
        _before.usdPool_PoolValue = 0;
        _before.usdPool_TotalSupply = 0;
        _before.usdPool_Apr = 0;
        _before.usdPool_TotalClaimedRewards = 0;

        delete _before.usdPool_stableTokenBalances_amount;
        delete _before.usdPool_stableTokenBalances_holdAmount;
        delete _before.usdPool_stableTokenBalances_unsettledAmount;
        delete _before.usdPool_BorrowingFee_totalBorrowingFee;
        delete _before.usdPool_BorrowingFee_totalRealizedBorrowingFee;
        delete _before.usdPool_BorrowingFee_cumulativeBorrowingFeePerToken;
        delete _before.usdPool_BorrowingFee_lastUpdateTime;

        ///////// MarketFacet Computations /////////
        _before.marketFacet_getStakeUsdToken = address(0);

        _before.market_TradeTokenInfo_TradeTokenCollateral = 0;
        _before.market_TradeTokenInfo_TradeTokenLiability = 0;

        _before.market_MarketInfo_LongPositionInterest = 0;
        _before.market_MarketInfo_LongPositionEntryPrice = 0;
        _before.market_MarketInfo_TotalShortPositionInterest = 0;
        _before.market_MarketInfo_AvailableLiquidity = 0;
        _before.market_MarketInfo_SymbolInfo_Code = bytes32(0);
        // _before.market_MarketInfo_SymbolInfo_Status = uint8(0);
        _before.market_MarketInfo_SymbolInfo_StakeToken = address(0);
        _before.market_MarketInfo_SymbolInfo_IndexToken = address(0);
        _before.market_MarketInfo_SymbolInfo_BaseToken = address(0);
        _before.market_MarketInfo_SymbolInfo_BaseTokenName = "";

        delete _before.market_MarketInfo_ShortPositions_openInterest;
        delete _before.market_MarketInfo_ShortPositions_entryPrice;

        _before.market_MarketInfo_FundingFee_longFundingFeePerQty = 0;
        _before.market_MarketInfo_FundingFee_shortFundingFeePerQty = 0;
        _before.market_MarketInfo_FundingFee_totalLongFundingFee = 0;
        _before.market_MarketInfo_FundingFee_totalShortFundingFee = 0;
        _before.market_MarketInfo_FundingFee_longFundingFeeRate = 0;
        _before.market_MarketInfo_FundingFee_shortFundingFeeRate = 0;
        _before.market_MarketInfo_FundingFee_lastUpdateTime = 0;


        ///////// Custom Computations /////////
        _before.portfolioVaultRawEthBalance = 0;
        _before.portfolioVaultWethBalance = 0;
        _before.portfolioVaultUsdcBalance = 0;
        _before.portfolioVaultBtcBalance = 0;

        _before.tradeVaultRawEthBalance = 0;
        _before.tradeVaultWethBalance = 0;
        _before.tradeVaultUsdcBalance = 0;
        _before.tradeVaultBtcBalance = 0;

        _before.lpVaultRawEthBalance = 0;
        _before.lpVaultWethBalance = 0;
        _before.lpVaultUsdcBalance = 0;
        _before.lpVaultBtcBalance = 0;
    }


    function _resetAfter() internal {
        ///////// AccountFacet /////////
        _after.accountOwner = address(0);
        delete _after.accountTokens;
        delete _after.accountPositions;
        _after.accountPortfolioNetValue = 0;
        _after.accountTotalUsedValue = 0;
        _after.accountAvailableValue = 0;
        _after.accountOrderHoldInUsd = 0;
        _after.accountCrossMMR = 0;
        _after.accountCrossNetValue = 0;
        _after.accountTotalMM = 0;

        /// Account.TokenBalance[] deconstructed values
        delete _after.accountTokenBalancesAmount;
        delete _after.accountTokenBalancesUsedAmount;
        delete _after.accountTokenBalancesInterest;
        delete _after.accountTokenBalancesLiability;
        
        /// getAccountInfoWithOracles deconstructed values
        _after.accountOwnerWithOracles = address(0);
        delete _after.accountTokensWithOracles;
        delete _after.accountPositionsWithOracles;
        _after.accountPortfolioNetValueWithOracles = 0;
        _after.accountTotalUsedValueWithOracles = 0;
        _after.accountAvailableValueWithOracles = 0;
        _after.accountOrderHoldInUsdWithOracles = 0;
        _after.accountCrossMMRWithOracles = 0;
        _after.accountCrossNetValueWithOracles = 0;
        _after.accountTotalMMWithOracles = 0;

        /// Account.TokenBalance[] deconstructed values
        delete _after.accountTokenBalancesAmountWithOracles;
        delete _after.accountTokenBalancesUsedAmountWithOracles;
        delete _after.accountTokenBalancesInterestWithOracles;
        delete _after.accountTokenBalancesLiabilityWithOracles;

        ///////// OrderFacet /////////
        delete _after.orderId;
        delete _after.orderAccount;
        delete _after.symbol;
        delete _after.orderSide;
        delete _after.posSide;
        delete _after.orderType;
        delete _after.stopType;
        delete _after.isCrossMargin;
        delete _after.isExecutionFeeFromTradeVault;
        delete _after.marginToken;
        delete _after.qty;
        delete _after.leverage;
        delete _after.orderMargin;
        delete _after.triggerPrice;
        delete _after.acceptablePrice;
        delete _after.placeTime;
        delete _after.executionFee;
        delete _after.lastBlock;

        ///////// PositionFacet /////////
        delete _after.positionLiquidationPrice;
        delete _after.positionCurrentTimestamp;
        delete _after.positionKey;
        delete _after.positionSymbol;
        delete _after.positionIsLong;
        delete _after.positionIsCrossMargin;
        delete _after.positionAccount;
        delete _after.positionMarginToken;
        delete _after.positionIndexToken;
        delete _after.positionQty;
        delete _after.positionEntryPrice;
        delete _after.positionLeverage;
        delete _after.positionInitialMargin;
        delete _after.positionInitialMarginInUsd;
        delete _after.positionInitialMarginInUsdFromBalance;
        delete _after.positionHoldPoolAmount;
        delete _after.positionRealizedPnl;
        delete _after.positionLastUpdateTime;
        delete _after.positionCloseFeeInUsd;
        delete _after.positionOpenBorrowingFeePerToken;
        delete _after.positionRealizedBorrowingFee;
        delete _after.positionRealizedBorrowingFeeInUsd;
        delete _after.positionOpenFundingFeePerQty;
        delete _after.positionRealizedFundingFee;
        delete _after.positionRealizedFundingFeeInUsd;

        ///////// StakingAccountFacet Computations /////////
        // _after.stakingAccountPoolCollateralAmount = 0;
        // _after.stakingAccountUsdPoolAmount = 0;
        
        // stakingAccountFacet_getAccountPoolBalance deconstructed values
        // _after.stakingAccountUsdPoolCollateralAmount = 0;
        delete _after.stakingAccount_AccountPoolBalance_collateralTokens;
        delete _after.stakingAccount_AccountPoolBalance_collateralAmounts;
        delete _after.stakingAccount_AccountPoolBalance_collateralStakeLiability;


        ///////// FeeFacet Computations /////////
        _after.feeFacet_getCumulativeRewardsPerStakeToken = 0;
        _after.feeFacet_getDaoTokenFee = 0;
        _after.feeFacet_getMarketTokenFee = 0;
        _after.feeFacet_getPoolTokenFee = 0;
        _after.feeFacet_getStakingTokenFee = 0;
        
        // feeFacet_getAccountUsdFeeReward deconstructed values
        _after.accountUsdFeeReward_Account = address(0);
        _after.accountUsdFeeReward_StakeToken = address(0);
        _after.accountUsdFeeReward_Reward = 0;
        
        // tuple feeFacet_getAccountFeeRewards;
        _after.accountFeeRewards_Account = address(0);
        delete _after.accountFeeRewards_StakeTokens;
        delete _after.accountFeeRewards_Tokens;
        delete _after.accountFeeRewards_Rewards;


        // ///////// PoolFacet Computations /////////
        _after.pool_stakeToken = address(0);
        _after.pool_stakeTokenName = "";
        _after.pool_baseToken = address(0);
        _after.pool_symbol = "";
        delete _after.pool_stableTokens;
        _after.pool_poolValue = 0;
        _after.pool_availableLiquidity = 0;
        _after.pool_poolPnl = 0;
        _after.pool_totalSupply = 0;
        _after.pool_apr = 0;
        _after.pool_totalClaimedRewards = 0;
        
        _after.pool_baseTokenBalance_amount = 0;
        _after.pool_baseTokenBalance_liability = 0;
        _after.pool_baseTokenBalance_holdAmount = 0;
        _after.pool_baseTokenBalance_unsettledAmount = 0;
        _after.pool_baseTokenBalance_lossAmount = 0;
        delete _after.pool_baseTokenBalance_collateralTokens;
        delete _after.pool_baseTokenBalance_collateralAmounts;

        delete _after.pool_stableTokenBalances_amount;
        delete _after.pool_stableTokenBalances_liability;
        delete _after.pool_stableTokenBalances_holdAmount;
        delete _after.pool_stableTokenBalances_unsettledAmount;
        delete _after.pool_stableTokenBalances_lossAmount;
        delete _after.pool_stableTokenBalances_collateralTokens;
        delete _after.pool_stableTokenBalances_collateralAmounts;

        _after.pool_borrowingFee_totalBorrowingFee = 0;
        _after.pool_borrowingFee_totalRealizedBorrowingFee = 0;
        _after.pool_borrowingFee_cumulativeBorrowingFeePerToken = 0;
        _after.pool_borrowingFee_lastUpdateTime = 0;

        delete _after.usdPool_StableTokens;
        delete _after.usdPool_StableTokenMaxWithdraws;
        delete _after.usdPool_TokensAvailableLiquidity;
        _after.usdPool_PoolValue = 0;
        _after.usdPool_TotalSupply = 0;
        _after.usdPool_Apr = 0;
        _after.usdPool_TotalClaimedRewards = 0;

        delete _after.usdPool_stableTokenBalances_amount;
        delete _after.usdPool_stableTokenBalances_holdAmount;
        delete _after.usdPool_stableTokenBalances_unsettledAmount;
        delete _after.usdPool_BorrowingFee_totalBorrowingFee;
        delete _after.usdPool_BorrowingFee_totalRealizedBorrowingFee;
        delete _after.usdPool_BorrowingFee_cumulativeBorrowingFeePerToken;
        delete _after.usdPool_BorrowingFee_lastUpdateTime;

        ///////// MarketFacet Computations /////////
        _after.marketFacet_getStakeUsdToken = address(0);

        _after.market_TradeTokenInfo_TradeTokenCollateral = 0;
        _after.market_TradeTokenInfo_TradeTokenLiability = 0;

        _after.market_MarketInfo_LongPositionInterest = 0;
        _after.market_MarketInfo_LongPositionEntryPrice = 0;
        _after.market_MarketInfo_TotalShortPositionInterest = 0;
        _after.market_MarketInfo_AvailableLiquidity = 0;
        _after.market_MarketInfo_SymbolInfo_Code = bytes32(0);
        // _after.market_MarketInfo_SymbolInfo_Status = uint8(0);
        _after.market_MarketInfo_SymbolInfo_StakeToken = address(0);
        _after.market_MarketInfo_SymbolInfo_IndexToken = address(0);
        _after.market_MarketInfo_SymbolInfo_BaseToken = address(0);
        _after.market_MarketInfo_SymbolInfo_BaseTokenName = "";

        delete _after.market_MarketInfo_ShortPositions_openInterest;
        delete _after.market_MarketInfo_ShortPositions_entryPrice;

        _after.market_MarketInfo_FundingFee_longFundingFeePerQty = 0;
        _after.market_MarketInfo_FundingFee_shortFundingFeePerQty = 0;
        _after.market_MarketInfo_FundingFee_totalLongFundingFee = 0;
        _after.market_MarketInfo_FundingFee_totalShortFundingFee = 0;
        _after.market_MarketInfo_FundingFee_longFundingFeeRate = 0;
        _after.market_MarketInfo_FundingFee_shortFundingFeeRate = 0;
        _after.market_MarketInfo_FundingFee_lastUpdateTime = 0;


        ///////// Custom Computations /////////
        _after.portfolioVaultRawEthBalance = 0;
        _after.portfolioVaultWethBalance = 0;
        _after.portfolioVaultUsdcBalance = 0;
        _after.portfolioVaultBtcBalance = 0;

        _after.tradeVaultRawEthBalance = 0;
        _after.tradeVaultWethBalance = 0;
        _after.tradeVaultUsdcBalance = 0;
        _after.tradeVaultBtcBalance = 0;

        _after.lpVaultRawEthBalance = 0;
        _after.lpVaultWethBalance = 0;
        _after.lpVaultUsdcBalance = 0;
        _after.lpVaultBtcBalance = 0;
    }
}
