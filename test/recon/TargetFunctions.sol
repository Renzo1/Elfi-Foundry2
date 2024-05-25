
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

    /////////// Faucet /////////
    struct Counter {
        uint256 count;
    }

    Counter private _counter;
    /// Deal users some token mid simulation after every X calls to this function
    function dealUsers() public {
        if(_counter.count % 50 == 0) {
            for(uint256 i = 0; i < USERS.length; i++) {
                // deal ETH
                vm.prank(address(this));
                vm.deal(USERS[i], 100e18);
    
                // mint weth
                vm.prank(address(this));
                weth.mint(USERS[i], 100e18);
                
                // mint wbtc
                vm.prank(address(this));
                wbtc.mint(USERS[i], 10e8);
                
                // mint usdc
                vm.prank(address(this));
                usdc.mint(USERS[i], 10000e6);
            }
        }
        _counter.count++;
    }

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
        bool executed;
    }

    struct CanceledOrders {
        address account;
        uint256 orderId;
        bool executed;
    }

    struct KeeperExecutions {
        AccountWithdrawExecutions[] accountWithdrawExecutions;
        CancelWithdrawExecutions[] cancelWithdrawExecutions;
        OrderExecutions[] orderExecutions;
        CanceledOrders[] canceledOrders;
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



    /////////// executeOrder ///////////

    function executeOrder(uint16 _answer) public {
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
    function orderFacet_cancelOrder(uint8 _requestIndex, uint16 _answer) public {
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
        for(uint256 i = 0; i < openRequests.length; i++) {
            if(!_keeperExecutions.orderExecutions[i].executed) {
                openRequests[i] = _keeperExecutions.orderExecutions[i];
            }
        }

        /// select a random request from the list
        uint256 requestIndex = EchidnaUtils.clampBetween(uint256(_requestIndex), 0, openRequests.length - 1);
        OrderExecutions memory request = openRequests[requestIndex];
        requestId = request.orderId;

        vm.prank(keeper); // prolly redundant
        try diamondOrderFacet.cancelOrder(requestId, ""){
            __after(msg.sender, oracles); // Update the contract state tracker

            // Add to canceledOrder Queue -- tracking canceledOrder requests is not critical, but is useful for debugging
            CanceledOrders memory execution = CanceledOrders(request.account, requestId, false);
            _keeperExecutions.canceledOrders.push(execution);

            // Update status of request in withdrawRequest queue
            for(uint256 i = 0; i < numRequests; i++) {
                if(_keeperExecutions.orderExecutions[i].orderId == requestId) {
                    _keeperExecutions.orderExecutions[i].executed = true;
                }
            }

            /// Invariants assessment

            // Update the deposit tracker
            // Add tx to keeper queue orders --> KeeperExecutions.accountExecutions[]

        }catch{       

        }
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
        uint256 requestIndex = EchidnaUtils.clampBetween(uint256(_requestIndex), 0, openRequests.length - 1);
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

    /*
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
        uint16 _answer, 
        bool _isCrossMargin, 
        bool _isNativeToken,
        uint8 _orderSide, 
        uint8 _positionSide,
        uint8 _orderType,
        uint8 _stopType,
        uint8 _marginTokenIndex,
        uint96 _qty,
        uint96 _orderMargin,
        uint96 _leverage,
        uint64 _triggerPrice
    ) public {
        // Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        OrderParamsHelper memory orderParamsHelper;

        IOrder.PlaceOrderParams memory params;
        params.isCrossMargin = _isCrossMargin;
        params.isNativeToken = _isNativeToken;



        orderParamsHelper.orderSide = EchidnaUtils.clampBetween(uint256(_orderSide), 0, 2);
        if(orderParamsHelper.orderSide == 0){
            params.orderSide = Order.Side.NONE;
        }else if(orderParamsHelper.orderSide == 1){
            params.orderSide = Order.Side.LONG;
        }else{
            params.orderSide = Order.Side.SHORT;
        }

        uint256 positionSide = EchidnaUtils.clampBetween(uint256(_positionSide), 0, 2);
        if(positionSide == 0){
            params.posSide = Order.PositionSide.NONE;
        }else if(positionSide == 1){
            params.posSide = Order.PositionSide.INCREASE;
        }else{
            params.posSide = Order.PositionSide.DECREASE;
        }

        orderParamsHelper.orderType = EchidnaUtils.clampBetween(uint256(_orderType), 0, 3);
        if(orderParamsHelper.orderType == 0){
            params.orderType = Order.Type.NONE;
        }else if(orderParamsHelper.orderType == 1){
            params.orderType = Order.Type.MARKET;
        }else if(orderParamsHelper.orderType == 2){
            params.orderType = Order.Type.LIMIT;
        }else{
            params.orderType = Order.Type.STOP;
        }

        orderParamsHelper.stopType = EchidnaUtils.clampBetween(uint256(_stopType), 0, 2);
        if(orderParamsHelper.stopType == 0){
            params.stopType = Order.StopType.NONE;
        }else if(orderParamsHelper.stopType == 1){
            params.stopType = Order.StopType.STOP_LOSS;
        }else{
            params.stopType = Order.StopType.TAKE_PROFIT;
        }

        orderParamsHelper.tokenIndex = EchidnaUtils.clampBetween(uint256(_marginTokenIndex), 0, 2);
        orderParamsHelper.token = tokens[orderParamsHelper.tokenIndex];
        params.marginToken = orderParamsHelper.token;

        if(params.marginToken == address(weth)){
            params.symbol = WETH_SYMBOL;
        }else if(params.marginToken == address(wbtc)){
            params.symbol = WBTC_SYMBOL;
        }else{
            // Note: Usdc is not configured to besupported as marginToken for LONG positionsSide, thus it has no symbol in our test suite. 
            // So to pass that check we are using a valid symbol whenever I test attempts to create a position with usdc as marginToken
            params.symbol = WETH_SYMBOL;
        }

        for(uint256 i = 0; i < oracles.length; i++) {
            if(oracles[i].token == params.marginToken) {
                params.triggerPrice = EchidnaUtils.clampBetween(uint256(_triggerPrice), uint256(oracles[i].maxPrice) / 5, uint256(oracles[i].maxPrice) * 10); 
            }
        }
    
        params.acceptablePrice = params.triggerPrice;
        
        orderParamsHelper.tokenMargin = EchidnaUtils.clampBetween(uint256(_orderMargin), 0, IERC20(orderParamsHelper.token).balanceOf(msg.sender));
        orderParamsHelper.ethMargin = EchidnaUtils.clampBetween(uint256(_orderMargin), 0, msg.sender.balance);
        
        params.orderMargin = orderParamsHelper.tokenMargin;
        params.qty = EchidnaUtils.clampBetween(uint256(_qty), 0, (_before.portfolioVaultUsdcBalance + _before.tradeVaultUsdcBalance + _before.lpVaultUsdcBalance) * 100);
        params.leverage = EchidnaUtils.clampBetween(uint256(_leverage), 0, MAX_LEVERAGE * 2);
        params.executionFee = (PLACE_INCREASE_ORDER_GAS_FEE_LIMIT * tx.gasprice) + 10_000; // extra 10k to account for margin of error
        params.placeTime = block.timestamp;

        orderParamsHelper.ethValue = params.executionFee;

        if(params.isNativeToken){
            // open position with native token
            // and match orderMargin to ethValue, else Tx reverts
            orderParamsHelper.ethValue = orderParamsHelper.ethMargin;
            params.orderMargin = orderParamsHelper.ethMargin;
        }

        vm.prank(msg.sender); // prolly redundant - can't be too safe ;)
        try diamondOrderFacet.createOrderRequest{value: orderParamsHelper.ethValue}(params)returns(uint256 orderId) {
            __after(msg.sender, oracles); // Update the contract state tracker

            // Add to orderRequest Queue
            OrderExecutions memory execution = OrderExecutions(msg.sender, orderId, false);
            _keeperExecutions.orderExecutions.push(execution);


        }catch{

            // Do something
        }
    }

    function _createBatchOrders(
        uint256 _numOrders, 
        OracleProcess.OracleParam[] memory oracles, 
        bool _isCrossMargin, 
        uint8 _orderSide,
        uint8 _orderType,
        uint8 _stopType,
        uint8 _marginTokenIndex,
        uint96 _orderMargin,
        uint64 _triggerPrice
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
            
            params.isCrossMargin = _isCrossMargin;
            params.isNativeToken = i % 2 == 0 ? true : false;
    
            orderParamsHelper.orderSide = EchidnaUtils.clampBetween(uint256(_orderSide), 0, 2);
            if(orderParamsHelper.orderSide == 0){
                params.orderSide = Order.Side.NONE;
            }else if(orderParamsHelper.orderSide == 1){
                params.orderSide = Order.Side.LONG;
            }else{
                params.orderSide = Order.Side.SHORT;
            }
    
            params.posSide = i % 2 == 0 ? Order.PositionSide.DECREASE : Order.PositionSide.NONE;
    
            orderParamsHelper.orderType = EchidnaUtils.clampBetween(uint256(_orderType), 0, 2);
            if(orderParamsHelper.orderType == 0){
                params.orderType = Order.Type.MARKET;
            }else if(orderParamsHelper.orderType == 1){
                params.orderType = Order.Type.STOP;
            }else{
                params.orderType = Order.Type.LIMIT;
            }
    
            orderParamsHelper.stopType = EchidnaUtils.clampBetween(uint256(_stopType), 0, 2);
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
    
            orderParamsHelper.tokenIndex = EchidnaUtils.clampBetween(uint256(_marginTokenIndex), 0, 1);
            orderParamsHelper.token = orderParamsHelper.tokenAddresses[orderParamsHelper.tokenIndex];
            params.marginToken = orderParamsHelper.token;
    
            if(params.marginToken == address(weth)){
                params.symbol = WETH_SYMBOL;
            }else{
                params.symbol = WBTC_SYMBOL;
            }

            for(uint256 i = 0; i < oracles.length; i++) {
                if(oracles[i].token == params.marginToken) {
                    orderParamsHelper.maxPrice = oracles[i].maxPrice;
                    params.triggerPrice = EchidnaUtils.clampBetween(uint256(_triggerPrice), uint256(orderParamsHelper.maxPrice) / 5, uint256(orderParamsHelper.maxPrice) * 10); 
                }
            }
        
            params.acceptablePrice = params.triggerPrice;
            
            orderParamsHelper.tokenMargin = EchidnaUtils.clampBetween(uint256(_orderMargin), 0, IERC20(orderParamsHelper.token).balanceOf(msg.sender) / 2);
            orderParamsHelper.ethMargin = EchidnaUtils.clampBetween(uint256(_orderMargin), 0, msg.sender.balance);
            
            params.orderMargin = orderParamsHelper.tokenMargin;
            params.qty = EchidnaUtils.clampBetween(uint256(_orderMargin + 66), 0, (_before.portfolioVaultUsdcBalance + _before.tradeVaultUsdcBalance + _before.lpVaultUsdcBalance) * 100);
            params.leverage = EchidnaUtils.clampBetween(uint256(_orderMargin + 77), 0, MAX_LEVERAGE * 2);
            params.executionFee = (PLACE_INCREASE_ORDER_GAS_FEE_LIMIT * tx.gasprice) + 10_000; // extra 10k to account for margin of error
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
        uint16 _answer,
        uint8 _numOrders, 
        bool _isCrossMargin, 
        uint8 _orderSide, 
        uint8 _orderType, 
        uint8 _stopType,
        uint8 _marginTokenIndex,
        uint96 _orderMargin,
        uint64 _triggerPrice
    ) public {
        // Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        IOrder.PlaceOrderParams[] memory params;
        OrderParamsHelper memory orderParamsHelper;

        // keep the numOrder value very low to reduce the chance of tx reverts
        orderParamsHelper.numOrders =  EchidnaUtils.clampBetween(uint256(_numOrders), 1, 2);

        (params, orderParamsHelper.ethValue) = _createBatchOrders(orderParamsHelper.numOrders, oracles, _isCrossMargin, _orderSide, _orderType, _stopType, _marginTokenIndex, _orderMargin, _triggerPrice);

        try diamondOrderFacet.batchCreateOrderRequest{value: orderParamsHelper.ethValue}(params)returns(uint256[] memory orderIds) {
            __after(msg.sender, oracles); // Update the contract state tracker

            // Add to orderRequest Queue
            OrderExecutions memory execution;
            for(uint256 i = 0; i < orderIds.length; i++) {
                execution = OrderExecutions(msg.sender, orderIds[i], false);
                _keeperExecutions.orderExecutions.push(execution);
            }
            
        }catch{

            // Do something
        }
    }


    ////////// PositionFacet //////////

    /**
    
    struct KeeperExecutions {
        OrderExecutions[] orderExecutions;
        AccountWithdrawExecutions[] accountWithdrawExecutions;
        CancelWithdrawExecutions[] cancelWithdrawExecutions;
    }
    
    KeeperExecutions internal _keeperExecutions;

    */
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
