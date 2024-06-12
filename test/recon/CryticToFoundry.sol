
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {TargetFunctions} from "./TargetFunctions.sol";
import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";

contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        setup();
    }

    /// Stakers Story
    function testStakeAndRedeemCoverage() public {
        // Create Mint Params
        uint256 _answer = 65000;
        uint256 _stakeTokenIndex = 0;
        uint256 _requestTokenIndex = 0;
        uint256 _requestTokenAmount = 100e18;
        uint256 _walletRequestTokenAmount = 100e18;
        uint256 _minStakeAmount = 0;
        bool _isCollateral = false;
        bool _isNativeToken = false;

        // Cancel Mint Params
        uint256 _requestIndex = 0;

        // Create Redeem Params
        uint256 _redeemTokenIndex = 0;
        uint256 _redeemRequestTokenAmount = 50e18;
        uint256 _unStakeAmount = 50e18;
        uint256 _minRedeemAmount = 0;

        vm.prank(USERS[0]);
        stakeFacet_createMintStakeTokenRequest(_answer, _stakeTokenIndex, _requestTokenIndex, _requestTokenAmount, _walletRequestTokenAmount, _minStakeAmount, _isCollateral, _isNativeToken);
        vm.prank(USERS[1]);
        stakeFacet_createMintStakeTokenRequest(_answer, _stakeTokenIndex, _requestTokenIndex, _requestTokenAmount, _walletRequestTokenAmount, _minStakeAmount, _isCollateral, _isNativeToken);
        stakeFacet_executeMintStakeToken(_answer);
        stakeFacet_cancelMintStakeToken(_requestIndex, _answer);
        
        vm.prank(USERS[0]);
        stakeFacet_createRedeemStakeTokenRequest(_answer, _stakeTokenIndex, _redeemTokenIndex, _redeemRequestTokenAmount, _unStakeAmount, _minRedeemAmount);
        stakeFacet_executeRedeemStakeToken(_answer);
        stakeFacet_cancelRedeemStakeToken(_requestIndex, _answer);

        t(true, "passed");
    }
    
    // function executeOrder(uint16 _answer) public {}

    // function orderFacet_cancelOrder(uint8 _requestIndex, uint16 _answer) public {}

    // function accountFacet_executeWithdraw(uint16 _answer) public{}

    // function accountFacet_cancelWithdraw(uint8 _requestIndex, uint16 _answer) public {}

    // function positionFacet_executeUpdatePositionMarginRequest(uint16 _answer) public{}

    // function positionFacet_cancelUpdatePositionMarginRequest(uint8 _requestIndex, uint16 _answer) public {}

    // function positionFacet_executeUpdateLeverageRequest(uint16 _answer) public{}

    // function positionFacet_cancelUpdateLeverageRequest(uint8 _requestIndex, uint16 _answer) public {}

    // function positionFacet_autoReducePositions(uint16 _answer) internal {}

    // function accountFacet_deposit(uint8 _tokenIndex, uint96 _amount, bool _sendEth, bool _onlyEth, uint96 _ethValue, uint16 _answer) public{}

    // function accountFacet_createWithdrawRequest(uint8 _tokenIndex, uint96 _amount, uint16 _answer) public {}

    // function orderFacet_createOrderRequest(
    //         uint16 _answer, 
    //         bool _isCrossMargin, 
    //         bool _isNativeToken,
    //         uint8 _orderSide, 
    //         uint8 _positionSide,
    //         uint8 _orderType,
    //         uint8 _stopType,
    //         uint8 _marginTokenIndex,
    //         uint96 _qty,
    //         uint96 _orderMargin,
    //         uint96 _leverage,
    //         uint64 _triggerPrice
    //     ) public {}

    // function _createBatchOrders(
    //     uint256 _numOrders, 
    //     OracleProcess.OracleParam[] memory oracles, 
    //     bool _isCrossMargin, 
    //     uint8 _orderSide,
    //     uint8 _orderType,
    //     uint8 _stopType,
    //     uint8 _marginTokenIndex,
    //     uint96 _orderMargin,
    //     uint64 _triggerPrice
    // ) internal returns(IOrder.PlaceOrderParams[] memory orderParams, uint256 totalEthValue) {}

    // function orderFacet_batchCreateOrderRequest(
    //     uint16 _answer,
    //     uint8 _numOrders, 
    //     bool _isCrossMargin, 
    //     uint8 _orderSide, 
    //     uint8 _orderType, 
    //     uint8 _stopType,
    //     uint8 _marginTokenIndex,
    //     uint96 _orderMargin,
    //     uint64 _triggerPrice
    // ) public {}

    // function positionFacet_createUpdatePositionMarginRequest(uint16 _answer, bool _isAdd, bool _isNativeToken, uint8 _tokenIndex, uint96 _updateMarginAmount) public {}

    // function positionFacet_createUpdateLeverageRequest(uint16 _answer, bool _isLong, bool _isNativeToken, uint8 _tokenIndex, uint96 _addMarginAmount, uint96 _leverage ) public {}


}
