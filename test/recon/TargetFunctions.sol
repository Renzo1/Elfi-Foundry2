
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

    //////////////////////////////////////
    //// Keeper Execution Modifiers //////
    //////////////////////////////////////

    struct KeeperExecutions {
        OrderExecutions[] orderExecutions;
        AccountWithdrawExecutions[] accountWithdrawExecutions;
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
    function accountFacet_deposit(uint8 _tokenIndex, uint256 _amount, bool _sendEth, bool _onlyEth, uint256 _ethValue, uint16 _answer) public{
        // Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        // select a random token
        uint256 tokenIndex = EchidnaUtils.clampBetween(uint256(_tokenIndex), 0, tokens.length - 1);
        address token = tokens[tokenIndex]; // select a random token

        uint256 amount = EchidnaUtils.clampBetween(_amount, 0, IERC20(token).balanceOf(msg.sender));
        
        uint256 ethValue;
        // _sendEth = false; // toggle this on for some jobs
        if(_sendEth){
            ethValue = EchidnaUtils.clampBetween(_ethValue, 0, msg.sender.balance);
            amount = ethValue;
        }else{
            ethValue = 0;
        }
        if (_sendEth && _onlyEth){ // to successfully deposit only eth
            ethValue =  EchidnaUtils.clampBetween(_ethValue, 0, msg.sender.balance);
            amount = ethValue;
            token = address(0);
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


    /**
    
    struct KeeperExecutions {
        OrderExecutions[] orderExecutions;
        AccountWithdrawExecutions[] accountWithdrawExecutions;
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

    struct AccountWithdrawExecutions {
        address account;
        uint256 requestId;
        address token;
        uint256 amount;
        bool executed;
    }


    /// createWithdrawRequest
    function accountFacet_createWithdrawRequest(uint8 _tokenIndex, uint256 _amount, uint16 _answer) public {
        // Get oracles
        OracleProcess.OracleParam[] memory oracles = getOracleParam(_answer);
        __before(msg.sender, oracles); // Update the contract state tracker

        // select a random token
        uint256 tokenIndex = EchidnaUtils.clampBetween(uint256(_tokenIndex), 0, tokens.length - 1);
        address token = tokens[tokenIndex]; // select a random token
        uint256 amount;

        if(token == address(usdc)){
            amount = EchidnaUtils.clampBetween(_amount, 0, _before.portfolioVaultUsdcBalance);
        }else if(token == address(weth)){
            amount = EchidnaUtils.clampBetween(_amount, 0, _before.portfolioVaultWethBalance);
        }else{ // wbtc
            amount = EchidnaUtils.clampBetween(_amount, 0, _before.portfolioVaultBtcBalance);
        }

        vm.prank(msg.sender); // prolly redundant
        try diamondAccountFacet.createWithdrawRequest(token, amount){
            __after(msg.sender, oracles); // Update the contract state tracker
            uint256 requestId;

            // Add to withdrawRequest Queue
            AccountWithdrawExecutions memory execution = AccountWithdrawExecutions(msg.sender, requestId, token, amount,false);
            _keeperExecutions.accountWithdrawExecutions.push(execution);

            /// Invariants assessment

            // Update the deposit tracker
            // Add tx to keeper queue orders --> KeeperExecutions.accountExecutions[]

        }catch{            
        }
    }

    /// cancelWithdraw
    function accountFacet_cancelWithdraw(uint256 requestId, bytes32 reasonCode) public {
        diamondAccountFacet.cancelWithdraw(requestId, reasonCode);
    }
  

    /// batchUpdateAccountToken
    function accountFacet_batchUpdateAccountToken(AssetsProcess.UpdateAccountTokenParams calldata params) public {
        diamondAccountFacet.batchUpdateAccountToken(params);
    }
  

    ////////// OrderFacet //////////

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

    //////////// Frontrunners //////////


}
