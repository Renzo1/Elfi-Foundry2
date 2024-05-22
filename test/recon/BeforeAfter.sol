
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Setup} from "./Setup.sol";

import "src/interfaces/IOrder.sol"; 
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

        ///////// OrderFacet /////////
        IOrder.AccountOrder[] accountOrders;

        ///////// OrderFacet /////////
        IPosition.PositionInfo[] accountPositionsInfo;

    }

    Vars internal _before;
    Vars internal _after;


    function __before(address _user, OracleProcess.OracleParam[] calldata _oracles) internal {
        ///////// AccountFacet /////////
        IAccount.AccountInfo memory account = diamondAccountFacet.getAccountInfo(_user);
        _before.accountOwner = account.owner;
        _before.accountTokenBalances = account.tokenBalances;
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
        _before.accountTokenBalancesWithOracles = accountWithOracles.tokenBalances;
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
        _before.accountOrders = diamondOrderFacet.getAccountOrders(_user);
        

        ///////// PositionFacet /////////
        _before.accountPositionsInfo = diamondPositionFacet.getAllPositions(_user);

        ///////// Custom Computations /////////
    }

    function __after(address _user, OracleProcess.OracleParam[] calldata _oracles) internal {
        ///////// AccountFacet /////////
        IAccount.AccountInfo memory account = diamondAccountFacet.getAccountInfo(_user);
        _after.accountOwner = account.owner;
        _after.accountTokenBalances = account.tokenBalances;
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
        _after.accountTokenBalancesWithOracles = accountWithOracles.tokenBalances;
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
        _after.accountOrders = diamondOrderFacet.getAccountOrders(_user);

        //////// PositionFacet /////////
        _after.accountPositionsInfo = diamondPositionFacet.getAllPositions(_user);

        ///////// Custom Computations /////////

    }
}
