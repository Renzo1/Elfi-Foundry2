
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "./BeforeAfter.sol";
import {Properties} from "./Properties.sol";
import {vm} from "@chimera/Hevm.sol";

import "src/process/OracleProcess.sol";
import "src/interfaces/IOrder.sol";
import "src/interfaces/IStake.sol";
import "src/interfaces/IPosition.sol";



abstract contract TargetFunctions is BaseTargetFunctions, Properties, BeforeAfter {
    /////////////////////////////////////////
    //// Utility functions & Modifiers //////
    /////////////////////////////////////////

    ///////// OracleProcess /////////
    // struct OracleParam {
    //     address token;
    //     address targetToken;
    //     int256 minPrice;
    //     int256 maxPrice;
    // }
    
    struct FuzzOracleParam {
        OracleProcess.OracleParam[] oracles;
    }

    FuzzOracleParam internal _oraclesParams;

    modifier setOracleParam(uint16 _answer) {

      uint256 wethPrice = uint256(((_answer % 5_000) + 900) * 1e8);
      uint256 btcPrice = uint256(((_answer % 40_000) + 20_000) * 1e8);

      address[] memory tokens = new address[](2);

      tokens[0] = address(weth);
      tokens[1] = address(wbtc);

    //   OracleProcess.OracleParam[] oracles_ = new OracleProcess.OracleParam[](tokens.length);
        _oraclesParams.oracles = new OracleProcess.OracleParam[](tokens.length);


      for(uint256 i = 0; i < tokens.length; i++) {
        _oraclesParams.oracles[i].token = tokens[i];
        if(tokens[i] == address(weth)) {
            _oraclesParams.oracles[i].minPrice = int256(wethPrice);
            _oraclesParams.oracles[i].maxPrice = int256(wethPrice);    
        } else{
            _oraclesParams.oracles[i].minPrice = int256(btcPrice);
            _oraclesParams.oracles[i].maxPrice = int256(btcPrice);  
        }
      }

      _;
    }

    //////////////////////////////////////
    //// Keeper Execution Modifiers //////
    //////////////////////////////////////

    struct KeeperExecutions {
        ExecutionOrders[] orderExecutions;
    }

    KeeperExecutions internal _keeperExecutions;

    /**
    delay variation of execution modifiers
    */
    /////////// executeOrder ///////////
    struct ExecutionOrders {
        uint256 orderId;
        OracleProcess.OracleParam[] oracles;
    }

    modifier executeOrder() {
        // Execute the function first
        _;

        // for each orders in the queue (KeeperExecutions.orderExecutions)

        // Execute the order
        // diamondOrderFacet.executeOrder(ExecutionOrders.orderId, ExecutionOrders.oracles);

        // Remove the order from the queue (KeeperExecutions.orderExecutions)
    }


    /////////// executeWithdraw ///////////
    modifier accountFacet_executeWithdraw(uint256 requestId) {
        _;

        OracleProcess.OracleParam[] memory oracles;
        diamondAccountFacet.executeWithdraw(requestId, oracles);
    }
  
    /////////// executeUpdatePositionMarginRequest ///////////
    modifier positionFacet_executeUpdatePositionMarginRequest() {
        _;

        uint256 requestId;
        OracleProcess.OracleParam[] memory oracles;
        diamondPositionFacet.executeUpdatePositionMarginRequest(requestId, oracles);
    }


    /////////// executeUpdateLeverageRequest ///////////
    modifier positionFacet_executeUpdateLeverageRequest() {
        _;

        uint256 requestId; 
        OracleProcess.OracleParam[] calldata oracles;
        diamondPositionFacet.executeUpdateLeverageRequest(requestId, oracles);
    }
    
    
    /////////// executeMintStakeToken ///////////
    modifier stakeFacet_executeMintStakeToken() {
        _;

        uint256 requestId; 
        OracleProcess.OracleParam[] calldata oracles;
        diamondStakeFacet.executeMintStakeToken(requestId, oracles);
    }
    

    /////////// executeRedeemStakeToken ///////////
    modifier stakeFacet_executeRedeemStakeToken() {
        _;

        uint256 requestId; 
        OracleProcess.OracleParam[] calldata oracles;
        diamondStakeFacet.executeRedeemStakeToken(requestId, oracles);
    }

    ///////////////////////////
    //// Wrapper functions ////
    ///////////////////////////

    ////////// AccountFacet //////////
    
    /// deposit
    function accountFacet_deposit(address token, uint256 amount) public {
        diamondAccountFacet.deposit(token, amount);
    }

    /// createWithdrawRequest
    function accountFacet_createWithdrawRequest(address token, uint256 amount) public {
        diamondAccountFacet.createWithdrawRequest(token, amount);
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





    //////////// Keeper Delays //////////
}
