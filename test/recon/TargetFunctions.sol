
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



abstract contract TargetFunctions is BaseTargetFunctions, Properties, BeforeAfter {
    /////////////////////////////////////////
    //// Utility functions & Modifiers //////
    /////////////////////////////////////////

    ///////// OracleProcess /////////

    function getOracleParam(uint16 _answer) internal returns(OracleProcess.OracleParam[] memory) {

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

    /**
      tokenToUsd(value: bigint, price: number | string | bigint, decimal: number) {
        return (value * BigInt(price) * BigInt(Math.pow(10, 18 - decimal))) / BigInt(Math.pow(10, 8))
    },

    usdToToken(value: bigint, price: number | string | bigint, decimal: number = 18) {
        return (value * BigInt(Math.pow(10, 8))) / BigInt(price) / BigInt(Math.pow(10, 18 - decimal))
    },
    */
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

    struct KeeperExecutions {
        OrderExecutions[] orderExecutions;
        AccountWithdrawExecutions[] accountWithdrawExecutions;
        CancelWithdrawExecutions[] cancelWithdrawExecutions;
    }
    
    KeeperExecutions internal _keeperExecutions;

    /**
    consider the delay variation of execution modifiers
    */
    /////////// executeOrder ///////////
    struct OrderExecutions {
        uint256 orderId;
        OracleProcess.OracleParam[] oracles;
    }

    function executeOrder(uint16 _answer) public {
        // Execute the function first
        

        // for each orders in the queue (KeeperExecutions.orderExecutions)

        // Execute the order
        // diamondOrderFacet.executeOrder(OrderExecutions.orderId, OrderExecutions.oracles);

        // Remove the order from the queue (KeeperExecutions.orderExecutions)
    }


    /////////// executeWithdraw ///////////
    function accountFacet_executeWithdraw(uint16 _answer) public{
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

    function accountFacet_cancelWithdraw(uint8 _requestIndex, uint16 _answer) public {
        /// Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        uint256 requestId;
        bytes32 reasonCode;

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
        for(uint256 i = 0; i < openRequests.length; i++) {
            if(!_keeperExecutions.accountWithdrawExecutions[i].executed) {
                openRequests[i] = _keeperExecutions.accountWithdrawExecutions[i];
            }
        }

        /// select a random request from the list
        uint256 _requestIndex = EchidnaUtils.clampBetween(uint256(_requestIndex), 0, openRequests.length - 1);
        AccountWithdrawExecutions memory request = openRequests[_requestIndex];
        requestId = request.requestId;

        vm.prank(keeper); // prolly redundant
        try diamondAccountFacet.cancelWithdraw(requestId, ""){
            __after(msg.sender, oracles); // Update the contract state tracker

            // Add to cancelWithdrawRequest Queue
            CancelWithdrawExecutions memory execution = CancelWithdrawExecutions(request.account, requestId, request.token, request.amount,true);
            _keeperExecutions.cancelWithdrawExecutions.push(execution);

            // Update status of request in withdrawRequest queue
            for(uint256 i = 0; i < numRequests; i++) {
                if(_keeperExecutions.accountWithdrawExecutions[i].requestId == requestId) {
                    _keeperExecutions.accountWithdrawExecutions[i].executed = true;
                }
            }

            /// Invariants assessment

            // Update the deposit tracker
            // Add tx to keeper queue orders --> KeeperExecutions.accountExecutions[]

        }catch{       

        }
    }


    /////////// executeUpdatePositionMarginRequest ///////////
    function positionFacet_executeUpdatePositionMarginRequest(uint16 _answer) public{
        

        // uint256 requestId;
        // OracleProcess.OracleParam[] memory oracles;
        // diamondPositionFacet.executeUpdatePositionMarginRequest(requestId, oracles);
    }


    /////////// executeUpdateLeverageRequest ///////////
    function positionFacet_executeUpdateLeverageRequest(uint16 _answer) public{
        

        // uint256 requestId; 
        // OracleProcess.OracleParam[] calldata oracles;
        // diamondPositionFacet.executeUpdateLeverageRequest(requestId, oracles);
    }
    
    
    /////////// executeMintStakeToken ///////////
    function stakeFacet_executeMintStakeToken(uint16 _answer) public{
        

        // uint256 requestId; 
        // OracleProcess.OracleParam[] calldata oracles;
        // diamondStakeFacet.executeMintStakeToken(requestId, oracles);
    }
    

    /////////// executeRedeemStakeToken ///////////
    function stakeFacet_executeRedeemStakeToken(uint16 _answer) public{
        

        // uint256 requestId; 
        // OracleProcess.OracleParam[] calldata oracles;
        // diamondStakeFacet.executeRedeemStakeToken(requestId, oracles);
    }


    /////////// Aux functions ///////////
    // Liquidation function that is called after every Tx
    // call this after every tx 

    function attemptLiquidation(address account) internal {

        // Liquidate all positions under water
    }

    ///////////////////////////
    //// Wrapper functions ////
    ///////////////////////////

    ////////// AccountFacet //////////
    
    /// deposit
    function accountFacet_deposit(uint8 _tokenIndex, uint96 _amount, bool _sendEth, bool _onlyEth, uint96 _ethValue, uint16 _answer) public{
        // Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        // select a random token
        uint256 tokenIndex = EchidnaUtils.clampBetween(uint256(_tokenIndex), 0, tokens.length - 1);
        address token = tokens[tokenIndex]; // select a random token

        uint256 amount = EchidnaUtils.clampBetween(uint256(_amount), 0, IERC20(token).balanceOf(msg.sender));
        
        uint256 ethValue;
        // _sendEth = false; // toggle this on for some jobs
        if(_sendEth){
            ethValue = EchidnaUtils.clampBetween(uint256(_ethValue), 0, msg.sender.balance);
            amount = ethValue;

            if (_onlyEth){ // to successfully deposit only eth
                token = address(0);
            }
        }else{
            ethValue = 0;
        }

        vm.prank(msg.sender); // prolly redundant
        try diamondAccountFacet.deposit{value: ethValue}(token, amount){
            __after(msg.sender, oracles); // Update the contract state tracker

            // Update the deposit tracker; Remember to factor in transaction fee when calculating with this
            _txsTracking.deposits[msg.sender][token] += amount;
            _txsTracking.deposits[msg.sender][ETH_ADDRESS] += ethValue;

            /// Invariants assessment
            /**
            - deposited amount should only enter portfolioVault
            
            */


        }catch{

            // Do something
        }
    }


    /// createWithdrawRequest
    function accountFacet_createWithdrawRequest(uint8 _tokenIndex, uint96 _amount, uint16 _answer) public {
        // Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        // select a random token
        uint256 tokenIndex = EchidnaUtils.clampBetween(uint256(_tokenIndex), 0, tokens.length - 1);
        address token = tokens[tokenIndex]; // select a random token
        uint256 amount;

        if(token == address(usdc)){
            amount = EchidnaUtils.clampBetween(uint256(_amount), 0, _before.portfolioVaultUsdcBalance);
        }else if(token == address(weth)){
            amount = EchidnaUtils.clampBetween(uint256(_amount), 0, _before.portfolioVaultWethBalance);
        }else{ // wbtc
            amount = EchidnaUtils.clampBetween(uint256(_amount), 0, _before.portfolioVaultBtcBalance);
        }

        vm.prank(msg.sender); // prolly redundant
        try diamondAccountFacet.createWithdrawRequest(token, amount) returns(uint256 requestId){
            __after(msg.sender, oracles); // Update the contract state tracker

            // Add to withdrawRequest Queue
            AccountWithdrawExecutions memory execution = AccountWithdrawExecutions(msg.sender, requestId, token, amount,false);
            _keeperExecutions.accountWithdrawExecutions.push(execution);

            /// Invariants assessment

            // Update the deposit tracker
            // Add tx to keeper queue orders --> KeeperExecutions.accountExecutions[]

        }catch{       

        }
    }

    /// batchUpdateAccountToken
    function accountFacet_batchUpdateAccountToken(
        uint16 _answer, 
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

        vm.prank(msg.sender); // prolly redundant
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
  

    ////////// OrderFacet //////////

    /**
    
    struct KeeperExecutions {
        OrderExecutions[] orderExecutions;
        AccountWithdrawExecutions[] accountWithdrawExecutions;
        CancelWithdrawExecutions[] cancelWithdrawExecutions;
    }
    
    KeeperExecutions internal _keeperExecutions;
    */
    

    struct TxsTracking {
        ////////// AccountFacet //////////
        // mapping users to their deposits
        // user -> token -> amount
        mapping (address => mapping (address => uint256)) deposits;
        
        // mapping users to their withdrawals
        // user -> token -> amount
        mapping (address => mapping (address => uint256)) processedWithdrawals;


        
        ////////// OrderFacet //////////
        // mapping users to their orders
        // mappings users to their positions(Long; Short; Executed (set by keeper));

        ////////// PositionFacet //////////
        // (might not be necessary as these actions update the above trackers)
        // mapping users to their Position Margin 

        // mapping users to their Position Leverage

    }

    TxsTracking internal _txsTracking;


    /// createOrderRequest
    // create order with weth or btc. 
    // do not use tokens array as it contains usdc  too
    function orderFacet_createOrderRequest(IOrder.PlaceOrderParams calldata params) public {

        // try diamondOrderFacet.createOrderRequest(IOrder.PlaceOrderParams(params)){
        //     // Do something
        //     // Push all executed orders into KeeperExecutions.orderExecutions[]

        // }catch{

        //     // Do something
        // }
    }

    /// batchCreateOrderRequest
    function orderFacet_batchCreateOrderRequest(IOrder.PlaceOrderParams calldata params) public {


        // try diamondOrderFacet.batchCreateOrderRequest(IOrder.PlaceOrderParams[](params)){

        //     // Do something
        // }catch{

        //     // Do something
        // }
    }
  
    function orderFacet_cancelOrder(uint256 orderId, bytes32 reasonCode) public {

        // try diamondOrderFacet.cancelOrder(orderId, reasonCode){

        //     // Do something
        // } catch {
        //     // Do something
        // }
    }



    ////////// PositionFacet //////////

    /// createUpdatePositionMarginRequest
    function positionFacet_createUpdatePositionMarginRequest(IPosition.UpdatePositionMarginParams calldata params) public {
        diamondPositionFacet.createUpdatePositionMarginRequest(params);
    }
  

    /// cancelUpdatePositionMarginRequest
    function positionFacet_cancelUpdatePositionMarginRequest(uint256 requestId, bytes32 reasonCode) public {
      diamondPositionFacet.cancelUpdatePositionMarginRequest(requestId, reasonCode);
    }
    

    /// createUpdateLeverageRequest
    function positionFacet_createUpdateLeverageRequest(IPosition.UpdateLeverageParams calldata params) public {
        diamondPositionFacet.createUpdateLeverageRequest(params);
    }


    /// cancelUpdateLeverageRequest
    function positionFacet_cancelUpdateLeverageRequest(uint256 requestId, bytes32 reasonCode) public {
      diamondPositionFacet.cancelUpdateLeverageRequest(requestId, reasonCode);
    }
    
    /// autoReducePositions
    function positionFacet_autoReducePositions(bytes32[] calldata positionKeys) public {
      diamondPositionFacet.autoReducePositions(positionKeys);
    }


    ////////// StakeFacet //////////

    /// createMintStakeTokenRequest

    function stakeFacet_createMintStakeTokenRequest(IStake.MintStakeTokenParams calldata params) public {
        diamondStakeFacet.createMintStakeTokenRequest(params);
    }
  

    /// cancelMintStakeToken

    function stakeFacet_cancelMintStakeToken(uint256 requestId, bytes32 reasonCode) public {
        diamondStakeFacet.cancelMintStakeToken(requestId, reasonCode);
    }

    /// createRedeemStakeTokenRequest

    function stakeFacet_createRedeemStakeTokenRequest(IStake.RedeemStakeTokenParams calldata params) public {
        diamondStakeFacet.createRedeemStakeTokenRequest(params);
    }


    /// cancelRedeemStakeToken

    function stakeFacet_cancelRedeemStakeToken(uint256 requestId, bytes32 reasonCode) public {
      diamondStakeFacet.cancelRedeemStakeToken(requestId, reasonCode);
    }


    ////////////////////////////
    //// Scenario functions ////
    ////////////////////////////
    // Consider moving to stateless test

    //////////// Frontrunners //////////


}
