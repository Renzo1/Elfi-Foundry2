
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "./BeforeAfter.sol";
import {Properties} from "./Properties.sol";
import {vm} from "@chimera/Hevm.sol";
import {EchidnaUtils} from "../utils/EchidnaUtils.sol";

import "src/process/OracleProcess.sol";
import "src/interfaces/IOrder.sol";
import "src/storage/Order.sol";
import "src/interfaces/IStake.sol";
import "src/interfaces/IPosition.sol";
import "src/mock/MockToken.sol";

import "../constants/ChainConfig.sol";
import "../constants/MarketConfig.sol";
import "../constants/RolesAndPools.sol";
import "../constants/StakeConfig.sol";
import "../constants/TradeConfig.sol";
import "../constants/UsdcTradeConfig.sol";
import "../constants/WbtcTradeConfig.sol";
import "../constants/WethTradeConfig.sol";


abstract contract TargetFunctions is BaseTargetFunctions, Properties, BeforeAfter {
    // function alwaysPasss() public {
    //     t(true, "Test passed!");
    // }
    
    ///////////////////////////////////////
    // Utility functions & Modifiers //////
    ///////////////////////////////////////

    // /////////// Faucet /////////
    // struct Counter {
    //     uint256 count;
    // }

    // Counter private _counter;
    // /// Deal users some token mid simulation after every X calls to this function
    // function dealUsers() public {
    //     if(_counter.count % 50 == 0) {
    //         for(uint256 i = 0; i < USERS.length; i++) {
    //             // deal ETH
    //             vm.prank(keeper);
    //             vm.deal(USERS[i], 100e18);
    
    //             // mint weth
    //             vm.prank(keeper);
    //             weth.mint(USERS[i], 100e18);
                
    //             // mint wbtc
    //             vm.prank(keeper);
    //             wbtc.mint(USERS[i], 10e8);
                
    //             // mint usdc
    //             vm.prank(keeper);
    //             usdc.mint(USERS[i], 10000e6);
    //         }
    //     }
    //     _counter.count++;
    // }


    ///////// Conversion Functions /////////

    function ethToWethConverter(uint256 _amount) internal returns(uint256) {
        uint256 wethDecimal = weth.decimals(); // 6 or 18
        uint256 ethDecimal = 18;

        return (_amount / (10 ** (ethDecimal - wethDecimal)));    
    }

    function wethToEthConverter(uint256 _amount) internal returns(uint256) {
        uint256 wethDecimal = weth.decimals(); // 6 or 18
        uint256 ethDecimal = 18;

        return (_amount * (10 ** (ethDecimal - wethDecimal)));
    }

    //////////////////////////////////////
    //// Keeper Execution Modifiers //////
    //////////////////////////////////////

    struct AccountWithdrawExecutions {
        address account;
        uint256 requestId;
        address token;
        uint256 amount;
        bool executed;
    }

    struct CancelWithdrawExecutions {
        address account;
        uint256 requestId;
        address token;
        uint256 amount;
        bool executed;
    }

    struct OrderExecutions {
        address account;
        uint256 orderId;
        bool isNativeToken;
        address marginToken;
        uint256 orderMargin;
        uint256 executionFee;
        bool executed;
    }

    struct CanceledOrders {
        address account;
        uint256 orderId;
        bool isNativeToken;
        address marginToken;
        uint256 orderMargin;
        uint256 executionFee;
        bool executed;
    }

    struct PositionMarginRequests {
        address account;
        uint256 requestId;
        uint256 positionKey;
        bool isAdd;
        bool isNativeToken;
        uint256 updateMarginAmount;
        uint256 executionFee;
        bool executed;
    }

    struct CanceledPositionMarginRequests {
        address account;
        uint256 requestId;
        uint256 positionKey;
        bool isAdd;
        bool isNativeToken;
        uint256 updateMarginAmount;
        uint256 executionFee;
        bool executed;
    }

    struct PositionLeverageRequests {
        address account;
        uint256 requestId;
        bytes32 symbol;
        bool isLong;
        bool isNativeToken;
        bool isCrossMargin;
        uint256 leverage;
        address marginToken;
        uint256 addMarginAmount;
        uint256 executionFee;
        bool executed;
    }

    struct CanceledPositionLeverageRequests {
        address account;
        uint256 requestId;
        bytes32 symbol;
        bool isLong;
        bool isNativeToken;
        bool isCrossMargin;
        uint256 leverage;
        address marginToken;
        uint256 addMarginAmount;
        uint256 executionFee;
        bool executed;
    }

    struct MintStakeRequests {
        address account;
        uint256 requestId;
        address stakeToken;
        address requestToken;
        uint256 requestTokenAmount;
        uint256 walletRequestTokenAmount;
        uint256 minStakeAmount;
        uint256 executionFee;
        bool isCollateral;
        bool isNativeToken;
        bool executed;
    }

    struct CanceledMintStakeRequests {
        address account;
        uint256 requestId;
        address stakeToken;
        address requestToken;
        uint256 requestTokenAmount;
        uint256 walletRequestTokenAmount;
        uint256 minStakeAmount;
        uint256 executionFee;
        bool isCollateral;
        bool isNativeToken;
        bool executed;
    }

    struct RedeemStakeTokenRequests{
        address account;
        uint256 requestId;
        address stakeToken;
        address redeemToken;
        uint256 unStakeAmount;
        uint256 minRedeemAmount;
        uint256 executionFee;
        bool executed;
    }

    struct CanceledRedeemStakeTokenRequests{
        address account;
        uint256 requestId;
        address stakeToken;
        address redeemToken;
        uint256 unStakeAmount;
        uint256 minRedeemAmount;
        uint256 executionFee;
        bool executed;
    }

    struct KeeperExecutions {
        AccountWithdrawExecutions[] accountWithdrawExecutions;
        CancelWithdrawExecutions[] cancelWithdrawExecutions;
        OrderExecutions[] orderExecutions;
        CanceledOrders[] canceledOrders;
        PositionMarginRequests[] positionMarginRequests;
        PositionLeverageRequests[] positionLeverageRequests;
        CanceledPositionMarginRequests[] canceledPositionMarginRequests;
        CanceledPositionLeverageRequests[] canceledPositionLeverageRequests;
        MintStakeRequests[] mintStakeRequests;
        CanceledMintStakeRequests[] canceledMintStakeRequests;
        RedeemStakeTokenRequests[] redeemStakeTokenRequests;
        CanceledRedeemStakeTokenRequests[] canceledRedeemStakeTokenRequests;
    }
    
    KeeperExecutions internal _keeperExecutions;

    struct TxsTracking {
        ////////// AccountFacet //////////
        // mapping users to their deposits
        // user -> token -> amount
        mapping (address => mapping (address => uint256)) deposits;
        
        // mapping users to their withdrawals
        // user -> token -> amount
        mapping (address => mapping (address => uint256)) processedWithdrawals;
    }

    TxsTracking internal _txsTracking;

    // TODO Liquidate once position passes maximum leverage

    /////////// executeOrder ///////////

    function executeOrder(uint256 _answer) public {
        // Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        
        OrderExecutions memory request;
        address account;
        uint256 requestId;
        
        for (uint256 i = 0; i < _keeperExecutions.orderExecutions.length; i++) {
            request = _keeperExecutions.orderExecutions[i];
            account = request.account;
            requestId = request.orderId;
            
            __before(account, oracles); // Update the contract state tracker

            if(!request.executed){
                vm.prank(keeper);
                try diamondOrderFacet.executeOrder(requestId, oracles){
                    __after(account, oracles); // Update the contract state tracker
                    _keeperExecutions.orderExecutions[i].executed = true;
    
                    
                    
                    /// Invariants assessment
    
    
    
                } catch {
                    // if executeWithdraw fails for valid reasons set:
                    // revert Errors.OrderNotExists(orderId);
                    // revert Errors.SymbolStatusInvalid(order.symbol);
                    // revert Errors.TokenInvalid(order.symbol, order.marginToken);
                    // revert Errors.TokenInvalid(order.symbol, order.marginToken);
                    // revert Errors.LeverageInvalid(order.symbol, order.leverage);
                    // revert Errors.OnlyOneShortPositionSupport(order.symbol);
                    // revert Errors.ExecutionPriceInvalid();
                    // revert Errors.BalanceNotEnough(account, marginToken);
                    // require(self.orderHoldInUsd >= holdInUsd, "orderHoldInUsd is smaller than holdInUsd");
                    // require(!isCheck || balance.amount >= balance.usedAmount + amount, "use token failed with amount not enough");
                    // revert Errors.OrderMarginTooSmall();
                    // revert Errors.UpdateLeverageError()
                    // revert Errors.UpdateLeverageError()
                    // require(self.tokens.contains(token), "token not exists!");
                    // require(self.tokenBalances[token].usedAmount >= amount, "unUse overflow!");
                    // revert Errors.DecreaseOrderSideInvalid();
                    // revert Errors.PositionNotExists();
                    // revert Errors.PositionShouldBeLiquidation();

                    _keeperExecutions.orderExecutions[i].executed = true;
    
                    // if executeWithdraw fails for invalid reasons assert false: DOS
                    // assert(false);
                }
            }
        }

        for(uint256 i = 0; i < _keeperExecutions.orderExecutions.length; i++) {
            // remove all executed requests from the queue
            if(_keeperExecutions.orderExecutions[i].executed) {
                _keeperExecutions.orderExecutions[i] = _keeperExecutions.orderExecutions[_keeperExecutions.orderExecutions.length - 1];
                _keeperExecutions.orderExecutions.pop();
                // Decrement i to ensure the current index is checked again
                if (i > 0) {
                    i--;
                }
            }

        }
    }

    /////////// cancelOrder ///////////
    function orderFacet_cancelOrder(uint256 _requestIndex, uint256 _answer) public {
        /// Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        uint256 requestId;

        /// create a new list of requests yet to be executed
        // get the number of unexecuted requests (numNonExecutedRequests)
        uint256 numRequests = _keeperExecutions.orderExecutions.length;
        uint256 numNonExecutedRequests;
        for(uint256 i = 0; i < numRequests; i++) {
            if(!_keeperExecutions.orderExecutions[i].executed) {
                numNonExecutedRequests++;
            }
        }

        OrderExecutions[] memory openRequests = new OrderExecutions[](numNonExecutedRequests);
        uint256 index;
        for(uint256 i = 0; i < numRequests; i++) {
            if(!_keeperExecutions.orderExecutions[i].executed) {
                openRequests[index] = _keeperExecutions.orderExecutions[i];
                index++;
            }
        }

        /// select a random request from the list
        uint256 requestIndex = EchidnaUtils.clampBetween(_requestIndex, 0, openRequests.length - 1);
        OrderExecutions memory request = openRequests[requestIndex];
        requestId = request.orderId;

        vm.prank(keeper); // prolly redundant
        try diamondOrderFacet.cancelOrder(requestId, ""){
            __after(msg.sender, oracles); // Update the contract state tracker

            // Add to canceledOrder Queue -- tracking canceledOrder requests is not critical, but is useful for debugging
            CanceledOrders memory execution = CanceledOrders(request.account, requestId, request.isNativeToken, request.marginToken, request.orderMargin,request.executionFee,false);
            _keeperExecutions.canceledOrders.push(execution);

            // Update status of request in withdrawRequest queue
            for(uint256 i = 0; i < numRequests; i++) {
                if(_keeperExecutions.orderExecutions[i].orderId == requestId) {
                    _keeperExecutions.orderExecutions[i].executed = true;
                }
            }

            /// Invariants assessment


        }catch{       

        }
    }

    /////////// executeWithdraw ///////////
    function accountFacet_executeWithdraw(uint256 _answer) public{
        // Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        
        AccountWithdrawExecutions memory request;
        address account;
        uint256 requestId;
        address token;
        uint256 amount;
        
        for (uint256 i = 0; i < _keeperExecutions.accountWithdrawExecutions.length; i++) {
            request = _keeperExecutions.accountWithdrawExecutions[i];
            account = request.account;
            requestId = request.requestId;
            token = request.token;
            amount = request.amount;
            
            __before(account, oracles); // Update the contract state tracker

            if(!request.executed){
                vm.prank(keeper);
                try diamondAccountFacet.executeWithdraw(requestId, oracles){
                    __after(account, oracles); // Update the contract state tracker
                    _keeperExecutions.accountWithdrawExecutions[i].executed = true;
    
                    // Update the withdrawal tracker; Remember to factor in transaction fee when calculating with this
                    _txsTracking.processedWithdrawals[account][token] += amount;
    
                    
                    /// Invariants assessment
    
    
    
                } catch {
                    // if executeWithdraw fails for valid reasons set:
                    _keeperExecutions.accountWithdrawExecutions[i].executed = true;

                    // revert Errors.WithdrawRequestNotExists();
                    // revert Errors.AmountZeroNotAllowed();
                    // revert Errors.OnlyCollateralSupported();
                    // revert Errors.WithdrawWithNoEnoughAmount();
                    // revert Errors.PriceIsZero();
                    // revert Errors.WithdrawWithNoEnoughAmount();
                    // require(self.tokens.contains(token), "token not exists!");
                    // require(self.tokenBalances[token].amount >= amount, "token amount not enough!");

    
                    // if executeWithdraw fails for invalid reasons assert false: DOS
                    // assert(false);
                }
            }
        }

        for(uint256 i = 0; i < _keeperExecutions.accountWithdrawExecutions.length; i++) {
            // remove all executed requests from the queue
            if(_keeperExecutions.accountWithdrawExecutions[i].executed) {
                _keeperExecutions.accountWithdrawExecutions[i] = _keeperExecutions.accountWithdrawExecutions[_keeperExecutions.accountWithdrawExecutions.length - 1];
                _keeperExecutions.accountWithdrawExecutions.pop();
                // Decrement i to ensure the current index is checked again
                if (i > 0) {
                    i--;
                }
            }

        }
    }
  
    /////////// cancelWithdraw ///////////

    function accountFacet_cancelWithdraw(uint256 _requestIndex, uint256 _answer) public {
        /// Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        uint256 requestId;

        /// create a new list of requests yet to be executed
        // get the number of unexecuted requests
        uint256 numRequests = _keeperExecutions.accountWithdrawExecutions.length;
        uint256 numNonExecutedRequests;
        for(uint256 i = 0; i < numRequests; i++) {
            if(!_keeperExecutions.accountWithdrawExecutions[i].executed) {
                numNonExecutedRequests++;
            }
        }

        AccountWithdrawExecutions[] memory openRequests = new AccountWithdrawExecutions[](numNonExecutedRequests);
        uint256 index;
        for(uint256 i = 0; i < numRequests; i++) {
            if(!_keeperExecutions.accountWithdrawExecutions[i].executed) {
                openRequests[index] = _keeperExecutions.accountWithdrawExecutions[i];
                index++;
            }
        }

        /// select a random request from the list
        uint256 requestIndex = EchidnaUtils.clampBetween(_requestIndex, 0, openRequests.length - 1);
        AccountWithdrawExecutions memory request = openRequests[requestIndex];
        requestId = request.requestId;

        vm.prank(keeper); // prolly redundant
        try diamondAccountFacet.cancelWithdraw(requestId, ""){
            __after(msg.sender, oracles); // Update the contract state tracker

            // Add to cancelWithdrawRequest Queue -- tracking cancelWithdraw requests is not critical, but is useful for debugging
            CancelWithdrawExecutions memory execution = CancelWithdrawExecutions(request.account, requestId, request.token, request.amount,false);
            _keeperExecutions.cancelWithdrawExecutions.push(execution);

            // Update status of request in withdrawRequest queue
            for(uint256 i = 0; i < numRequests; i++) {
                if(_keeperExecutions.accountWithdrawExecutions[i].requestId == requestId) {
                    _keeperExecutions.accountWithdrawExecutions[i].executed = true;
                }
            }

            /// Invariants assessment


        }catch{       
            // revert Errors.WithdrawRequestNotExists();
        }
    }


    /////////// executeUpdatePositionMarginRequest ///////////
    function positionFacet_executeUpdatePositionMarginRequest(uint256 _answer) public{
        // Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        
        PositionMarginRequests memory request;
        address account;
        uint256 requestId;
        
        for (uint256 i = 0; i < _keeperExecutions.positionMarginRequests.length; i++) {
            request = _keeperExecutions.positionMarginRequests[i];
            account = request.account;
            requestId = request.requestId;
            
            __before(account, oracles); // Update the contract state tracker

            if(!request.executed){
                vm.prank(keeper);
                try diamondPositionFacet.executeUpdatePositionMarginRequest(requestId, oracles){
                    __after(account, oracles); // Update the contract state tracker
                    _keeperExecutions.positionMarginRequests[i].executed = true;
    
                    
                    
                    /// Invariants assessment
    
    
    
                } catch {
                    // if executeWithdraw fails for valid reasons set:
                    // revert Errors.UpdatePositionMarginRequestNotExists();
                    // revert Errors.OnlyIsolateSupported();
                    // revert Errors.TokenIsNotSupport();
                    // revert Errors.AddMarginTooBig();
                    // require(self.baseTokenBalance.holdAmount >= amount, "sub hold bigger than hold");
                    // require(self.stableTokenBalances[stableToken].holdAmount >= amount, "sub hold bigger than hold");
                    // revert Errors.TransferErrorWithVaultBalanceNotEnough(vault, token, receiver, amount);
                    // revert AddressSelfNotSupported(receiver);
                    // revert Errors.ReduceMarginTooBig();
                    // revert Errors.PoolAmountNotEnough(stakeToken, token);
                    // revert Errors.PoolAmountNotEnough(stakeToken, token);
                    // require(isHoldAmountAllowed(self.baseTokenBalance, getPoolLiquidityLimit(self), amount),
                    //             "hold failed with balance not enough"
                    //         );
                    // revert Errors.TransferErrorWithVaultBalanceNotEnough(vault, token, receiver, amount);

                    _keeperExecutions.positionMarginRequests[i].executed = true;
    
                    // if executeWithdraw fails for invalid reasons assert false: DOS
                    // assert(false);
                }
            }
        }

        for(uint256 i = 0; i < _keeperExecutions.positionMarginRequests.length; i++) {
            // remove all executed requests from the queue
            if(_keeperExecutions.positionMarginRequests[i].executed) {
                _keeperExecutions.positionMarginRequests[i] = _keeperExecutions.positionMarginRequests[_keeperExecutions.positionMarginRequests.length - 1];
                _keeperExecutions.positionMarginRequests.pop();
                // Decrement i to ensure the current index is checked again
                if (i > 0) {
                    i--;
                }
            }

        }
    }


    /////////// cancelUpdatePositionMarginRequest ///////////
    function positionFacet_cancelUpdatePositionMarginRequest(uint256 _requestIndex, uint256 _answer) public {
        /// Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        uint256 requestId;

        /// create a new list of requests yet to be executed
        // get the number of unexecuted requests (numNonExecutedRequests)
        uint256 numRequests = _keeperExecutions.positionMarginRequests.length;
        uint256 numNonExecutedRequests;
        for(uint256 i = 0; i < numRequests; i++) {
            if(!_keeperExecutions.positionMarginRequests[i].executed) {
                numNonExecutedRequests++;
            }
        }

        PositionMarginRequests[] memory openRequests = new PositionMarginRequests[](numNonExecutedRequests);
        uint256 index;
        for(uint256 i = 0; i < numRequests; i++) {
            if(!_keeperExecutions.positionMarginRequests[i].executed) {
                openRequests[index] = _keeperExecutions.positionMarginRequests[i];
                index++;
            }
        }

        /// select a random request from the list
        uint256 requestIndex = EchidnaUtils.clampBetween(_requestIndex, 0, openRequests.length - 1);
        PositionMarginRequests memory request = openRequests[requestIndex];
        requestId = request.requestId;

        vm.prank(keeper); // prolly redundant
        try diamondPositionFacet.cancelUpdatePositionMarginRequest(requestId, ""){
            __after(msg.sender, oracles); // Update the contract state tracker

            // Add to canceledOrder Queue -- tracking canceledOrder requests is not critical, but is useful for debugging
            CanceledPositionMarginRequests memory execution = CanceledPositionMarginRequests(
                request.account, 
                requestId, 
                request.positionKey,
                request.isAdd,
                request.isNativeToken,
                request.updateMarginAmount,
                request.executionFee,
                false);
            _keeperExecutions.canceledPositionMarginRequests.push(execution);

            // Update status of request in withdrawRequest queue
            for(uint256 i = 0; i < numRequests; i++) {
                if(_keeperExecutions.positionMarginRequests[i].requestId == requestId) {
                    _keeperExecutions.positionMarginRequests[i].executed = true;
                }
            }

            /// Invariants assessment

            // Update the deposit tracker
            // Add tx to keeper queue orders --> KeeperExecutions.accountExecutions[]

        }catch{       

        }
      }

    /////////// executeUpdateLeverageRequest ///////////
    function positionFacet_executeUpdateLeverageRequest(uint256 _answer) public{
        // Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        
        PositionLeverageRequests memory request;
        address account;
        uint256 requestId;
        
        for (uint256 i = 0; i < _keeperExecutions.positionLeverageRequests.length; i++) {
            request = _keeperExecutions.positionLeverageRequests[i];
            account = request.account;
            requestId = request.requestId;
            
            __before(account, oracles); // Update the contract state tracker

            if(!request.executed){
                vm.prank(keeper);
                try diamondPositionFacet.executeUpdateLeverageRequest(requestId, oracles){
                    __after(account, oracles); // Update the contract state tracker
                    _keeperExecutions.positionLeverageRequests[i].executed = true;
    
                    
                    
                    /// Invariants assessment
    
    
    
                } catch {
                    // if executeWithdraw fails for valid reasons set:
                    // revert Errors.UpdateLeverageRequestNotExists();
                    // revert Errors.UpdateLeverageWithNoChange();
                    // revert Errors.UpdateLeverageWithNoChange();
                    // revert Errors.BalanceNotEnough(request.account, position.marginToken);
                    // revert Errors.PoolAmountNotEnough(stakeToken, token);
                    // revert Errors.PoolAmountNotEnough(stakeToken, token);
                    // revert Errors.TransferErrorWithVaultBalanceNotEnough(vault, token, receiver, amount);
                    // require(self.tokens.contains(token), "token not exists!");
                    // require(self.tokenBalances[token].usedAmount >= amount, "unUse overflow!");
                    // revert Errors.ReduceMarginTooBig();
                    // revert Errors.PoolAmountNotEnough(stakeToken, token);
                    // revert Errors.PoolAmountNotEnough(stakeToken, token);
                    // require(isHoldAmountAllowed(self.stableTokenBalances[stableToken], getPoolLiquidityLimit(), amount),"hold failed with balance not enough");
                    // revert Errors.TransferErrorWithVaultBalanceNotEnough(vault, token, receiver, amount);
                    // require(success, "STE");

                    _keeperExecutions.positionLeverageRequests[i].executed = true;
    
                    // if executeWithdraw fails for invalid reasons assert false: DOS
                    // assert(false);
                }
            }
        }

        for(uint256 i = 0; i < _keeperExecutions.positionLeverageRequests.length; i++) {
            // remove all executed requests from the queue
            if(_keeperExecutions.positionLeverageRequests[i].executed) {
                _keeperExecutions.positionLeverageRequests[i] = _keeperExecutions.positionLeverageRequests[_keeperExecutions.positionLeverageRequests.length - 1];
                _keeperExecutions.positionLeverageRequests.pop();
                // Decrement i to ensure the current index is checked again
                if (i > 0) {
                    i--;
                }
            }

        }   
    }
      
  
    /////////// cancelUpdateLeverageRequest ///////////
    function positionFacet_cancelUpdateLeverageRequest(uint256 _requestIndex, uint256 _answer) public {
        /// Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        uint256 requestId;

        /// create a new list of requests yet to be executed
        // get the number of unexecuted requests (numNonExecutedRequests)
        uint256 numRequests = _keeperExecutions.positionLeverageRequests.length;
        uint256 numNonExecutedRequests;
        for(uint256 i = 0; i < numRequests; i++) {
            if(!_keeperExecutions.positionLeverageRequests[i].executed) {
                numNonExecutedRequests++;
            }
        }

        PositionLeverageRequests[] memory openRequests = new PositionLeverageRequests[](numNonExecutedRequests);
        uint256 index;
        for(uint256 i = 0; i < numRequests; i++) {
            if(!_keeperExecutions.positionLeverageRequests[i].executed) {
                openRequests[index] = _keeperExecutions.positionLeverageRequests[i];
                index++;
            }
        }

        /// select a random request from the list
        uint256 requestIndex = EchidnaUtils.clampBetween(_requestIndex, 0, openRequests.length - 1);
        PositionLeverageRequests memory request = openRequests[requestIndex];
        requestId = request.requestId;

        vm.prank(keeper); // prolly redundant
        try diamondPositionFacet.cancelUpdateLeverageRequest(requestId, ""){
            __after(msg.sender, oracles); // Update the contract state tracker

            // Add to canceledOrder Queue -- tracking canceledOrder requests is not critical, but is useful for debugging
            CanceledPositionLeverageRequests memory execution = CanceledPositionLeverageRequests(
                request.account, 
                requestId, 
                request.symbol,
                request.isLong,
                request.isNativeToken,
                request.isCrossMargin,
                request.leverage,
                request.marginToken,
                request.addMarginAmount,
                request.executionFee,
                false);
            _keeperExecutions.canceledPositionLeverageRequests.push(execution);

            // Update status of request in withdrawRequest queue
            for(uint256 i = 0; i < numRequests; i++) {
                if(_keeperExecutions.positionMarginRequests[i].requestId == requestId) {
                    _keeperExecutions.positionMarginRequests[i].executed = true;
                }
            }

            /// Invariants assessment

            // Update the deposit tracker
            // Add tx to keeper queue orders --> KeeperExecutions.accountExecutions[]

        }catch{       
            // revert InvalidRoleAccess(msg.sender, role);
            // revert Errors.UpdateLeverageRequestNotExists();
            // revert Errors.TransferErrorWithVaultBalanceNotEnough(vault, token, receiver, amount);

        }
    }

    /**
    
    struct DecreasePositionParams {
        uint256 requestId;
        bytes32 symbol;
        bool isLiquidation;
        bool isCrossMargin;
        address marginToken;
        uint256 decreaseQty;
        uint256 executePrice;
    }


    */

    struct AutoDecreasePositionParamsHelper {
        bytes32[] positionKeys;
    }

    AutoDecreasePositionParamsHelper _autoDecreasePositionParamsHelper;

    /////////// autoReducePositions ///////////
    // This is a part of the protocol's risk control design. When the pool is insufficient to cover all user positions' 
    // profits and losses, the Keeper will sort the existing positions based on the profit rate and automatically 
    // reduce the positions with higher profit rates until the risk rate is controllable.

    modifier callAuto(uint256 _answer) {
        _;
        // if condition for autoReducePositions is met
        // call autoReducePositions
    }
    
    function sortPositions(uint256 _answer) internal view returns (bytes32[] memory) {
        
    }

    function positionFacet_autoReducePositions(uint256 _answer) internal {
        /// Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        
        // collect all positionKeys for every users' position
        for(uint256 i = 0; i < USERS.length; i++) {
            __before(USERS[i], oracles);
            
            // calculate the length of positionKeys
            for(uint256 j = 0; j < _before.positionKey.length; j++) {
                _autoDecreasePositionParamsHelper.positionKeys.push(_before.positionKey[j]);
            }
        }

        bytes32[] memory positionKeys = new bytes32[](_autoDecreasePositionParamsHelper.positionKeys.length);
        for(uint256 i = 0; i < _autoDecreasePositionParamsHelper.positionKeys.length; i++) {
            positionKeys[i] = _autoDecreasePositionParamsHelper.positionKeys[i];
        }

        // reset the _autoDecreasePositionParamsHelper.positionKeys array
        _autoDecreasePositionParamsHelper.positionKeys = new bytes32[](0);


        vm.prank(keeper); 
        try diamondPositionFacet.autoReducePositions(positionKeys){
            __after(msg.sender, oracles); // Update the contract state tracker

         
            /// Invariants assessment


        }catch{       

        }
    }
    
    
    /////////// executeMintStakeToken ///////////

    function stakeFacet_executeMintStakeToken(uint256 _answer) public{
        // Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        
        MintStakeRequests memory request;
        address account;
        uint256 requestId;
        
        for (uint256 i = 0; i < _keeperExecutions.mintStakeRequests.length; i++) {
            request = _keeperExecutions.mintStakeRequests[i];
            account = request.account;
            requestId = request.requestId;
            
            __before(account, oracles); // Update the contract state tracker

            if(!request.executed){
                vm.prank(keeper);
                try diamondStakeFacet.executeMintStakeToken(requestId, oracles){
                    __after(account, oracles); // Update the contract state tracker
                    _keeperExecutions.mintStakeRequests[i].executed = true;
    
                    
                    
                    /// Invariants assessment
    
    
    
                } catch {
                    // if executeWithdraw fails for valid reasons set:
                    _keeperExecutions.mintStakeRequests[i].executed = true;

                    // revert Errors.MintWithAmountZero();
                    // revert Errors.MintWithParamError();
                    // revert Errors.MintTokenInvalid(params.stakeToken, token);
                    // revert Errors.MintTokenInvalid(params.stakeToken, token);
                    // revert Errors.StakeTokenInvalid(params.stakeToken);
                    // revert Errors.MintWithParamError();
                    // revert Errors.MintTokenInvalid(mintRequest.stakeToken, mintRequest.requestToken);
                    // revert Errors.MintStakeTokenTooSmall(minMintStakeAmount, mintRequest.requestTokenAmount);
                    // revert Errors.MintFailedWithBalanceNotEnough(account, token);
                    // revert Errors.MintFailedWithBalanceNotEnough(account, token);
                    // require(self.tokens.contains(token), "token not exists!");
                    // require(self.tokenBalances[token].amount >= amount, "token amount not enough!");
                    // require(self.stableTokens.contains(stableToken), "stable token not supported!");
                    // revert Errors.PoolValueIsZero();
                    // revert Errors.MintStakeTokenTooSmall(params.minStakeAmount, mintStakeTokenAmount);
                    // require(self.stableTokens.contains(stableToken), "stable token not supported!");
                    // revert Errors.MintTokenInvalid(mintRequest.stakeToken, mintRequest.requestToken);
                    // revert Errors.MintStakeTokenTooSmall(minMintStakeAmount, mintRequest.requestTokenAmount);
                    // revert Errors.StakeTokenInvalid(mintRequest.stakeToken);
                    // require(success, "STE");

    
                    // if executeWithdraw fails for invalid reasons assert false: DOS
                    // assert(false);
                }
            }
        }

        for(uint256 i = 0; i < _keeperExecutions.mintStakeRequests.length; i++) {
            // remove all executed requests from the queue
            if(_keeperExecutions.mintStakeRequests[i].executed) {
                _keeperExecutions.mintStakeRequests[i] = _keeperExecutions.mintStakeRequests[_keeperExecutions.mintStakeRequests.length - 1];
                _keeperExecutions.mintStakeRequests.pop();
                // Decrement i to ensure the current index is checked again
                if (i > 0) {
                    i--;
                }
            }
        }   
    }

    

    /////////// cancelMintStakeToken ///////////

    function stakeFacet_cancelMintStakeToken(uint256 _requestIndex, uint256 _answer) public {
        /// Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        uint256 requestId;

        /// create a new list of requests yet to be executed
        // get the number of unexecuted requests (numNonExecutedRequests)
        uint256 numRequests = _keeperExecutions.mintStakeRequests.length;
        uint256 numNonExecutedRequests;
        for(uint256 i = 0; i < numRequests; i++) {
            if(!_keeperExecutions.mintStakeRequests[i].executed) {
                numNonExecutedRequests++;
            }
        }

        MintStakeRequests[] memory openRequests = new MintStakeRequests[](numNonExecutedRequests);
        uint256 index;
        for(uint256 i = 0; i < numRequests; i++) {
            if(!_keeperExecutions.mintStakeRequests[i].executed) {
                openRequests[index] = _keeperExecutions.mintStakeRequests[i];
                index++;
            }
        }

        /// select a random request from the list
        uint256 requestIndex = EchidnaUtils.clampBetween(_requestIndex, 0, openRequests.length - 1);
        MintStakeRequests memory request = openRequests[requestIndex];
        requestId = request.requestId;

        vm.prank(keeper); // prolly redundant
        try diamondStakeFacet.cancelMintStakeToken(requestId, ""){
            __after(msg.sender, oracles); // Update the contract state tracker

            // Add to canceledOrder Queue -- tracking canceledOrder requests is not critical, but is useful for debugging
            CanceledMintStakeRequests memory execution = CanceledMintStakeRequests(
                request.account, 
                requestId, 
                request.stakeToken,
                request.requestToken,
                request.requestTokenAmount,
                request.walletRequestTokenAmount,
                request.minStakeAmount,
                request.executionFee,
                request.isCollateral,
                request.isNativeToken,
                false);
            _keeperExecutions.canceledMintStakeRequests.push(execution);

            // Update status of request in withdrawRequest queue
            for(uint256 i = 0; i < numRequests; i++) {
                if(_keeperExecutions.mintStakeRequests[i].requestId == requestId) {
                    _keeperExecutions.mintStakeRequests[i].executed = true;
                }
            }

            /// Invariants assessment

            // Update the deposit tracker
            // Add tx to keeper queue orders --> KeeperExecutions.accountExecutions[]

        }catch{       

        }
    }

    /////////// executeRedeemStakeToken ///////////
    function stakeFacet_executeRedeemStakeToken(uint256 _answer) public{
            // Get oracles
            OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
            
            RedeemStakeTokenRequests memory request;
            address account;
            uint256 requestId;
            
            for (uint256 i = 0; i < _keeperExecutions.redeemStakeTokenRequests.length; i++) {
                request = _keeperExecutions.redeemStakeTokenRequests[i];
                account = request.account;
                requestId = request.requestId;
                
                __before(account, oracles); // Update the contract state tracker
    
                if(!request.executed){
                    vm.prank(keeper);
                    try diamondStakeFacet.executeMintStakeToken(requestId, oracles){
                        __after(account, oracles); // Update the contract state tracker
                        _keeperExecutions.redeemStakeTokenRequests[i].executed = true;
        
                        
                        
                        /// Invariants assessment
        
        
        
                    } catch {
                        // if executeWithdraw fails for valid reasons set:
                        _keeperExecutions.redeemStakeTokenRequests[i].executed = true;
                        // revert Errors.RedeemRequestNotExists();
                        // revert Errors.RedeemWithAmountNotEnough(account, stakeUsdToken);
                        // revert Errors.RedeemWithAmountNotEnough(account, params.redeemToken);
                        // revert Errors.RedeemStakeTokenTooSmall(redeemTokenAmount);
                        // revert Errors.RedeemWithAmountNotEnough(params.account, params.redeemToken);
                        // revert Errors.RedeemTokenInvalid(params.stakeToken, params.redeemToken);
                        // revert Errors.RedeemWithAmountNotEnough(params.account, baseToken);
                        // revert Errors.RedeemWithAmountNotEnough(params.account, params.redeemToken);

        
                        // if executeWithdraw fails for invalid reasons assert false: DOS
                        // assert(false);
                    }
                }
            }
    
            for(uint256 i = 0; i < _keeperExecutions.redeemStakeTokenRequests.length; i++) {
                // remove all executed requests from the queue
                if(_keeperExecutions.redeemStakeTokenRequests[i].executed) {
                    _keeperExecutions.redeemStakeTokenRequests[i] = _keeperExecutions.redeemStakeTokenRequests[_keeperExecutions.redeemStakeTokenRequests.length - 1];
                    _keeperExecutions.redeemStakeTokenRequests.pop();
                    // Decrement i to ensure the current index is checked again
                    if (i > 0) {
                        i--;
                    }
                }
            }   
        // diamondStakeFacet.executeRedeemStakeToken(requestId, oracles);
    }


    /////////// cancelRedeemStakeToken ///////////

    function stakeFacet_cancelRedeemStakeToken(uint256 _requestIndex, uint256 _answer) public {
        /// Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        uint256 requestId;

        /// create a new list of requests yet to be executed
        // get the number of unexecuted requests (numNonExecutedRequests)
        uint256 numRequests = _keeperExecutions.redeemStakeTokenRequests.length;
        uint256 numNonExecutedRequests;
        for(uint256 i = 0; i < numRequests; i++) {
            if(!_keeperExecutions.redeemStakeTokenRequests[i].executed) {
                numNonExecutedRequests++;
            }
        }

        RedeemStakeTokenRequests[] memory openRequests = new RedeemStakeTokenRequests[](numNonExecutedRequests);
        uint256 index;
        for(uint256 i = 0; i < numRequests; i++) {
            if(!_keeperExecutions.redeemStakeTokenRequests[i].executed) {
                openRequests[index] = _keeperExecutions.redeemStakeTokenRequests[i];
                index++;
            }
        }

        /// select a random request from the list
        uint256 requestIndex = EchidnaUtils.clampBetween(_requestIndex, 0, openRequests.length - 1);
        RedeemStakeTokenRequests memory request = openRequests[requestIndex];
        requestId = request.requestId;

        vm.prank(keeper); // prolly redundant
        try diamondStakeFacet.cancelRedeemStakeToken(requestId, ""){
            __after(msg.sender, oracles); // Update the contract state tracker

            // Add to canceledOrder Queue -- tracking canceledOrder requests is not critical, but is useful for debugging

            CanceledRedeemStakeTokenRequests memory execution = CanceledRedeemStakeTokenRequests(
                request.account, 
                requestId, 
                request.stakeToken,
                request.redeemToken,
                request.unStakeAmount,
                request.minRedeemAmount,
                request.executionFee,
                false);
            _keeperExecutions.canceledRedeemStakeTokenRequests.push(execution);

            // Update status of request in withdrawRequest queue
            for(uint256 i = 0; i < numRequests; i++) {
                if(_keeperExecutions.redeemStakeTokenRequests[i].requestId == requestId) {
                    _keeperExecutions.redeemStakeTokenRequests[i].executed = true;
                }
            }

            /// Invariants assessment

            // Update the deposit tracker
            // Add tx to keeper queue orders --> KeeperExecutions.accountExecutions[]

        }catch{       

        }
    }  
  
    /////////// Aux functions ///////////
    // Liquidation function that is called after every Tx
    // call this after every tx 

    function attemptLiquidation(address account) internal {

        // Liquidate all positions under water
    }

    ///////////////////////////////
    //// User Facing functions ////
    ///////////////////////////////

    ////////// AccountFacet //////////
    
    /// deposit ✅
    function accountFacet_deposit(uint256 _tokenIndex, uint256 _amount, bool _sendEth, bool _onlyEth, uint256 _ethValue, uint256 _answer) public{
        // Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        // select a random token
        uint256 tokenIndex = EchidnaUtils.clampBetween(_tokenIndex, 0, tokens.length - 1);
        address token = tokens[tokenIndex]; // select a random token

        uint256 amount = EchidnaUtils.clampBetween(_amount, 0, IERC20(token).balanceOf(msg.sender));
        
        uint256 ethValue;
        // _sendEth = false; // toggle this on for some jobs
        if(_sendEth){
            ethValue = EchidnaUtils.clampBetween(_ethValue, 0, msg.sender.balance);
            amount = ethValue;

            if (_onlyEth){ // to successfully deposit only eth
                token = address(0);
            }
        }else{
            ethValue = 0;
        }

        // vm.prank(msg.sender); // prolly redundant - can't be too safe ;
        try diamondAccountFacet.deposit{value: ethValue}(token, amount){
            __after(msg.sender, oracles); // Update the contract state tracker

            // Update the deposit tracker; Remember to factor in transaction fee when calculating with this
            _txsTracking.deposits[msg.sender][token] += amount;
            _txsTracking.deposits[msg.sender][ETH_ADDRESS] += ethValue;

            /// Invariants assessment
            /**
            - deposited amount should only enter portfolioVault
            */
            t(true, "accountFacet_deposit: test passed");

        }catch{

            // AccountFacet::deposit Revert Cases
            // revert Errors.AmountZeroNotAllowed();
            // revert Errors.AmountNotMatch(msg.value, amount);
            // revert Errors.OnlyCollateralSupported();
            // require(wrapperToken == params.token, "Deposit with token error!");
            // revert TokenTransferError(token, receiver, amount);
            // revert Errors.TokenIsNotSupportCollateral();
            // revert Errors.CollateralTotalCapOverflow(token, tradeTokenConfig.collateralTotalCap);
            // revert Errors.CollateralUserCapOverflow(token, tradeTokenConfig.collateralUserCap);
            // require(self.tokensTotalLiability[token] >= subLiability, "subTokenLiability less than liability");
            // require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256")
            
            
            // Do something
        }
    }


    /// createWithdrawRequest ✅
    function accountFacet_createWithdrawRequest(uint256 _tokenIndex, uint256 _amount, uint256 _answer) public {
        // Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        // select a random token
        uint256 tokenIndex = EchidnaUtils.clampBetween(_tokenIndex, 0, tokens.length - 1);
        address token = tokens[tokenIndex]; // select a random token
        uint256 amount;

        if(token == address(usdc)){
            amount = EchidnaUtils.clampBetween(_amount, 0, _before.portfolioVaultUsdcBalance);
        }else if(token == address(weth)){
            amount = EchidnaUtils.clampBetween(_amount, 0, _before.portfolioVaultWethBalance);
        }else{ // wbtc
            amount = EchidnaUtils.clampBetween(_amount, 0, _before.portfolioVaultBtcBalance);
        }

        // vm.prank(msg.sender); // prolly redundant - can't be too safe ;
        try diamondAccountFacet.createWithdrawRequest(token, amount) returns(uint256 requestId){
            __after(msg.sender, oracles); // Update the contract state tracker

            // Add to withdrawRequest Queue
            AccountWithdrawExecutions memory execution = AccountWithdrawExecutions(msg.sender, requestId, token, amount,false);
            _keeperExecutions.accountWithdrawExecutions.push(execution);

            /// Invariants assessment


        }catch{
            // revert Errors.AmountZeroNotAllowed();
            // revert AddressZero(); 

        }
    }

    /*
    /// batchUpdateAccountToken
    function accountFacet_batchUpdateAccountToken(
        uint256 _answer, 
        uint96 _changedUsdc, 
        uint96 _changedWeth, 
        uint96 _changedBtc, 
        bool _addUsdc,
        bool _addWeth,
        bool _addBtc
    ) public {
        // Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        AssetsProcess.UpdateAccountTokenParams memory params;
        params.account = msg.sender;
        params.tokens = tokens;
        params.changedTokenAmounts = new int256[](tokens.length);

        int256 usdcDelta;
        int256 wethDelta;
        int256 btcDelta;

        uint256 accountUsdcBalance;
        uint256 accountWethBalance;
        uint256 accountBtcBalance;

        for(uint256 i = 0; i < params.tokens.length; i++) {
            
            for(uint256 j = 0; j < _before.accountTokens.length; j++) {
                if(_before.accountTokens[j] == address(usdc)){
                    accountUsdcBalance = _before.accountTokenBalancesAmount[j];
                }else if(_before.accountTokens[j] == address(weth)){
                    accountWethBalance = _before.accountTokenBalancesAmount[j];
                }else if(_before.accountTokens[j] == address(wbtc)){
                    accountBtcBalance = _before.accountTokenBalancesAmount[j];
                }else{
                    accountUsdcBalance = 0;
                    accountWethBalance = 0;
                    accountBtcBalance = 0;
                }
            }

            if(params.tokens[i] == address(weth)){
                if(_addWeth){
                    // set weth delta
                    wethDelta = int256(EchidnaUtils.clampBetween(uint256(_changedWeth), 0, accountWethBalance));
                }else{
                    // set weth delta
                    wethDelta = -(int256(EchidnaUtils.clampBetween(uint256(_changedWeth), 0, accountWethBalance)));
                }

                params.changedTokenAmounts[i] = wethDelta;

            }else if(params.tokens[i] == address(wbtc)){
                if(_addBtc){
                    // set btc delta
                    btcDelta = int256(EchidnaUtils.clampBetween(uint256(_changedBtc), 0, accountBtcBalance));
                }else{
                    // set btc delta
                    btcDelta = -(int256(EchidnaUtils.clampBetween(uint256(_changedBtc), 0, accountBtcBalance)));
                }

                params.changedTokenAmounts[i] = btcDelta;

            }else{
                if(_addUsdc){
                    // set usdc delta
                    usdcDelta = int256(EchidnaUtils.clampBetween(uint256(_changedUsdc), 0, accountUsdcBalance));
                }else{
                    // set usdc delta
                    usdcDelta = -(int256(EchidnaUtils.clampBetween(uint256(_changedUsdc), 0, accountUsdcBalance)));
                }

                params.changedTokenAmounts[i] = usdcDelta;

            }
            
        }

        vm.prank(msg.sender); // prolly redundant - can't be too safe ;
        try diamondAccountFacet.batchUpdateAccountToken(params) {
            __after(msg.sender, oracles); // Update the contract state tracker

            // Add to withdrawRequest Queue
            // AccountWithdrawExecutions memory execution = AccountWithdrawExecutions(msg.sender, requestId, token, amount,false);
            // _keeperExecutions.accountWithdrawExecutions.push(execution);

            /// Invariants assessment

            // Update the deposit tracker
            // Add tx to keeper queue orders --> KeeperExecutions.accountExecutions[]

        }catch{       

        }
    
    }
    */

    ////////// OrderFacet //////////
    
    struct OrderParamsHelper{
        uint256 orderSide;
        uint256 orderType;
        uint256 stopType;
        uint256 tokenIndex;
        address token;
        uint256 tokenMargin;
        uint256 ethMargin;
        uint256 ethValue;
        address[] tokenAddresses;
        uint256 numOrders;
        int256 maxPrice;
    }

    /// createOrderRequest
    function orderFacet_createOrderRequest(
        uint256 _answer, 
        bool _isCrossMargin, 
        bool _isNativeToken,
        uint256 _orderSide, 
        uint256 _positionSide,
        uint256 _orderType,
        uint256 _stopType,
        uint256 _marginTokenIndex,
        uint256 _qty,
        uint256 _orderMargin,
        uint256 _leverage,
        uint256 _triggerPrice
    ) public {
        // Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        OrderParamsHelper memory orderParamsHelper;

        IOrder.PlaceOrderParams memory params;
        params.isCrossMargin = _isCrossMargin;
        params.isNativeToken = _isNativeToken;



        orderParamsHelper.orderSide = EchidnaUtils.clampBetween(_orderSide, 0, 2);
        if(orderParamsHelper.orderSide == 0){
            params.orderSide = Order.Side.NONE;
        }else if(orderParamsHelper.orderSide == 1){
            params.orderSide = Order.Side.LONG;
        }else{
            params.orderSide = Order.Side.SHORT;
        }

        uint256 positionSide = EchidnaUtils.clampBetween(_positionSide, 0, 2);
        if(positionSide == 0){
            params.posSide = Order.PositionSide.NONE;
        }else if(positionSide == 1){
            params.posSide = Order.PositionSide.INCREASE;
        }else{
            params.posSide = Order.PositionSide.DECREASE;
        }

        orderParamsHelper.orderType = EchidnaUtils.clampBetween(_orderType, 0, 3);
        if(orderParamsHelper.orderType == 0){
            params.orderType = Order.Type.NONE;
        }else if(orderParamsHelper.orderType == 1){
            params.orderType = Order.Type.MARKET;
        }else if(orderParamsHelper.orderType == 2){
            params.orderType = Order.Type.LIMIT;
        }else{
            params.orderType = Order.Type.STOP;
        }

        orderParamsHelper.stopType = EchidnaUtils.clampBetween(_stopType, 0, 2);
        if(orderParamsHelper.stopType == 0){
            params.stopType = Order.StopType.NONE;
        }else if(orderParamsHelper.stopType == 1){
            params.stopType = Order.StopType.STOP_LOSS;
        }else{
            params.stopType = Order.StopType.TAKE_PROFIT;
        }

        orderParamsHelper.tokenIndex = EchidnaUtils.clampBetween(_marginTokenIndex, 0, 2);
        orderParamsHelper.token = tokens[orderParamsHelper.tokenIndex];
        params.marginToken = orderParamsHelper.token;

        if(params.marginToken == address(weth)){
            params.symbol = MarketConfig.getWethSymbol();
        }else if(params.marginToken == address(wbtc)){
            params.symbol = MarketConfig.getWbtcSymbol();
        }else{
            // Note: Usdc is not configured to besupported as marginToken for LONG positionsSide, thus it has no symbol in our test suite. 
            // So to pass that check we are using a valid symbol whenever I test attempts to create a position with usdc as marginToken
            params.symbol = MarketConfig.getWethSymbol();
        }

        for(uint256 i = 0; i < oracles.length; i++) {
            if(oracles[i].token == params.marginToken) {
                params.triggerPrice = EchidnaUtils.clampBetween(_triggerPrice, uint256(oracles[i].maxPrice) / 5, uint256(oracles[i].maxPrice) * 5); 
                params.acceptablePrice = uint256(oracles[i].maxPrice); // TODO revisit this - bounds on acceptablePrice
            }
        }
    
        
        orderParamsHelper.tokenMargin = EchidnaUtils.clampBetween(_orderMargin, 0, IERC20(orderParamsHelper.token).balanceOf(msg.sender));
        orderParamsHelper.ethMargin = EchidnaUtils.clampBetween(_orderMargin, 0, msg.sender.balance);
        
        params.orderMargin = orderParamsHelper.tokenMargin;
        params.qty = EchidnaUtils.clampBetween(_qty, 0, (_before.portfolioVaultUsdcBalance + _before.tradeVaultUsdcBalance + _before.lpVaultUsdcBalance) * 100);
        // Consider a smaller bound on leverage to reduce revert cases that occurs when attempting to update a position with an unmatching leverage
        params.leverage = EchidnaUtils.clampBetween(_leverage, 0, MarketConfig.getMaxLeverage() * 2);
        params.executionFee = (ChainConfig.getPlaceIncreaseOrderGasFeeLimit() * tx.gasprice) + 10_000; // extra 10k to account for margin of error
        params.placeTime = block.timestamp;

        orderParamsHelper.ethValue = params.executionFee;

        if(params.isNativeToken){
            // open position with native token
            // and match orderMargin to ethValue, else Tx reverts
            orderParamsHelper.ethValue = orderParamsHelper.ethMargin;
            params.orderMargin = orderParamsHelper.ethMargin;
        }

        // vm.prank(msg.sender); // prolly redundant - can't be too safe ;)
        try diamondOrderFacet.createOrderRequest{value: orderParamsHelper.ethValue}(params)returns(uint256 orderId) {
            __after(msg.sender, oracles); // Update the contract state tracker

            // Add to orderRequest Queue
            OrderExecutions memory execution = OrderExecutions(
                msg.sender, 
                orderId,
                params.isNativeToken,
                params.marginToken,
                params.orderMargin,
                params.executionFee, 
                false
            );
            _keeperExecutions.orderExecutions.push(execution);


        }catch{

            // Do something

            // require(!params.isNativeToken || msg.value == params.orderMargin, "Deposit native token amount error!");
            // require(wrapperToken == params.token, "Deposit with token error!");
            // revert TokenTransferError(token, receiver, amount);
            // require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
            // require(keeper.balance >= value, "Address: insufficient balance for call");
            // revert Errors.PlaceOrderWithParamsError();
            // revert Errors.SymbolStatusInvalid(params.symbol);
            // revert Errors.OnlyOneShortPositionSupport(params.symbol);
            // revert Errors.ExecutionFeeNotEnough();

        }
    }


    struct BatchCreateOrderParamsHelper{
        bool _isCrossMargin;
        uint256 _orderSide;
        uint256 _orderType;
        uint256 _stopType;
        uint256 _marginTokenIndex;
        uint256 _orderMargin;
        uint256 _qty;
        uint256 _leverage;
        uint256 _triggerPrice;
    }

    function _createBatchOrders(
        uint256 _numOrders, 
        OracleProcess.OracleParam[] memory oracles, 
        BatchCreateOrderParamsHelper memory paramsHelper
    ) internal returns(IOrder.PlaceOrderParams[] memory orderParams, uint256 totalEthValue) {
        /* Note 
        - You can't add INCREASE posSide to the batch, else it reverts --> 
        - There all have to be the same isCrossMargin, else it reverts  --> v
        - If any of the orderType is NONE, it reverts  --> 
        - reverts if any PositionSide is DECREASE and Qty is zero --> 
        - reverts if any PositionSide is INCREASE and Qty is zero --> 
        - reverts if OrderSide is NONE --> 
        - reverts if OrderType is LIMIT and triggerPrice is zero --> 
        - reverts if OrderType is LIMIT and OrderPositionSide is DECREASE --> 
        - reverts if OrderType is STOP and (OrderStopType is NONE or triggerPrice is Zero) --> 
        */
        
        orderParams = new IOrder.PlaceOrderParams[](_numOrders);
        totalEthValue;
        
        OrderParamsHelper memory orderParamsHelper;
        IOrder.PlaceOrderParams memory params;

        for (uint256 i = 0; i < _numOrders; i++) {
            
            params.isCrossMargin = paramsHelper._isCrossMargin;
            params.isNativeToken = i % 2 == 0 ? true : false;
    
            orderParamsHelper.orderSide = EchidnaUtils.clampBetween(paramsHelper._orderSide, 0, 2);
            if(orderParamsHelper.orderSide == 0){
                params.orderSide = Order.Side.NONE;
            }else if(orderParamsHelper.orderSide == 1){
                params.orderSide = Order.Side.LONG;
            }else{
                params.orderSide = Order.Side.SHORT;
            }
    
            params.posSide = i % 2 == 0 ? Order.PositionSide.DECREASE : Order.PositionSide.NONE;
    
            orderParamsHelper.orderType = EchidnaUtils.clampBetween(paramsHelper._orderType, 0, 2);
            if(orderParamsHelper.orderType == 0){
                params.orderType = Order.Type.MARKET;
            }else if(orderParamsHelper.orderType == 1){
                params.orderType = Order.Type.STOP;
            }else{
                params.orderType = Order.Type.LIMIT;
            }
    
            orderParamsHelper.stopType = EchidnaUtils.clampBetween(paramsHelper._stopType, 0, 2);
            if(orderParamsHelper.stopType == 0){
                params.stopType = Order.StopType.NONE;
            }else if(orderParamsHelper.stopType == 1){
                params.stopType = Order.StopType.STOP_LOSS;
            }else{
                params.stopType = Order.StopType.TAKE_PROFIT;
            }

            orderParamsHelper.tokenAddresses = new address[](2);
            orderParamsHelper.tokenAddresses[0] = address(weth);
            orderParamsHelper.tokenAddresses[1] = address(wbtc);
    
            orderParamsHelper.tokenIndex = EchidnaUtils.clampBetween(paramsHelper._marginTokenIndex, 0, 1);
            orderParamsHelper.token = orderParamsHelper.tokenAddresses[orderParamsHelper.tokenIndex];
            params.marginToken = orderParamsHelper.token;
    
            if(params.marginToken == address(weth)){
                params.symbol = MarketConfig.getWethSymbol();
            }else{
                params.symbol = MarketConfig.getWbtcSymbol();
            }

            for(uint256 j = 0; j < oracles.length; i++) {
                if(oracles[j].token == params.marginToken) {
                    orderParamsHelper.maxPrice = oracles[j].maxPrice;
                    params.triggerPrice = EchidnaUtils.clampBetween(paramsHelper._triggerPrice, uint256(orderParamsHelper.maxPrice) / 5, uint256(orderParamsHelper.maxPrice) * 10); 
                }
            }
        
            params.acceptablePrice = params.triggerPrice;
            
            orderParamsHelper.tokenMargin = EchidnaUtils.clampBetween(paramsHelper._orderMargin, 0, IERC20(orderParamsHelper.token).balanceOf(msg.sender) / 2);
            orderParamsHelper.ethMargin = EchidnaUtils.clampBetween(paramsHelper._orderMargin, 0, msg.sender.balance);
            
            params.orderMargin = orderParamsHelper.tokenMargin;
            params.qty = EchidnaUtils.clampBetween(paramsHelper._qty, 0, (_before.portfolioVaultUsdcBalance + _before.tradeVaultUsdcBalance + _before.lpVaultUsdcBalance) * 100);
            params.leverage = EchidnaUtils.clampBetween(paramsHelper._leverage, 0, MarketConfig.getMaxLeverage() * 2);
            params.executionFee = (ChainConfig.getPlaceIncreaseOrderGasFeeLimit() * tx.gasprice) + 10_000; // extra 10k to account for margin of error
            params.placeTime = block.timestamp;
    
            orderParamsHelper.ethValue = params.executionFee;
    
            if(params.isNativeToken){
                // open position with native token
                // and match orderMargin to ethValue, else Tx reverts
                // orderParamsHelper.ethValue = orderParamsHelper.ethMargin;
                params.orderMargin = orderParamsHelper.ethMargin;
            }

            orderParams[i] = params;
            totalEthValue += params.executionFee;
        }
    }


    /// batchCreateOrderRequest
    function orderFacet_batchCreateOrderRequest(
        uint256 _answer,
        uint256 _numOrders, 
        bool _isCrossMargin, 
        uint256 _orderSide, 
        uint256 _orderType, 
        uint256 _stopType,
        uint256 _marginTokenIndex,
        uint256 _orderMargin,
        uint256 _qty,
        uint256 _leverage,
        uint256 _triggerPrice
    ) public {
        // Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        IOrder.PlaceOrderParams[] memory params;
        OrderParamsHelper memory orderParamsHelper;
        BatchCreateOrderParamsHelper memory paramsHelper;
        
        // keep the numOrder value very low to reduce the chance of tx reverts
        orderParamsHelper.numOrders =  EchidnaUtils.clampBetween(_numOrders, 1, 5);
        
        paramsHelper._isCrossMargin = _isCrossMargin;
        paramsHelper._orderSide = _orderSide;
        paramsHelper._orderType = _orderType;
        paramsHelper._stopType = _stopType;
        paramsHelper._marginTokenIndex = _marginTokenIndex;
        paramsHelper._orderMargin = _orderMargin;
        paramsHelper._qty = _qty;
        paramsHelper._leverage = _leverage;
        paramsHelper._triggerPrice = _triggerPrice;
        
        (params, orderParamsHelper.ethValue) = _createBatchOrders(orderParamsHelper.numOrders, oracles, paramsHelper);
        
        try diamondOrderFacet.batchCreateOrderRequest{value: orderParamsHelper.ethValue}(params)returns(uint256[] memory orderIds) {
            __after(msg.sender, oracles); // Update the contract state tracker

            // Add to orderRequest Queue
        
            OrderExecutions memory execution;
            for(uint256 i = 0; i < orderIds.length; i++) {
                execution = OrderExecutions(
                    msg.sender, 
                    orderIds[i], 
                    params[i].isNativeToken, 
                    params[i].marginToken, 
                    params[i].orderMargin, 
                    params[i].executionFee,
                    false);
                _keeperExecutions.orderExecutions.push(execution);
            }
            
        }catch{

            // Do something
        }
    }


    ////////// PositionFacet //////////

    /// createUpdatePositionMarginRequest
    function positionFacet_createUpdatePositionMarginRequest(uint256 _answer, bool _isAdd, bool _isNativeToken, uint256 _tokenIndex, uint256 _updateMarginAmount) public {
        // Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        /**
        Questions
        - Can the update marginToken be different from the position margin token? 
        Ans: It does validate in the contract
        */

        PositionParamsHelper memory positionParamsHelper;
        IPosition.UpdatePositionMarginParams memory params;

        positionParamsHelper.keyIndex = EchidnaUtils.clampBetween(_tokenIndex, 0, _before.positionKey.length - 1);

        params.positionKey = _before.positionKey[positionParamsHelper.keyIndex];
        params.isAdd = _isAdd;
        params.isNativeToken = _isNativeToken;

        positionParamsHelper.tokenIndex = EchidnaUtils.clampBetween(_tokenIndex, 0, tokens.length - 1);
        positionParamsHelper.token = tokens[positionParamsHelper.tokenIndex]; // select a random token
        params.marginToken = positionParamsHelper.token;

        positionParamsHelper.updateMarginAmount = EchidnaUtils.clampBetween(_updateMarginAmount, 0, IERC20(positionParamsHelper.token).balanceOf(msg.sender));
        params.updateMarginAmount = positionParamsHelper.updateMarginAmount;

        params.executionFee = (ChainConfig.getPositionUpdateMarginGasFeeLimit() * tx.gasprice) + 10_000;

        positionParamsHelper.ethValue = params.executionFee;

        if(_isNativeToken){
            params.updateMarginAmount = EchidnaUtils.clampBetween(_updateMarginAmount, 0, msg.sender.balance);
            positionParamsHelper.ethValue = params.updateMarginAmount;
        }


        try diamondPositionFacet.createUpdatePositionMarginRequest{value: positionParamsHelper.ethValue}(params)returns(uint256 requestId) {
            __after(msg.sender, oracles); // Update the contract state tracker

            // Add positionMarginRequest to Queue
            PositionMarginRequests memory execution = PositionMarginRequests(
                msg.sender, 
                requestId, 
                positionParamsHelper.keyIndex,
                params.isAdd,
                params.isNativeToken,
                params.updateMarginAmount,
                params.executionFee,
                false);
            _keeperExecutions.positionMarginRequests.push(execution);

            /// Invariants assessment

            
        }catch{
            // revert Errors.AmountZeroNotAllowed();
            // revert Errors.OnlyIsolateSupported();
            // revert Errors.ExecutionFeeNotEnough();
            // require(msg.value == params.executionFee, "update margin with execution fee error!");
            
            // Do something
        }

    }
  

    struct PositionParamsHelper{
        uint256 tokenIndex;
        address token;
        uint256 updateMarginAmount;
        uint256 ethValue;
        uint256 keyIndex;
        uint256 addMarginAmount;
        bytes32 symbol;
        uint256 symbolIndex;
        uint256 leverage;
    }

    /// createUpdateLeverageRequest
    function positionFacet_createUpdateLeverageRequest(uint256 _answer, bool _isLong, bool _isNativeToken, uint256 _tokenIndex, uint256 _addMarginAmount, uint256 _leverage ) public {
        // Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        PositionParamsHelper memory positionParamsHelper;
        IPosition.UpdateLeverageParams memory params;

        positionParamsHelper.symbolIndex = EchidnaUtils.clampBetween(_tokenIndex, 0, _before.positionSymbol.length - 1);
        positionParamsHelper.symbol = _before.positionSymbol[positionParamsHelper.symbolIndex];
        
        params.symbol = positionParamsHelper.symbol;
        params.isLong = _isLong;
        params.isNativeToken = _isNativeToken;
        
        positionParamsHelper.leverage = EchidnaUtils.clampBetween(_leverage, 0, MarketConfig.getMaxLeverage() + 100);
        params.leverage = positionParamsHelper.leverage;

        positionParamsHelper.tokenIndex = EchidnaUtils.clampBetween(_tokenIndex, 0, tokens.length - 1);
        positionParamsHelper.token = tokens[positionParamsHelper.tokenIndex]; // select a random token
        params.marginToken = positionParamsHelper.token;

        positionParamsHelper.addMarginAmount = EchidnaUtils.clampBetween(_addMarginAmount, 0, IERC20(positionParamsHelper.token).balanceOf(msg.sender));
        params.addMarginAmount = positionParamsHelper.addMarginAmount;

        params.executionFee = (ChainConfig.getPositionUpdateLeverageGasFeeLimit() * tx.gasprice) + 10_000;

        positionParamsHelper.ethValue = params.executionFee;

        if(_isNativeToken){
            params.addMarginAmount = EchidnaUtils.clampBetween(_addMarginAmount, 0, msg.sender.balance);
            positionParamsHelper.ethValue = params.addMarginAmount;
        }

        try diamondPositionFacet.createUpdateLeverageRequest{value: positionParamsHelper.ethValue}(params)returns(uint256 requestId) {
            __after(msg.sender, oracles); // Update the contract state tracker

            // Add positionMarginRequest to Queue
            PositionLeverageRequests memory execution = PositionLeverageRequests(
                msg.sender, 
                requestId,
                params.symbol,
                params.isLong,
                params.isNativeToken,
                params.isCrossMargin,
                params.leverage,
                params.marginToken,
                params.addMarginAmount,
                params.executionFee,
                false);
            _keeperExecutions.positionLeverageRequests.push(execution);

            /// Invariants assessment

            
        }catch{
            // revert Errors.SymbolNotExists();
            // revert Errors.SymbolStatusInvalid(params.symbol);
            // revert Errors.LeverageInvalid(params.symbol, params.leverage);
            // revert Errors.ExecutionFeeNotEnough();
            // require(msg.value == params.executionFee, "update leverage with execution fee error!");


            // Do something
        }
    }


    ////////// StakeFacet //////////
    /// @dev MintStakeTokenParams struct used for minting
    /// @param stakeToken The address of the pool
    /// @param requestToken The address of the token being used
    /// @param requestTokenAmount The total amount of tokens for minting
    /// @param walletRequestTokenAmount The amount of tokens from the wallet for minting.
    ///        When it is zero, it means that all of the requestTokenAmount is transferred from the user's trading account(Account).
    /// @param minStakeAmount The minimum staking return amount expected
    /// @param executionFee The execution fee for the keeper
    /// @param isCollateral Whether the request token is used as collateral
    /// @param isNativeToken whether the margin is ETH
    // struct MintStakeTokenParams {
    //     address stakeToken;
    //     address requestToken;
    //     uint256 requestTokenAmount;
    //     uint256 walletRequestTokenAmount;
    //     uint256 minStakeAmount;
    //     uint256 executionFee;
    //     bool isCollateral;
    //     bool isNativeToken;
    // }

    /// createMintStakeTokenRequest

    function stakeFacet_createMintStakeTokenRequest(
        uint256 _answer, 
        uint256 _stakeTokenIndex, 
        uint256 _requestTokenIndex, 
        uint256 _requestTokenAmount,
        uint256 _walletRequestTokenAmount,
        uint256 _minStakeAmount,
        bool _isCollateral,
        bool _isNativeToken
    ) public {
        // Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        StakeParamsHelper memory stakeParamsHelper;
        IStake.MintStakeTokenParams memory params;

        stakeParamsHelper.stakeTokenIndex = EchidnaUtils.clampBetween(_stakeTokenIndex, 0, stakedTokens.length - 1);
        stakeParamsHelper.stakeToken = stakedTokens[stakeParamsHelper.stakeTokenIndex]; // select a random token
        params.stakeToken = stakeParamsHelper.stakeToken;

        stakeParamsHelper.requestTokenIndex = EchidnaUtils.clampBetween(_requestTokenIndex, 0, tokens.length - 1);
        stakeParamsHelper.requestToken = tokens[stakeParamsHelper.requestTokenIndex]; // select a random token
        params.requestToken = stakeParamsHelper.requestToken;

        stakeParamsHelper.walletRequestTokenAmount = EchidnaUtils.clampBetween(_walletRequestTokenAmount, 0, IERC20(params.requestToken).balanceOf(msg.sender));
        params.walletRequestTokenAmount = stakeParamsHelper.walletRequestTokenAmount;

        params.minStakeAmount = _minStakeAmount;
        params.executionFee = (ChainConfig.getMintGasFeeLimit() * tx.gasprice) + 10_000;
        stakeParamsHelper.ethValue = params.executionFee;

        params.isCollateral = _isCollateral;
        params.isNativeToken = _isNativeToken;

        if(_isNativeToken){
            stakeParamsHelper.ethValue = EchidnaUtils.clampBetween(_requestTokenAmount, 0, msg.sender.balance);
            params.walletRequestTokenAmount = stakeParamsHelper.ethValue;
        }

        // Bound: requestTokenAmount >= walletRequestTokenAmount
        params.requestTokenAmount = EchidnaUtils.clampBetween(_requestTokenAmount, params.walletRequestTokenAmount, _requestTokenAmount); 

        try diamondStakeFacet.createMintStakeTokenRequest{value: stakeParamsHelper.ethValue}(params)returns(uint256 requestId) {
            __after(msg.sender, oracles); // Update the contract state tracker

            MintStakeRequests memory execution = MintStakeRequests(
                msg.sender, 
                requestId,
                params.stakeToken,
                params.requestToken,
                params.requestTokenAmount,
                params.walletRequestTokenAmount,
                params.minStakeAmount,
                params.executionFee,
                params.isCollateral,
                params.isNativeToken,
                false);
            _keeperExecutions.mintStakeRequests.push(execution);

            /// Invariants assessment

            
        }catch{

            // Do something
        }
    }

    struct StakeParamsHelper{
        uint256 requestTokenIndex;
        uint256 stakeTokenIndex;
        uint256 redeemTokenIndex;
        address stakeToken;
        address requestToken;
        address redeemToken;
        uint256 walletRequestTokenAmount;
        uint256 ethValue;
    }

    function stakeFacet_createRedeemStakeTokenRequest(
        uint256 _answer, 
        uint256 _stakeTokenIndex, 
        uint256 _redeemTokenIndex, 
        uint256 _requestTokenAmount,
        uint256 _unStakeAmount,
        uint256 _minRedeemAmount
    ) public {
        // Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        StakeParamsHelper memory stakeParamsHelper;
        IStake.RedeemStakeTokenParams memory params;

        params.receiver = msg.sender;

        stakeParamsHelper.stakeTokenIndex = EchidnaUtils.clampBetween(_stakeTokenIndex, 0, stakedTokens.length - 1);
        stakeParamsHelper.stakeToken = stakedTokens[stakeParamsHelper.stakeTokenIndex]; // select a random token
        params.stakeToken = stakeParamsHelper.stakeToken;

        stakeParamsHelper.redeemTokenIndex = EchidnaUtils.clampBetween(_redeemTokenIndex, 0, tokens.length - 1);
        stakeParamsHelper.redeemToken = tokens[stakeParamsHelper.redeemTokenIndex]; // select a random token
        params.redeemToken = stakeParamsHelper.redeemToken;

        params.unStakeAmount = EchidnaUtils.clampBetween(_unStakeAmount, 0, IERC20(params.stakeToken).balanceOf(msg.sender));

        params.minRedeemAmount = _minRedeemAmount; 
        params.executionFee = (ChainConfig.getRedeemGasFeeLimit() * tx.gasprice) + 10_000;
        stakeParamsHelper.ethValue = params.executionFee;

        try diamondStakeFacet.createRedeemStakeTokenRequest{value: stakeParamsHelper.ethValue}(params)returns(uint256 requestId) {
            __after(msg.sender, oracles); // Update the contract state tracker

            RedeemStakeTokenRequests memory execution = RedeemStakeTokenRequests(
                msg.sender, 
                requestId,
                params.stakeToken,
                params.redeemToken,
                params.unStakeAmount,
                params.minRedeemAmount,
                params.executionFee,
                false);
            _keeperExecutions.redeemStakeTokenRequests.push(execution);

            /// Invariants assessment

            
        }catch{

            // require(params.unStakeAmount > 0, "unStakeAmount == 0");
            // revert AddressZero();
            // revert Errors.RedeemWithAmountNotEnough(account, params.stakeToken);
            // revert Errors.RedeemWithAmountNotEnough(account, params.stakeToken);
            // revert Errors.RedeemTokenInvalid(params.stakeToken, params.redeemToken);
            // revert Errors.RedeemTokenInvalid(params.stakeToken, params.redeemToken);
            // require(msg.value == executionFee, "redeem with execution fee error!");

        }
    }

}
