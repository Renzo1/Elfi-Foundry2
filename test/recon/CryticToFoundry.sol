
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {TargetFunctions} from "./TargetFunctions.sol";
import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";
import "../constants/TradeConfig.sol";
import "src/mock/MockToken.sol";

import "src/process/OracleProcess.sol";
import "src/interfaces/IOrder.sol";
import "src/storage/Order.sol";
import "src/interfaces/IStake.sol";
import "src/interfaces/IPosition.sol";
import "src/mock/MockToken.sol";
import "src/storage/RoleAccessControl.sol";
import "src/utils/Errors.sol";
import "src/utils/TransferUtils.sol";
import "src/utils/CalUtils.sol";
import "src/utils/AddressUtils.sol";
import "src/vault/Vault.sol";

import "../constants/ChainConfig.sol";
import "../constants/MarketConfig.sol";
import "../constants/RolesAndPools.sol";
import "../constants/StakeConfig.sol";
import "../constants/TradeConfig.sol";
import "../constants/UsdcTradeConfig.sol";
import "../constants/WbtcTradeConfig.sol";
import "../constants/WethTradeConfig.sol";

contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    address userContract = address(this);

    function setUp() public {
        setup();
    }

    function _mintStakeTokenRequest() internal {
        // Create Mint Params
        uint256 _answer = 50_000;
        BeforeAfterParamHelper memory beAfParams;
        IStake.MintStakeTokenParams memory params;
        beAfParams.oracles = getOracleParam(_answer);

        /// createOrder params setup
        params.stakeToken = stakedTokens[0];
        params.requestToken = address(weth);
        params.requestTokenAmount = 1000e18;
        params.walletRequestTokenAmount = 1000e18;
        params.minStakeAmount = 0;
        params.executionFee = ChainConfig.getMintGasFeeLimit();
        params.isCollateral = false;
        params.isNativeToken = false;

        uint256 requestId = diamondStakeFacet.createMintStakeTokenRequest{value: params.executionFee}(params);
        diamondStakeFacet.executeMintStakeToken(requestId, beAfParams.oracles);
        console2.log("Keeper Mint StakeToken requestId", requestId);
    }

    // forge test --match-test testCreateOrderRequest
    function testCreateOrderRequest() public {
        uint256 _answer = 50_000;
        BeforeAfterParamHelper memory beAfParams;
        IOrder.PlaceOrderParams memory params;
        beAfParams.oracles = getOracleParam(_answer);


        /// createOrder params setup
        params.symbol = MarketConfig.getWethSymbol();
        params.isCrossMargin = false;
        params.isNativeToken = false;
        params.orderSide = Order.Side.LONG;
        params.posSide = Order.PositionSide.INCREASE;
        params.orderType = Order.Type.MARKET;
        params.stopType = Order.StopType.NONE;
        params.marginToken = tokens[0];
        params.qty = 0;
        params.orderMargin = 10e18;
        params.leverage = MarketConfig.getMaxLeverage() / 2;
        params.triggerPrice = 0; // triggerPrice 
        params.acceptablePrice = uint256(beAfParams.oracles[0].maxPrice);
        params.executionFee = ChainConfig.getPlaceIncreaseOrderGasFeeLimit();
        params.placeTime = block.timestamp;

        /// BeforAfter params setup
        // beAfParams.stakeToken = params.stakeToken;
        // beAfParams.token = params.marginToken;
        // beAfParams.code = params.code;
        
        __before(USERS[0], beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);
        vm.prank(USERS[0]);
        uint256 orderId = diamondOrderFacet.createOrderRequest{value: params.executionFee}(params);
        __after(USERS[0], beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);

        _mintStakeTokenRequest();
        diamondOrderFacet.executeOrder(orderId, beAfParams.oracles);

        console2.log("orderId", orderId);
        t(true, "Test Passed!");
    }

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
    // forge test --match-test testBatchCreateOrderRequest
    // function testBatchCreateOrderRequest() public {
    //     uint256 _answer = 50_000;
    //     BeforeAfterParamHelper memory beAfParams;
    //     OrderParamsHelper memory orderParamsHelper;
    //     IOrder.PlaceOrderParams[] memory params = new IOrder.PlaceOrderParams[](5);
    //     IOrder.PlaceOrderParams memory params_item;
    //     beAfParams.oracles = getOracleParam(_answer);
        
    //     for(uint256 i = 0; i < params.length; i++) {
    //         /// createOrder params setup
    //         params_item.symbol = MarketConfig.getWethSymbol();
    //         params_item.isCrossMargin = false;
    //         params_item.isNativeToken = false;
    //         params_item.orderSide = Order.Side.LONG;
    //         params_item.posSide = Order.PositionSide.DECREASE;
    //         params_item.orderType = Order.Type.MARKET;
    //         params_item.stopType = Order.StopType.NONE;
    //         params_item.marginToken = tokens[0];
    //         params_item.qty = 100;
    //         params_item.orderMargin = 10e18;
    //         params_item.leverage = MarketConfig.getMaxLeverage() / 2;
    //         params_item.triggerPrice = 0; // triggerPrice 
    //         params_item.acceptablePrice = uint256(beAfParams.oracles[0].maxPrice);
    //         params_item.executionFee = ChainConfig.getPlaceIncreaseOrderGasFeeLimit();
    //         params_item.placeTime = block.timestamp;

    //         params[i] = params_item;
    //         orderParamsHelper.ethValue += params_item.executionFee;
    //     }

    //     __before(USERS[0], beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);
    //     vm.prank(USERS[0]);
    //     uint256[] memory orderIds = diamondOrderFacet.batchCreateOrderRequest{value: orderParamsHelper.ethValue}(params);
    //     __after(USERS[0], beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);

    //     params[0].isCrossMargin = true;
    //     vm.prank(USERS[0]);
    //     uint256 orderId = diamondOrderFacet.createOrderRequest{value: params[0].executionFee}(params[0]);

    //     _mintStakeTokenRequest();
    //     diamondOrderFacet.executeOrder(orderId, beAfParams.oracles);

    //     diamondOrderFacet.executeOrder(orderIds[0], beAfParams.oracles);

    //     console2.log("Batch Create First OrderId", orderIds[0]);
    //     console2.log("Batch Create Last OrderId", orderIds[orderIds.length - 1]);
    //     t(true, "Test Passed!");
    // }


    // forge test --match-test testMintStakeTokenRequest
    function testMintStakeTokenRequest() public {

        // Create Mint Params
        uint256 _answer = 50_000;
        BeforeAfterParamHelper memory beAfParams;
        IStake.MintStakeTokenParams memory params;
        beAfParams.oracles = getOracleParam(_answer);

        /// createOrder params setup
        params.stakeToken = stakedTokens[0];
        params.requestToken = address(weth);
        params.requestTokenAmount = 1000e18;
        params.walletRequestTokenAmount = 1000e18;
        params.minStakeAmount = 0;
        params.executionFee = ChainConfig.getMintGasFeeLimit();
        params.isCollateral = false;
        params.isNativeToken = false;

        /// BeforAfter params setup
        // beAfParams.stakeToken = params.stakeToken;
        // beAfParams.token = params.marginToken;
        // beAfParams.code = params.code;


        __before(USERS[0], beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);
        uint256 requestId = diamondStakeFacet.createMintStakeTokenRequest{value: params.executionFee}(params);
        __after(USERS[0], beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);

        vm.prank(keeper);
        diamondStakeFacet.executeMintStakeToken(requestId, beAfParams.oracles);

        console2.log("requestId", requestId);
        t(true, "Test Passed!");
    }


    // forge test --match-test testRedeemStakeTokenRequest
    function testRedeemStakeTokenRequest() public {
        testMintStakeTokenRequest();

        // Create Mint Params
        uint256 _answer = 50_000;
        BeforeAfterParamHelper memory beAfParams;
        IStake.RedeemStakeTokenParams memory params;
        beAfParams.oracles = getOracleParam(_answer);

        params.receiver = USERS[0];
        params.stakeToken = stakedTokens[0];
        params.redeemToken = address(weth);
        params.unStakeAmount = 100e18;
        params.minRedeemAmount = 0;
        params.executionFee = ChainConfig.getRedeemGasFeeLimit();

        __before(USERS[0], beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);
        uint256 requestId = diamondStakeFacet.createRedeemStakeTokenRequest{value: params.executionFee}(params);
        __after(USERS[0], beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);

        diamondStakeFacet.executeRedeemStakeToken(requestId, beAfParams.oracles);

        console2.log("requestId", requestId);
        t(true, "Test Passed!");
    }


    // forge test --match-test testCreateUpdateLeverageRequest
    function testCreateUpdateLeverageRequest() public {
        testCreateOrderRequest();

        // Create Mint Params
        uint256 _answer = 50_000;
        BeforeAfterParamHelper memory beAfParams;
        IPosition.UpdateLeverageParams memory params;
        beAfParams.oracles = getOracleParam(_answer);

        params.symbol = MarketConfig.getWethSymbol();
        params.isLong = true;
        params.isNativeToken = false;
        params.isCrossMargin = false;
        params.leverage =  MarketConfig.getMaxLeverage() / 4;
        params.marginToken = address(weth);
        params.addMarginAmount = 50e18;
        params.executionFee = ChainConfig.getPositionUpdateLeverageGasFeeLimit();

        __before(USERS[0], beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);
        vm.prank(keeper);
        uint256 requestId = diamondPositionFacet.createUpdateLeverageRequest{value: params.executionFee}(params);
        __after(USERS[0], beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);

        diamondPositionFacet.executeUpdateLeverageRequest(requestId, beAfParams.oracles);

        console2.log("Leverage Update requestId", requestId);
        t(true, "Test Passed!");
    }

    // forge test --match-test testCreateUpdateMarginRequest
    function testCreateUpdateMarginRequest() public {
        testCreateOrderRequest();

        // Create Mint Params
        uint256 _answer = 50_000;
        BeforeAfterParamHelper memory beAfParams;
        IPosition.UpdatePositionMarginParams memory params;
        beAfParams.oracles = getOracleParam(_answer);
        __before(USERS[0], beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);

        params.positionKey = _before.positionKey[0];
        params.isAdd = true;
        params.isNativeToken = false;
        params.marginToken = address(weth);
        params.updateMarginAmount = 50e18;
        params.executionFee = ChainConfig.getPositionUpdateMarginGasFeeLimit();

        vm.prank(USERS[0]);
        uint256 requestId = diamondPositionFacet.createUpdatePositionMarginRequest{value: params.executionFee}(params);
        __after(USERS[0], beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);

        diamondPositionFacet.executeUpdatePositionMarginRequest(requestId, beAfParams.oracles);

        console2.log("Margin Update requestId", requestId);
        t(true, "Test Passed!");
    }

    

    
}
