
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Setup} from "./Setup.sol";

import "src/interfaces/IOrder.sol"; 
import "src/storage/Order.sol";
import "src/storage/Account.sol"; 
import "src/interfaces/IPosition.sol"; 
import "src/interfaces/IAccount.sol"; 


abstract contract BeforeAfter is Setup {

    struct Vars {

        ///////// AccountFacet /////////
        /// getAccountInfo deconstructed values
        address accountOwner;
        Account.TokenBalance[] accountTokenBalances;
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
        Account.TokenBalance[] accountTokenBalancesWithOracles;
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
        uint256[] PositionCloseFeeInUsd;
        uint256[] positionOpenBorrowingFeePerToken;
        uint256[] positionRealizedBorrowingFee;
        uint256[] positionRealizedBorrowingFeeInUsd;
        int256[] positionOpenFundingFeePerQty;
        int256[] positionRealizedFundingFee;
        int256[] positionRealizedFundingFeeInUsd;

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


    function __before(address _user, OracleProcess.OracleParam[] memory _oracles) internal {
        ///////// AccountFacet /////////
        IAccount.AccountInfo memory account = diamondAccountFacet.getAccountInfo(_user);
        _before.accountOwner = account.owner;
        // _before.accountTokenBalances = account.tokenBalances;
        for(uint256 i = 0; i < account.tokenBalances.length; i++) {
            _before.accountTokenBalancesAmount.push(account.tokenBalances[i].amount);
            _before.accountTokenBalancesUsedAmount.push(account.tokenBalances[i].usedAmount);
            _before.accountTokenBalancesInterest.push(account.tokenBalances[i].interest);
            _before.accountTokenBalancesLiability.push(account.tokenBalances[i].liability);
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

        IAccount.AccountInfo memory accountWithOracles = diamondAccountFacet.getAccountInfoWithOracles(_user, _oracles);
        _before.accountOwnerWithOracles = accountWithOracles.owner;

        // _before.accountTokenBalancesWithOracles = accountWithOracles.tokenBalances;
        for(uint256 i = 0; i < account.tokenBalances.length; i++) {
            _before.accountTokenBalancesAmountWithOracles.push(account.tokenBalances[i].amount);
            _before.accountTokenBalancesUsedAmountWithOracles.push(account.tokenBalances[i].usedAmount);
            _before.accountTokenBalancesInterestWithOracles.push(account.tokenBalances[i].interest);
            _before.accountTokenBalancesLiabilityWithOracles.push(account.tokenBalances[i].liability);
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
        IOrder.AccountOrder[] memory orders= diamondOrderFacet.getAccountOrders(_user);
        for(uint256 i = 0; i < orders.length; i++) {
            _before.orderId.push(orders[i].orderId);
            _before.symbol.push(orders[i].orderInfo.symbol);
            _before.orderSide.push(orders[i].orderInfo.orderSide);
            _before.posSide.push(orders[i].orderInfo.posSide);
            _before.orderType.push(orders[i].orderInfo.orderType);
            _before.stopType.push(orders[i].orderInfo.stopType);
            _before.isCrossMargin.push(orders[i].orderInfo.isCrossMargin);
            _before.isExecutionFeeFromTradeVault.push(orders[i].orderInfo.isExecutionFeeFromTradeVault);
            _before.marginToken.push(orders[i].orderInfo.marginToken);
            _before.qty.push(orders[i].orderInfo.qty);
            _before.leverage.push(orders[i].orderInfo.leverage);
            _before.orderMargin.push(orders[i].orderInfo.orderMargin);
            _before.triggerPrice.push(orders[i].orderInfo.triggerPrice);
            _before.acceptablePrice.push(orders[i].orderInfo.acceptablePrice);
            _before.placeTime.push(orders[i].orderInfo.placeTime);
            _before.executionFee.push(orders[i].orderInfo.executionFee);
            _before.lastBlock.push(orders[i].orderInfo.lastBlock);
        }

        ///////// PositionFacet /////////
        // _before.accountPositionsInfo = diamondPositionFacet.getAllPositions(_user);
        
        IPosition.PositionInfo[] memory positions = diamondPositionFacet.getAllPositions(_user);
        for (uint256 i = 0; i < positions.length; i++) {
            _before.positionLiquidationPrice.push(positions[i].liquidationPrice);
            _before.positionCurrentTimestamp.push(positions[i].currentTimestamp);

            _before.positionKey.push(positions[i].position.key);
            _before.positionSymbol.push(positions[i].position.symbol);
            _before.positionIsLong.push(positions[i].position.isLong);
            _before.positionIsCrossMargin.push(positions[i].position.isCrossMargin);
            _before.positionAccount.push(positions[i].position.account);
            _before.positionMarginToken.push(positions[i].position.marginToken);
            _before.positionIndexToken.push(positions[i].position.indexToken);
            _before.positionQty.push(positions[i].position.qty);
            _before.positionEntryPrice.push(positions[i].position.entryPrice);
            _before.positionLeverage.push(positions[i].position.leverage);
            _before.positionInitialMargin.push(positions[i].position.initialMargin);
            _before.positionInitialMarginInUsd.push(positions[i].position.initialMarginInUsd);
            _before.positionInitialMarginInUsdFromBalance.push(positions[i].position.initialMarginInUsdFromBalance);
            _before.positionHoldPoolAmount.push(positions[i].position.holdPoolAmount);
            _before.positionRealizedPnl.push(positions[i].position.realizedPnl);
            _before.positionLastUpdateTime.push(positions[i].position.lastUpdateTime);

            _before.PositionCloseFeeInUsd.push(positions[i].position.positionFee.closeFeeInUsd);
            _before.positionOpenBorrowingFeePerToken.push(positions[i].position.positionFee.openBorrowingFeePerToken);
            _before.positionRealizedBorrowingFee.push(positions[i].position.positionFee.realizedBorrowingFee);
            _before.positionRealizedBorrowingFeeInUsd.push(positions[i].position.positionFee.realizedBorrowingFeeInUsd);
            _before.positionOpenFundingFeePerQty.push(positions[i].position.positionFee.openFundingFeePerQty);
            _before.positionRealizedFundingFee.push(positions[i].position.positionFee.realizedFundingFee);
            _before.positionRealizedFundingFeeInUsd.push(positions[i].position.positionFee.realizedFundingFeeInUsd);
        }

        ///////// Custom Computations /////////
        
        /// PortfolioVault Balances
        _before.portfolioVaultRawEthBalance = diamondVaultFacet.getPortfolioVaultAddress().balance;
        _before.portfolioVaultWethBalance = weth.balanceOf(diamondVaultFacet.getPortfolioVaultAddress());
        _before.portfolioVaultUsdcBalance = usdc.balanceOf(diamondVaultFacet.getPortfolioVaultAddress());
        _before.portfolioVaultBtcBalance = wbtc.balanceOf(diamondVaultFacet.getPortfolioVaultAddress());

        /// TradeVault Balances
        _before.tradeVaultRawEthBalance = diamondVaultFacet.getTradeVaultAddress().balance;
        _before.tradeVaultWethBalance = weth.balanceOf(diamondVaultFacet.getTradeVaultAddress());
        _before.tradeVaultUsdcBalance = usdc.balanceOf(diamondVaultFacet.getTradeVaultAddress());
        _before.tradeVaultBtcBalance = wbtc.balanceOf(diamondVaultFacet.getTradeVaultAddress());

        /// LpVault Balances
        _before.lpVaultRawEthBalance = diamondVaultFacet.getLpVaultAddress().balance;
        _before.lpVaultWethBalance = weth.balanceOf(diamondVaultFacet.getLpVaultAddress());
        _before.lpVaultUsdcBalance = usdc.balanceOf(diamondVaultFacet.getLpVaultAddress());
        _before.lpVaultBtcBalance = wbtc.balanceOf(diamondVaultFacet.getLpVaultAddress());
    }

    function __after(address _user, OracleProcess.OracleParam[] memory _oracles) internal {
        ///////// AccountFacet /////////
        IAccount.AccountInfo memory account = diamondAccountFacet.getAccountInfo(_user);
        _after.accountOwner = account.owner;

        for(uint256 i = 0; i < account.tokenBalances.length; i++) {
            _after.accountTokenBalancesAmount.push(account.tokenBalances[i].amount);
            _after.accountTokenBalancesUsedAmount.push(account.tokenBalances[i].usedAmount);
            _after.accountTokenBalancesInterest.push(account.tokenBalances[i].interest);
            _after.accountTokenBalancesLiability.push(account.tokenBalances[i].liability);
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
        
        IAccount.AccountInfo memory accountWithOracles = diamondAccountFacet.getAccountInfoWithOracles(_user, _oracles);
        _after.accountOwnerWithOracles = accountWithOracles.owner;

        // _after.accountTokenBalancesWithOracles = accountWithOracles.tokenBalances;
        for(uint256 i = 0; i < account.tokenBalances.length; i++) {
            _after.accountTokenBalancesAmountWithOracles.push(account.tokenBalances[i].amount);
            _after.accountTokenBalancesUsedAmountWithOracles.push(account.tokenBalances[i].usedAmount);
            _after.accountTokenBalancesInterestWithOracles.push(account.tokenBalances[i].interest);
            _after.accountTokenBalancesLiabilityWithOracles.push(account.tokenBalances[i].liability);
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

        
        //////// OrderFacet /////////
        // _after.accountOrders = diamondOrderFacet.getAccountOrders(_user);
        IOrder.AccountOrder[] memory orders= diamondOrderFacet.getAccountOrders(_user);
        for(uint256 i = 0; i < orders.length; i++) {
            _after.orderId.push(orders[i].orderId);
            _after.symbol.push(orders[i].orderInfo.symbol);
            _after.orderSide.push(orders[i].orderInfo.orderSide);
            _after.posSide.push(orders[i].orderInfo.posSide);
            _after.orderType.push(orders[i].orderInfo.orderType);
            _after.stopType.push(orders[i].orderInfo.stopType);
            _after.isCrossMargin.push(orders[i].orderInfo.isCrossMargin);
            _after.isExecutionFeeFromTradeVault.push(orders[i].orderInfo.isExecutionFeeFromTradeVault);
            _after.marginToken.push(orders[i].orderInfo.marginToken);
            _after.qty.push(orders[i].orderInfo.qty);
            _after.leverage.push(orders[i].orderInfo.leverage);
            _after.orderMargin.push(orders[i].orderInfo.orderMargin);
            _after.triggerPrice.push(orders[i].orderInfo.triggerPrice);
            _after.acceptablePrice.push(orders[i].orderInfo.acceptablePrice);
            _after.placeTime.push(orders[i].orderInfo.placeTime);
            _after.executionFee.push(orders[i].orderInfo.executionFee);
            _after.lastBlock.push(orders[i].orderInfo.lastBlock);
        }
        

        //////// PositionFacet /////////
        IPosition.PositionInfo[] memory positions = diamondPositionFacet.getAllPositions(_user);
        for (uint256 i = 0; i < positions.length; i++) {
            _after.positionLiquidationPrice.push(positions[i].liquidationPrice);
            _after.positionCurrentTimestamp.push(positions[i].currentTimestamp);

            _after.positionKey.push(positions[i].position.key);
            _after.positionSymbol.push(positions[i].position.symbol);
            _after.positionIsLong.push(positions[i].position.isLong);
            _after.positionIsCrossMargin.push(positions[i].position.isCrossMargin);
            _after.positionAccount.push(positions[i].position.account);
            _after.positionMarginToken.push(positions[i].position.marginToken);
            _after.positionIndexToken.push(positions[i].position.indexToken);
            _after.positionQty.push(positions[i].position.qty);
            _after.positionEntryPrice.push(positions[i].position.entryPrice);
            _after.positionLeverage.push(positions[i].position.leverage);
            _after.positionInitialMargin.push(positions[i].position.initialMargin);
            _after.positionInitialMarginInUsd.push(positions[i].position.initialMarginInUsd);
            _after.positionInitialMarginInUsdFromBalance.push(positions[i].position.initialMarginInUsdFromBalance);
            _after.positionHoldPoolAmount.push(positions[i].position.holdPoolAmount);
            _after.positionRealizedPnl.push(positions[i].position.realizedPnl);
            _after.positionLastUpdateTime.push(positions[i].position.lastUpdateTime);

            _after.PositionCloseFeeInUsd.push(positions[i].position.positionFee.closeFeeInUsd);
            _after.positionOpenBorrowingFeePerToken.push(positions[i].position.positionFee.openBorrowingFeePerToken);
            _after.positionRealizedBorrowingFee.push(positions[i].position.positionFee.realizedBorrowingFee);
            _after.positionRealizedBorrowingFeeInUsd.push(positions[i].position.positionFee.realizedBorrowingFeeInUsd);
            _after.positionOpenFundingFeePerQty.push(positions[i].position.positionFee.openFundingFeePerQty);
            _after.positionRealizedFundingFee.push(positions[i].position.positionFee.realizedFundingFee);
            _after.positionRealizedFundingFeeInUsd.push(positions[i].position.positionFee.realizedFundingFeeInUsd);
        }
        
        ///////// Custom Computations /////////

        /// PortfolioVault Balances
        _after.portfolioVaultRawEthBalance = diamondVaultFacet.getPortfolioVaultAddress().balance;
        _after.portfolioVaultWethBalance = weth.balanceOf(diamondVaultFacet.getPortfolioVaultAddress());
        _after.portfolioVaultUsdcBalance = usdc.balanceOf(diamondVaultFacet.getPortfolioVaultAddress());
        _after.portfolioVaultBtcBalance = wbtc.balanceOf(diamondVaultFacet.getPortfolioVaultAddress());

        /// TradeVault Balances
        _after.tradeVaultRawEthBalance = diamondVaultFacet.getTradeVaultAddress().balance;
        _after.tradeVaultWethBalance = weth.balanceOf(diamondVaultFacet.getTradeVaultAddress());
        _after.tradeVaultUsdcBalance = usdc.balanceOf(diamondVaultFacet.getTradeVaultAddress());
        _after.tradeVaultBtcBalance = wbtc.balanceOf(diamondVaultFacet.getTradeVaultAddress());

        /// LpVault Balances
        _after.lpVaultRawEthBalance = diamondVaultFacet.getLpVaultAddress().balance;
        _after.lpVaultWethBalance = weth.balanceOf(diamondVaultFacet.getLpVaultAddress());
        _after.lpVaultUsdcBalance = usdc.balanceOf(diamondVaultFacet.getLpVaultAddress());
        _after.lpVaultBtcBalance = wbtc.balanceOf(diamondVaultFacet.getLpVaultAddress());

    }
}
