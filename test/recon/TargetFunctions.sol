
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "./BeforeAfter.sol";
import {Properties} from "./Properties.sol";
import {vm} from "@chimera/Hevm.sol";
import {EchidnaUtils} from "../utils/EchidnaUtils.sol";
import {Debugger} from "../utils/Debugger.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

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


abstract contract TargetFunctions is BaseTargetFunctions, Properties, BeforeAfter {
    using Strings for string;

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

    ///////// DoS Catcher /////////

    // used to filter for allowed text errors during functions
    // if a function fails with an error that is not allowed,
    // this can indicate a potential DoS attack vector
    event UnexpectedTextError(string);
    function _assertTextErrorsAllowed(string memory err, string[] memory allowedErrors) private {
        bool allowed;
        uint256 allowedErrorsLength = allowedErrors.length;

        for (uint256 i; i < allowedErrorsLength;) {
            if (err.equal(allowedErrors[i])) {
                allowed = true;
                break;
            }
            unchecked {++i;}
        }

        if(!allowed) {
            emit UnexpectedTextError(err);
            assert(false);
        }
    }

    // used to filter for allowed custom errors during functions
    // if a function fails with an error that is not allowed,
    // this can indicate a potential DoS attack vector
    event UnexpectedCustomError(bytes);
    function _assertCustomErrorsAllowed(bytes memory err, bytes4[] memory allowedErrors) private {
        bool allowed;
        bytes4 errorSelector = bytes4(err);
        uint256 allowedErrorsLength = allowedErrors.length;

        for (uint256 i; i < allowedErrorsLength;) {
            if (errorSelector == allowedErrors[i]) {
                allowed = true;
                break;
            }
            unchecked {++i;}
        }

        if(!allowed) {
            emit UnexpectedCustomError(err);
            assert(false);
        }
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
        bytes32 positionKey;
        bool isAdd;
        bool isNativeToken;
        uint256 updateMarginAmount;
        uint256 executionFee;
        bool executed;
    }

    struct CanceledPositionMarginRequests {
        address account;
        uint256 requestId;
        bytes32 positionKey;
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

    struct BeforeAfterParamHelper{
        OracleProcess.OracleParam[] oracles;
        address stakeToken;
        address collateralToken;
        address token; 
        bytes32 code;
    }

    function executeOrder(uint256 _answer) public {
        // Get oracles
        BeforeAfterParamHelper memory beAfParams;
        beAfParams.oracles = getOracleParam(_answer);

        
        OrderExecutions memory request;
        address account;
        uint256 requestId;
        
        for (uint256 i = 0; i < _keeperExecutions.orderExecutions.length; i++) {
            request = _keeperExecutions.orderExecutions[i];
            account = request.account;
            requestId = request.orderId;
            
            __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 
            

            if(!request.executed){
                vm.prank(keeper);
                try diamondOrderFacet.executeOrder(requestId, beAfParams.oracles){
                    __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 
                    _keeperExecutions.orderExecutions[i].executed = true;
    
                    
                    
                    /// Invariants assessment
    
    
                }
                
                /// handle `require` text-based errors
                catch Error(string memory err) {
                    
                    string[] memory allowedErrors = new string[](1);
                    allowedErrors[0] = "STE";

                    _assertTextErrorsAllowed(err, allowedErrors);
                    _keeperExecutions.orderExecutions[i].executed = true;
                }

                /// handle custom errors
                catch(bytes memory err) {

                    bytes4[] memory allowedErrors = new bytes4[](13);
                    allowedErrors[0] = RoleAccessControl.InvalidRoleAccess.selector;
                    allowedErrors[1] = Errors.OrderNotExists.selector;
                    allowedErrors[2] = Errors.SymbolStatusInvalid.selector;
                    allowedErrors[3] = Errors.TokenInvalid.selector;
                    allowedErrors[4] = Errors.LeverageInvalid.selector;
                    allowedErrors[5] = Errors.OnlyOneShortPositionSupport.selector;
                    allowedErrors[6] = Errors.DecreaseOrderSideInvalid.selector;
                    allowedErrors[7] = Errors.ExecutionPriceInvalid.selector;
                    allowedErrors[8] = Errors.PositionShouldBeLiquidation.selector;
                    allowedErrors[9] = Errors.TransferErrorWithVaultBalanceNotEnough.selector;
                    allowedErrors[10] = Vault.AddressSelfNotSupported.selector;
                    allowedErrors[11] = TransferUtils.TokenTransferError.selector;
                    allowedErrors[12] = Errors.PriceIsZero.selector;

                    _assertCustomErrorsAllowed(err, allowedErrors);

                    _keeperExecutions.orderExecutions[i].executed = true;
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
        BeforeAfterParamHelper memory beAfParams;
        beAfParams.oracles = getOracleParam(_answer);
        
        
        __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

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

        if (openRequests.length == 0) {
            return;
        }

        /// select a random request from the list
        uint256 requestIndex = EchidnaUtils.clampBetween(_requestIndex, 0, openRequests.length - 1);
        OrderExecutions memory request = openRequests[requestIndex];
        requestId = request.orderId;

        vm.prank(msg.sender); 
        try diamondOrderFacet.cancelOrder(requestId, ""){
            __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

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


        }   
        
        /// handle `require` text-based errors
        catch Error(string memory err) {
            string[] memory allowedErrors = new string[](1);
            allowedErrors[0] = "orderHoldInUsd is smaller than holdInUsd";

            _assertTextErrorsAllowed(err, allowedErrors);
        }

        /// handle custom errors
        catch(bytes memory err) {
            bytes4[] memory allowedErrors = new bytes4[](4);
            allowedErrors[0] = Errors.OrderNotExists.selector;
            allowedErrors[1] = Errors.TransferErrorWithVaultBalanceNotEnough.selector;
            allowedErrors[2] = Vault.AddressSelfNotSupported.selector;
            allowedErrors[3] = TransferUtils.TokenTransferError.selector;

            _assertCustomErrorsAllowed(err, allowedErrors);
        }
    }

    /////////// executeWithdraw ///////////
    function accountFacet_executeWithdraw(uint256 _answer) public{
        // Get oracles
        BeforeAfterParamHelper memory beAfParams;
        beAfParams.oracles = getOracleParam(_answer);
        
        
        
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
            
           __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

            if(!request.executed){
                vm.prank(keeper);
                try diamondAccountFacet.executeWithdraw(requestId, beAfParams.oracles){
                    __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 
                    _keeperExecutions.accountWithdrawExecutions[i].executed = true;
    
                    // Update the withdrawal tracker; Remember to factor in transaction fee when calculating with this
                    _txsTracking.processedWithdrawals[account][token] += amount;
    
                    
                    /// Invariants assessment
    
    
    
                }

                /// handle `require` text-based errors
                catch Error(string memory err) {
                    
                    // require(self.tokens.contains(token), "token not exists!");
                    // require(self.tokenBalances[token].amount >= amount, "token amount not enough!");
                    string[] memory allowedErrors = new string[](2);
                    allowedErrors[0] = "token not exists!";
                    allowedErrors[1] = "token amount not enough!";

                    _assertTextErrorsAllowed(err, allowedErrors);
                    _keeperExecutions.accountWithdrawExecutions[i].executed = true;
                }

                /// handle custom errors
                catch(bytes memory err) {
                    
                    bytes4[] memory allowedErrors = new bytes4[](9);
                    allowedErrors[0] = Errors.WithdrawRequestNotExists.selector;
                    allowedErrors[1] = RoleAccessControl.InvalidRoleAccess.selector;
                    allowedErrors[2] = Errors.AmountZeroNotAllowed.selector;
                    allowedErrors[3] = Errors.OnlyCollateralSupported.selector;
                    allowedErrors[4] = Errors.WithdrawWithNoEnoughAmount.selector;
                    allowedErrors[5] = Errors.TransferErrorWithVaultBalanceNotEnough.selector;
                    allowedErrors[6] = Vault.AddressSelfNotSupported.selector;
                    allowedErrors[7] = TransferUtils.TokenTransferError.selector;
                    allowedErrors[8] = Errors.PriceIsZero.selector;

                    
                    _assertCustomErrorsAllowed(err, allowedErrors);
                    _keeperExecutions.accountWithdrawExecutions[i].executed = true;
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
        BeforeAfterParamHelper memory beAfParams;
        beAfParams.oracles = getOracleParam(_answer);
        
        
        __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

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

        if (openRequests.length == 0) {
            return;
        }

        /// select a random request from the list
        uint256 requestIndex = EchidnaUtils.clampBetween(_requestIndex, 0, openRequests.length - 1);
        AccountWithdrawExecutions memory request = openRequests[requestIndex];
        requestId = request.requestId;

        vm.prank(keeper); 
        try diamondAccountFacet.cancelWithdraw(requestId, ""){
            __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

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



        }
                     
        // /// handle `require` text-based errors
        // catch Error(string memory err) {
        //     string[] memory allowedErrors = new string[](1);
        //     allowedErrors[0] = "First error";

        //     _assertTextErrorsAllowed(err, allowedErrors);
        // }

        /// handle custom errors
        catch(bytes memory err) {
            bytes4[] memory allowedErrors = new bytes4[](2);
            allowedErrors[0] = RoleAccessControl.InvalidRoleAccess.selector;
            allowedErrors[1] = Errors.WithdrawRequestNotExists.selector;

            _assertCustomErrorsAllowed(err, allowedErrors);
        }
    }


    /////////// executeUpdatePositionMarginRequest ///////////
    function positionFacet_executeUpdatePositionMarginRequest(uint256 _answer) public{
        // Get oracles
        BeforeAfterParamHelper memory beAfParams;
        beAfParams.oracles = getOracleParam(_answer);
        
        
        
        PositionMarginRequests memory request;
        address account;
        uint256 requestId;
        
        for (uint256 i = 0; i < _keeperExecutions.positionMarginRequests.length; i++) {
            request = _keeperExecutions.positionMarginRequests[i];
            account = request.account;
            requestId = request.requestId;
            
           __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

            if(!request.executed){
                vm.prank(keeper);
                try diamondPositionFacet.executeUpdatePositionMarginRequest(requestId, beAfParams.oracles){
                    __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 
                    _keeperExecutions.positionMarginRequests[i].executed = true;
    
                    
                    
                    /// Invariants assessment
    
    
    
                } 



                /// handle `require` text-based errors
                catch Error(string memory err) {
                    
                    string[] memory allowedErrors = new string[](3);
                    allowedErrors[0] = "hold failed with balance not enough";
                    allowedErrors[1] = "sub hold bigger than hold";
                    allowedErrors[2] = "STE";

                    _assertTextErrorsAllowed(err, allowedErrors);
                    _keeperExecutions.positionMarginRequests[i].executed = true;
                }

                /// handle custom errors
                catch(bytes memory err) {
                    
                    bytes4[] memory allowedErrors = new bytes4[](12);
                    allowedErrors[0] = Errors.UpdatePositionMarginRequestNotExists.selector;
                    allowedErrors[1] = Errors.OnlyIsolateSupported.selector;
                    allowedErrors[2] = Errors.TokenIsNotSupport.selector;
                    allowedErrors[3] = Errors.AddMarginTooBig.selector;
                    allowedErrors[4] = Errors.TransferErrorWithVaultBalanceNotEnough.selector;
                    allowedErrors[5] = Vault.AddressSelfNotSupported.selector;
                    allowedErrors[6] = Errors.ReduceMarginTooBig.selector;
                    allowedErrors[7] = Errors.PoolAmountNotEnough.selector;
                    allowedErrors[8] = RoleAccessControl.InvalidRoleAccess.selector;
                    allowedErrors[9] = Errors.PositionNotExists.selector;
                    allowedErrors[10] = Errors.PriceIsZero.selector;
                    allowedErrors[11] = TransferUtils.TokenTransferError.selector;
                    
                    _assertCustomErrorsAllowed(err, allowedErrors);
                    _keeperExecutions.positionMarginRequests[i].executed = true;
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
        BeforeAfterParamHelper memory beAfParams;
        beAfParams.oracles = getOracleParam(_answer);
        
        
        __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

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

        if (openRequests.length == 0) {
            return;
        }

        /// select a random request from the list
        uint256 requestIndex = EchidnaUtils.clampBetween(_requestIndex, 0, openRequests.length - 1);
        PositionMarginRequests memory request = openRequests[requestIndex];
        requestId = request.requestId;

        vm.prank(keeper); 
        try diamondPositionFacet.cancelUpdatePositionMarginRequest(requestId, ""){
            __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

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
            // Add tx to keeper queue orders --> KeeperExecutions.accountExecutions[]✅

        }
                     
        // /// handle `require` text-based errors
        // catch Error(string memory err) {
        //     string[] memory allowedErrors = new string[](1);
        //     allowedErrors[0] = "First error";

        //     _assertTextErrorsAllowed(err, allowedErrors);
        // }

        /// handle custom errors
        catch(bytes memory err) {
            bytes4[] memory allowedErrors = new bytes4[](5);
            allowedErrors[0] = RoleAccessControl.InvalidRoleAccess.selector;
            allowedErrors[1] = Errors.UpdatePositionMarginRequestNotExists.selector;
            allowedErrors[2] = Errors.TransferErrorWithVaultBalanceNotEnough.selector;
            allowedErrors[3] = Vault.AddressSelfNotSupported.selector;
            allowedErrors[4] = TransferUtils.TokenTransferError.selector;

            _assertCustomErrorsAllowed(err, allowedErrors);
        }
    }

    /////////// executeUpdateLeverageRequest ///////////
    function positionFacet_executeUpdateLeverageRequest(uint256 _answer) public{
        // Get oracles
        BeforeAfterParamHelper memory beAfParams;
        beAfParams.oracles = getOracleParam(_answer);
        
        
        
        PositionLeverageRequests memory request;
        address account;
        uint256 requestId;
        
        for (uint256 i = 0; i < _keeperExecutions.positionLeverageRequests.length; i++) {
            request = _keeperExecutions.positionLeverageRequests[i];
            account = request.account;
            requestId = request.requestId;
            
           __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

            if(!request.executed){
                vm.prank(keeper);
                try diamondPositionFacet.executeUpdateLeverageRequest(requestId, beAfParams.oracles){
                    __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 
                    _keeperExecutions.positionLeverageRequests[i].executed = true;
    
                    
                    
                    /// Invariants assessment
    
    
    
                }
                
                
                /// handle `require` text-based errors
                catch Error(string memory err) {

                    string[] memory allowedErrors = new string[](7);
                    allowedErrors[0] = "token not exists!";
                    allowedErrors[1] = "unUse overflow!";
                    allowedErrors[2] = "hold failed with balance not enough";
                    allowedErrors[3] = "STE";
                    allowedErrors[4] = "sub hold bigger than hold";
                    allowedErrors[5] = "base token amount less than sub amount!";
                    allowedErrors[6] = "stable token not supported!";
                    
                    _assertTextErrorsAllowed(err, allowedErrors);
                    _keeperExecutions.positionLeverageRequests[i].executed = true;
                }
                
                /// handle custom errors
                catch(bytes memory err) {
           
                    bytes4[] memory allowedErrors = new bytes4[](11);
                    allowedErrors[0] = Errors.UpdateLeverageRequestNotExists.selector;
                    allowedErrors[1] = Errors.UpdateLeverageWithNoChange.selector;
                    allowedErrors[2] = Errors.BalanceNotEnough.selector;
                    allowedErrors[3] = Errors.PoolAmountNotEnough.selector;
                    allowedErrors[4] = Errors.TransferErrorWithVaultBalanceNotEnough.selector;
                    allowedErrors[5] = Errors.ReduceMarginTooBig.selector;
                    allowedErrors[6] = RoleAccessControl.InvalidRoleAccess.selector;
                    allowedErrors[7] = Errors.PriceIsZero.selector;
                    allowedErrors[8] = Errors.AddMarginTooBig.selector;
                    allowedErrors[9] = TransferUtils.TokenTransferError.selector;
                    allowedErrors[10] = Vault.AddressSelfNotSupported.selector;

                    _assertCustomErrorsAllowed(err, allowedErrors);
                    _keeperExecutions.positionLeverageRequests[i].executed = true;
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
        BeforeAfterParamHelper memory beAfParams;
        beAfParams.oracles = getOracleParam(_answer);
        
        
        __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

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

        if (openRequests.length == 0) {
            return;
        }

        /// select a random request from the list
        uint256 requestIndex = EchidnaUtils.clampBetween(_requestIndex, 0, openRequests.length - 1);
        PositionLeverageRequests memory request = openRequests[requestIndex];
        requestId = request.requestId;

        vm.prank(keeper); 
        try diamondPositionFacet.cancelUpdateLeverageRequest(requestId, ""){
            __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

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


        }
        
        /// handle `require` text-based errors
        // catch Error(string memory err) {
        //     string[] memory allowedErrors = new string[](1);
        //     allowedErrors[0] = "First error";
            
        //     _assertTextErrorsAllowed(err, allowedErrors);
        // }
        
        // revert Vault.AddressSelfNotSupported(receiver);
        // revert TransferUtils.TokenTransferError(token, receiver, amount);
        
        /// handle custom errors
        catch(bytes memory err) {
            bytes4[] memory allowedErrors = new bytes4[](5);
            allowedErrors[0] = RoleAccessControl.InvalidRoleAccess.selector;
            allowedErrors[1] = Errors.UpdateLeverageRequestNotExists.selector;
            allowedErrors[2] = Errors.TransferErrorWithVaultBalanceNotEnough.selector;
            allowedErrors[3] = Vault.AddressSelfNotSupported.selector;
            allowedErrors[4] = TransferUtils.TokenTransferError.selector;

            _assertCustomErrorsAllowed(err, allowedErrors);
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
        BeforeAfterParamHelper memory beAfParams;
        beAfParams.oracles = getOracleParam(_answer);
        
        
        
        // collect all positionKeys for every users' position
        for(uint256 i = 0; i < USERS.length; i++) {
            __before(USERS[i], beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);
            
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
        delete _autoDecreasePositionParamsHelper.positionKeys;


        vm.prank(keeper);
        try diamondPositionFacet.autoReducePositions(positionKeys){
            __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

         
            /// Invariants assessment


        }

        /// handle `require` text-based errors
        catch Error(string memory err) {
            // string[] memory allowedErrors = new string[](5);
            // allowedErrors[0] = "token not exists!";
            // allowedErrors[1] = "unUse overflow!";
            // allowedErrors[2] = "base token amount less than sub amount!";
            // allowedErrors[3] = "sub hold bigger than hold";
            // allowedErrors[4] = "sub failed with balance not enough";

            // _assertTextErrorsAllowed(err, allowedErrors);

            emit UnexpectedTextError(err);
            assert(false);
        }

        /// handle custom errors
        catch(bytes memory err) {
            // bytes4[] memory allowedErrors = new bytes4[](7);
            // allowedErrors[0] = RoleAccessControl.InvalidRoleAccess.selector;
            // allowedErrors[1] = Errors.PositionNotExists.selector;
            // allowedErrors[2] = Errors.PriceIsZero.selector;
            // allowedErrors[3] = Errors.PositionShouldBeLiquidation.selector;
            // allowedErrors[4] = Errors.TransferErrorWithVaultBalanceNotEnough.selector;
            // allowedErrors[5] = Vault.AddressSelfNotSupported.selector;
            // allowedErrors[6] = TransferUtils.TokenTransferError.selector;

            // _assertCustomErrorsAllowed(err, allowedErrors);

            emit UnexpectedCustomError(err);
            assert(false);
        }
    }
    
    
    /////////// executeMintStakeToken ///////////

    function stakeFacet_executeMintStakeToken(uint256 _answer) public{
        // Get oracles
        BeforeAfterParamHelper memory beAfParams;
        beAfParams.oracles = getOracleParam(_answer);
        
        MintStakeRequests memory request;
        address account;
        uint256 requestId;
        
        for (uint256 i = 0; i < _keeperExecutions.mintStakeRequests.length; i++) {
            request = _keeperExecutions.mintStakeRequests[i];
            account = request.account;
            requestId = request.requestId;
            
           __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

            if(!request.executed){
                vm.prank(keeper);
                try diamondStakeFacet.executeMintStakeToken(requestId, beAfParams.oracles){
                    __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 
                    _keeperExecutions.mintStakeRequests[i].executed = true;
    
                    
                    
                    /// Invariants assessment
    
    
    
                }
                
                
                
                    // if executeWithdraw fails for invalid reasons assert false: DOS
                    // assert(false);
                    
                    
                    /// handle `require` text-based errors
                catch Error(string memory err) {
                    
                    string[] memory allowedErrors = new string[](4);
                    allowedErrors[0] = "token not exists!";
                    allowedErrors[1] = "token amount not enough!";
                    allowedErrors[2] = "stable token not supported!";
                    allowedErrors[3] = "STE";
                    
                    _assertTextErrorsAllowed(err, allowedErrors);
                    _keeperExecutions.mintStakeRequests[i].executed = true;
                }
                    
                /// handle custom errors
                catch(bytes memory err) {
                    
                    bytes4[] memory allowedErrors = new bytes4[](7);
                    allowedErrors[0] = Errors.MintWithAmountZero.selector;
                    allowedErrors[1] = Errors.MintWithParamError.selector;
                    allowedErrors[2] = Errors.MintFailedWithBalanceNotEnough.selector;
                    allowedErrors[3] = Errors.PoolValueIsZero.selector;
                    allowedErrors[4] = Errors.MintTokenInvalid.selector;
                    allowedErrors[5] = Errors.MintStakeTokenTooSmall.selector;
                    allowedErrors[6] = Errors.StakeTokenInvalid.selector;

                    _assertCustomErrorsAllowed(err, allowedErrors);
                    _keeperExecutions.mintStakeRequests[i].executed = true;
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
        BeforeAfterParamHelper memory beAfParams;
        beAfParams.oracles = getOracleParam(_answer);
        
        
        __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

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

        if (openRequests.length == 0) {
            return;
        }

        /// select a random request from the list
        uint256 requestIndex = EchidnaUtils.clampBetween(_requestIndex, 0, openRequests.length - 1);
        MintStakeRequests memory request = openRequests[requestIndex];
        requestId = request.requestId;

        vm.prank(keeper); 
        try diamondStakeFacet.cancelMintStakeToken(requestId, ""){
            __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

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

        }    

        /// handle `require` text-based errors
        catch Error(string memory err) {
            string[] memory allowedErrors = new string[](1);
            allowedErrors[0] = "STE";

            _assertTextErrorsAllowed(err, allowedErrors);
        }

        /// handle custom errors
        catch(bytes memory err) {
            bytes4[] memory allowedErrors = new bytes4[](5);
            allowedErrors[0] = RoleAccessControl.InvalidRoleAccess.selector;
            allowedErrors[1] = Errors.MintRequestNotExists.selector;
            allowedErrors[2] = Errors.TransferErrorWithVaultBalanceNotEnough.selector;
            allowedErrors[3] = TransferUtils.TokenTransferError.selector;
            allowedErrors[4] = Vault.AddressSelfNotSupported.selector;

            _assertCustomErrorsAllowed(err, allowedErrors);
        }
    }

    /////////// executeRedeemStakeToken ///////////
    function stakeFacet_executeRedeemStakeToken(uint256 _answer) public{
            // Get oracles
            BeforeAfterParamHelper memory beAfParams;
            beAfParams.oracles = getOracleParam(_answer);
        
        
            
            RedeemStakeTokenRequests memory request;
            address account;
            uint256 requestId;
            
            for (uint256 i = 0; i < _keeperExecutions.redeemStakeTokenRequests.length; i++) {
                request = _keeperExecutions.redeemStakeTokenRequests[i];
                account = request.account;
                requestId = request.requestId;
                
               __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 
    
                if(!request.executed){
                    vm.prank(keeper);
                    try diamondStakeFacet.executeMintStakeToken(requestId, beAfParams.oracles){
                        __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 
                        __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);
                        _keeperExecutions.redeemStakeTokenRequests[i].executed = true;
        
                        
                        
                        /// Invariants assessment
        
        
        
                    } 
               
                    /// handle `require` text-based errors
                    catch Error(string memory err) {
                        string[] memory allowedErrors = new string[](5);
                        allowedErrors[0] = "STE";
                        allowedErrors[1] = "usd token amount not enough";
                        allowedErrors[2] = "sub failed with balance not enough";
                        allowedErrors[3] = "base token amount less than sub amount!";
                        allowedErrors[4] = "token amount not enough";
                        
                        _assertTextErrorsAllowed(err, allowedErrors);
                        _keeperExecutions.redeemStakeTokenRequests[i].executed = true;
                    }
                    
                    /// handle custom errors
                    catch(bytes memory err) {
                        bytes4[] memory allowedErrors = new bytes4[](11);
                        allowedErrors[0] = Errors.RedeemRequestNotExists.selector;
                        allowedErrors[1] = Errors.RedeemStakeTokenTooSmall.selector;
                        allowedErrors[2] = Errors.RedeemWithAmountNotEnough.selector;
                        allowedErrors[3] = Errors.RedeemTokenInvalid.selector;
                        allowedErrors[4] = RoleAccessControl.InvalidRoleAccess.selector;
                        allowedErrors[5] = Errors.PoolAmountNotEnough.selector;
                        allowedErrors[6] = Errors.StakeTokenInvalid.selector;
                        allowedErrors[7] = Errors.TransferErrorWithVaultBalanceNotEnough.selector;
                        allowedErrors[8] = Vault.AddressSelfNotSupported.selector;
                        allowedErrors[9] = TransferUtils.TokenTransferError.selector;
                        allowedErrors[10] = Errors.PriceIsZero.selector;

                        _assertCustomErrorsAllowed(err, allowedErrors);
                        _keeperExecutions.redeemStakeTokenRequests[i].executed = true;
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
        BeforeAfterParamHelper memory beAfParams;
        beAfParams.oracles = getOracleParam(_answer);
        
        
        __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

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

        if (openRequests.length == 0) {
            return;
        }

        /// select a random request from the list
        uint256 requestIndex = EchidnaUtils.clampBetween(_requestIndex, 0, openRequests.length - 1);
        RedeemStakeTokenRequests memory request = openRequests[requestIndex];
        requestId = request.requestId;

        vm.prank(keeper); 
        try diamondStakeFacet.cancelRedeemStakeToken(requestId, ""){
            __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

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

        }   

        /// handle `require` text-based errors
        catch Error(string memory err) {
            string[] memory allowedErrors = new string[](1);
            allowedErrors[0] = "STE";

            _assertTextErrorsAllowed(err, allowedErrors);
        }

        /// handle custom errors
        catch(bytes memory err) {
            bytes4[] memory allowedErrors = new bytes4[](5);
            allowedErrors[0] = RoleAccessControl.InvalidRoleAccess.selector;
            allowedErrors[1] = Errors.RedeemRequestNotExists.selector;
            allowedErrors[2] = Vault.AddressSelfNotSupported.selector;
            allowedErrors[3] = TransferUtils.TokenTransferError.selector;
            allowedErrors[4] = Errors.TransferErrorWithVaultBalanceNotEnough.selector;

            _assertCustomErrorsAllowed(err, allowedErrors);
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
    
    /// deposit crypto token
    function accountFacet_depositCrypto(uint256 _answer, uint256 _tokenIndex, uint256 _amount) public{
        // Get oracles
        BeforeAfterParamHelper memory beAfParams;
        beAfParams.oracles = getOracleParam(_answer);
        
        // select a random token
        address token = tokens[EchidnaUtils.clampBetween(_tokenIndex, 0, tokens.length - 1)]; // select a random token
        uint256 amount = EchidnaUtils.clampBetween(_amount, 0, IERC20(token).balanceOf(msg.sender));
        uint256 ethValue = 0;
                    
        __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 
        vm.prank(msg.sender);  
        try diamondAccountFacet.deposit{value: ethValue}(token, amount){
            __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

            // Update the deposit tracker; Remember to factor in transaction fee when calculating with this
            _txsTracking.deposits[msg.sender][token] += amount;
            _txsTracking.deposits[msg.sender][ETH_ADDRESS] += ethValue;

            /// Invariants assessment
            /**
            - deposited amount should only enter portfolioVault
            */
            t(true, "accountFacet_deposit: test passed");

        }
            
        /// handle `require` text-based errors
        catch Error(string memory err) {

            string[] memory allowedErrors = new string[](3);
            allowedErrors[0] = "Deposit with token error!";
            allowedErrors[1] = "subTokenLiability less than liability";
            allowedErrors[2] = "SafeCast: value doesn't fit in an int256";
            
        _assertTextErrorsAllowed(err, allowedErrors);
        }

        /// handle custom errors
        catch(bytes memory err) {
            bytes4[] memory allowedErrors = new bytes4[](7);
            allowedErrors[0] = TransferUtils.TokenTransferError.selector;
            allowedErrors[1] = Errors.AmountZeroNotAllowed.selector;
            allowedErrors[2] = Errors.AmountNotMatch.selector;
            allowedErrors[3] = Errors.OnlyCollateralSupported.selector;
            allowedErrors[4] = Errors.TokenIsNotSupportCollateral.selector;
            allowedErrors[5] = Errors.CollateralTotalCapOverflow.selector;
            allowedErrors[6] = Errors.CollateralUserCapOverflow.selector;

            _assertCustomErrorsAllowed(err, allowedErrors);
        }
    }


    /// deposit native token
    function accountFacet_depositNative(uint256 _answer, uint256 _amount) public{
        // Get oracles
        BeforeAfterParamHelper memory beAfParams;
        beAfParams.oracles = getOracleParam(_answer);
        
        address token = address(0);
        uint256 amount = EchidnaUtils.clampBetween(_amount, 0, msg.sender.balance);
        uint256 ethValue = amount;
                    
        __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 
        vm.prank(msg.sender);  
        try diamondAccountFacet.deposit{value: ethValue}(token, amount){
            __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

            // Update the deposit tracker; Remember to factor in transaction fee when calculating with this
            _txsTracking.deposits[msg.sender][token] += 0;
            _txsTracking.deposits[msg.sender][ETH_ADDRESS] += ethValue;

            /// Invariants assessment
            /**
            - deposited amount should only enter portfolioVault
            */
            t(true, "accountFacet_deposit: test passed");

        }
            
        /// handle `require` text-based errors
        catch Error(string memory err) {

            string[] memory allowedErrors = new string[](3);
            allowedErrors[0] = "Deposit with token error!";
            allowedErrors[1] = "subTokenLiability less than liability";
            allowedErrors[2] = "SafeCast: value doesn't fit in an int256";
            
        _assertTextErrorsAllowed(err, allowedErrors);
        }

        /// handle custom errors
        catch(bytes memory err) {
            bytes4[] memory allowedErrors = new bytes4[](7);
            allowedErrors[0] = TransferUtils.TokenTransferError.selector;
            allowedErrors[1] = Errors.AmountZeroNotAllowed.selector;
            allowedErrors[2] = Errors.AmountNotMatch.selector;
            allowedErrors[3] = Errors.OnlyCollateralSupported.selector;
            allowedErrors[4] = Errors.TokenIsNotSupportCollateral.selector;
            allowedErrors[5] = Errors.CollateralTotalCapOverflow.selector;
            allowedErrors[6] = Errors.CollateralUserCapOverflow.selector;

            _assertCustomErrorsAllowed(err, allowedErrors);
        }
    }

    /// createWithdrawRequest 
    function accountFacet_createWithdrawRequest( uint256 _answer, uint256 _tokenIndex, uint256 _amount) public {
        // Get oracles
        BeforeAfterParamHelper memory beAfParams;
        beAfParams.oracles = getOracleParam(_answer);
        
        __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

        // select a random token
        address token = tokens[EchidnaUtils.clampBetween(_tokenIndex, 0, tokens.length - 1)]; // select a random token
        uint256 amount = _before.portfolioVaultUsdcBalance + _before.portfolioVaultWethBalance + _before.portfolioVaultBtcBalance;
        amount = EchidnaUtils.clampBetween(_amount, 0, amount);

        vm.prank(msg.sender);  
        try diamondAccountFacet.createWithdrawRequest(token, amount) returns(uint256 requestId){
            __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

            // Add to withdrawRequest Queue
            AccountWithdrawExecutions memory execution = AccountWithdrawExecutions(msg.sender, requestId, token, amount, false);
            _keeperExecutions.accountWithdrawExecutions.push(execution);

            /// Invariants assessment


        }

        // /// handle `require` text-based errors
        // catch Error(string memory err) {
        //     // string[] memory allowedErrors = new string[](1);
        //     // allowedErrors[0] = "First error";
            
        //     // _assertTextErrorsAllowed(err, allowedErrors);
        // }
        
        /// handle custom errors
        catch(bytes memory err) {
            bytes4[] memory allowedErrors = new bytes4[](2);
            allowedErrors[0] = AddressUtils.AddressZero.selector;
            allowedErrors[1] = Errors.AmountZeroNotAllowed.selector;

            _assertCustomErrorsAllowed(err, allowedErrors);
        }
    }

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

    /// createOrderRequest for Crypto token
    function orderFacet_createTokenOrderRequest(
        uint256 _answer, 
        bool _isCrossMargin, 
        Order.Side _orderSide, 
        Order.PositionSide _positionSide,
        Order.Type _orderType,
        Order.StopType _stopType,
        uint256 _marginTokenIndex,
        uint256 _qty,
        uint256 _orderMargin,
        uint256 _leverage,
        uint256 _triggerPrice,
        uint256 _acceptablePrice
    ) public {
        BeforeAfterParamHelper memory beAfParams;
        IOrder.PlaceOrderParams memory params;
        OrderParamsHelper memory orderParamsHelper;
        beAfParams.oracles = getOracleParam(_answer);


        /// createOrder params setup
        params.isCrossMargin = _isCrossMargin;
        params.isNativeToken = false;
        params.orderSide = _orderSide;
        params.posSide = _positionSide;
        params.orderType = _orderType;
        params.stopType = _stopType;
        orderParamsHelper.tokenIndex = EchidnaUtils.clampBetween(_marginTokenIndex, 0, 2);
        params.marginToken = tokens[orderParamsHelper.tokenIndex];
        params.qty = _qty;
        params.orderMargin = EchidnaUtils.clampBetween(_orderMargin, 0, IERC20(params.marginToken).balanceOf(msg.sender));
        params.leverage = EchidnaUtils.clampBetween(_leverage, 0, MarketConfig.getMaxLeverage());
        params.triggerPrice = EchidnaUtils.clampBetween(_triggerPrice, 0, 100_000e8);
        params.acceptablePrice = EchidnaUtils.clampBetween(_acceptablePrice, 0, 100_000e8);
        params.executionFee = ChainConfig.getPlaceIncreaseOrderGasFeeLimit();
        params.placeTime = block.timestamp;
        params.symbol = params.marginToken == address(weth) ? MarketConfig.getWethSymbol() : MarketConfig.getWbtcSymbol();
        
        __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);
        vm.prank(msg.sender);
        try diamondOrderFacet.createOrderRequest{value: params.executionFee}(params)returns(uint256 orderId) {
            __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

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


        }

        /// handle `require` text-based errors
        catch Error(string memory err) {

            string[] memory allowedErrors = new string[](5);
            allowedErrors[0] = "Deposit native token amount error!";
            allowedErrors[1] = "Deposit with token error!";
            allowedErrors[2] = "SafeERC20: ERC20 operation did not succeed";
            allowedErrors[3] = "Address: insufficient balance for call";
            allowedErrors[4] = "place order with execution fee error!";

            _assertTextErrorsAllowed(err, allowedErrors);
        }

        /// handle custom errors
        catch(bytes memory err) {
            bytes4[] memory allowedErrors = new bytes4[](5);
            allowedErrors[0] = TransferUtils.TokenTransferError.selector;
            allowedErrors[1] = Errors.PlaceOrderWithParamsError.selector;
            allowedErrors[2] = Errors.SymbolStatusInvalid.selector;
            allowedErrors[3] = Errors.OnlyOneShortPositionSupport.selector;
            allowedErrors[4] = Errors.ExecutionFeeNotEnough.selector;

            _assertCustomErrorsAllowed(err, allowedErrors);
        }
    }


    /// createOrderRequest for Native token
    function orderFacet_createNativeOrderRequest(
        uint256 _answer, 
        bool _isCrossMargin, 
        Order.Side _orderSide, 
        Order.PositionSide _positionSide,
        Order.Type _orderType,
        Order.StopType _stopType,
        uint256 _marginTokenIndex,
        uint256 _qty,
        uint256 _orderMargin,
        uint256 _leverage,
        uint256 _triggerPrice,
        uint256 _acceptablePrice
    ) public {
        BeforeAfterParamHelper memory beAfParams;
        IOrder.PlaceOrderParams memory params;
        OrderParamsHelper memory orderParamsHelper;
        beAfParams.oracles = getOracleParam(_answer);


        /// createOrder params setup
        params.isCrossMargin = _isCrossMargin;
        params.isNativeToken = true;
        params.orderSide = _orderSide;
        params.posSide = _positionSide;
        params.orderType = _orderType;
        params.stopType = _stopType;
        params.marginToken = address(weth);
        params.qty = _qty;
        params.orderMargin = EchidnaUtils.clampBetween(_orderMargin, 0, msg.sender.balance);
        params.leverage = EchidnaUtils.clampBetween(_leverage, 0, MarketConfig.getMaxLeverage());
        params.triggerPrice = EchidnaUtils.clampBetween(_triggerPrice, 0, 100_000e8);
        params.acceptablePrice = EchidnaUtils.clampBetween(_acceptablePrice, 0, 100_000e8);
        params.executionFee = ChainConfig.getPlaceIncreaseOrderGasFeeLimit();
        params.placeTime = block.timestamp;
        params.symbol = params.marginToken == address(weth) ? MarketConfig.getWethSymbol() : MarketConfig.getWbtcSymbol();
        
        __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);
        vm.prank(msg.sender);
        try diamondOrderFacet.createOrderRequest{value: params.orderMargin}(params)returns(uint256 orderId) {
            __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

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


        }

        /// handle `require` text-based errors
        catch Error(string memory err) {

            string[] memory allowedErrors = new string[](5);
            allowedErrors[0] = "Deposit native token amount error!";
            allowedErrors[1] = "Deposit with token error!";
            allowedErrors[2] = "SafeERC20: ERC20 operation did not succeed";
            allowedErrors[3] = "Address: insufficient balance for call";
            allowedErrors[4] = "place order with execution fee error!";

            _assertTextErrorsAllowed(err, allowedErrors);
        }

        /// handle custom errors
        catch(bytes memory err) {
            bytes4[] memory allowedErrors = new bytes4[](5);
            allowedErrors[0] = TransferUtils.TokenTransferError.selector;
            allowedErrors[1] = Errors.PlaceOrderWithParamsError.selector;
            allowedErrors[2] = Errors.SymbolStatusInvalid.selector;
            allowedErrors[3] = Errors.OnlyOneShortPositionSupport.selector;
            allowedErrors[4] = Errors.ExecutionFeeNotEnough.selector;

            _assertCustomErrorsAllowed(err, allowedErrors);
        }
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


    struct BatchCreateOrderParamsHelper{
        bool isCrossMargin; 
        Order.Side orderSide; 
        Order.Type orderType;
        Order.StopType stopType;
        uint256 marginTokenIndex;
        uint256 qty;
        uint256 orderMargin;
        uint256 leverage;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 ethValue;
    }

    function _createBatchOrders(
        uint256 _numOrders, 
        // OracleProcess.OracleParam[] memory oracles, 
        BatchCreateOrderParamsHelper memory paramsHelper
    ) internal returns(IOrder.PlaceOrderParams[] memory orderParams, uint256 totalEthValue) {
        IOrder.PlaceOrderParams[] memory params = new IOrder.PlaceOrderParams[](_numOrders);
        IOrder.PlaceOrderParams memory params_item;
        OrderParamsHelper memory orderParamsHelper;

        for(uint256 i = 0; i < params.length; i++) {
            /// createOrder params setup
            params_item.isCrossMargin = paramsHelper.isCrossMargin;
            params_item.isNativeToken = i % 2 == 0 ? true : false;
            params_item.orderSide = i % 2 == 0 ? paramsHelper.orderSide : Order.Side.LONG;
            params_item.posSide = Order.PositionSide.DECREASE;
            params_item.orderType = i % 2 == 0 ? paramsHelper.orderType : Order.Type.MARKET;
            params_item.stopType = i % 2 == 0 ? paramsHelper.stopType : Order.StopType.TAKE_PROFIT;
            params_item.marginToken = tokens[EchidnaUtils.clampBetween(paramsHelper.marginTokenIndex, 0, tokens.length - 1)];
            params_item.qty = paramsHelper.qty + i;
            params_item.orderMargin = EchidnaUtils.clampBetween(paramsHelper.orderMargin, 0, IERC20(params_item.marginToken).balanceOf(msg.sender));
            params_item.leverage = EchidnaUtils.clampBetween(paramsHelper.leverage, 0, MarketConfig.getMaxLeverage() - params.length);
            params_item.triggerPrice = EchidnaUtils.clampBetween(paramsHelper.triggerPrice, 0, 100_000e8);
            params_item.acceptablePrice = EchidnaUtils.clampBetween(paramsHelper.acceptablePrice, 0, 100_000e8);
            params_item.executionFee = ChainConfig.getPlaceDecreaseOrderGasFeeLimit();
            params_item.placeTime = block.timestamp;
            params_item.symbol = params_item.marginToken == address(weth) ? MarketConfig.getWethSymbol() : MarketConfig.getWbtcSymbol();
            
            params[i] = params_item;
            orderParamsHelper.ethValue += params_item.executionFee;
        }

        return (params, orderParamsHelper.ethValue);
    }

    /// batchCreateOrderRequest
    function orderFacet_batchCreateOrderRequest(
        uint256 _answer,
        uint256 _numOrders, 
        bool _isCrossMargin, 
        Order.Side _orderSide, 
        Order.Type _orderType,
        Order.StopType _stopType,
        uint256 _marginTokenIndex,
        uint256 _qty,
        uint256 _orderMargin,
        uint256 _leverage,
        uint256 _triggerPrice,
        uint256 _acceptablePrice
    ) public {
        BeforeAfterParamHelper memory beAfParams;
        IOrder.PlaceOrderParams[] memory params;
        BatchCreateOrderParamsHelper memory paramsHelper;
        beAfParams.oracles = getOracleParam(_answer);

        paramsHelper.isCrossMargin = _isCrossMargin;
        paramsHelper.orderSide = _orderSide;
        paramsHelper.orderType = _orderType;
        paramsHelper.stopType = _stopType;
        paramsHelper.marginTokenIndex = _marginTokenIndex;
        paramsHelper.qty = _qty;
        paramsHelper.orderMargin = _orderMargin;
        paramsHelper.leverage = _leverage;
        paramsHelper.triggerPrice = _triggerPrice;
        paramsHelper.acceptablePrice = _acceptablePrice;
        
        (params, paramsHelper.ethValue) = _createBatchOrders(EchidnaUtils.clampBetween(_numOrders, 1, 5), paramsHelper);

        __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);
        vm.prank(msg.sender);
        try diamondOrderFacet.batchCreateOrderRequest{value: paramsHelper.ethValue}(params)returns(uint256[] memory orderIds) {
            __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);

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

            /// Add Invariants
            
        }                      
        
        /// handle `require` text-based errors
        catch Error(string memory err) {
            string[] memory allowedErrors = new string[](3);
            allowedErrors[0] = "place order with execution fee error!";
            allowedErrors[1] = "Batch place order with execution fee error!";
            allowedErrors[2] = "Deposit native token amount error!";

            _assertTextErrorsAllowed(err, allowedErrors);
        }

        /// handle custom errors
        catch(bytes memory err) {
            bytes4[] memory allowedErrors = new bytes4[](8);
            allowedErrors[0] = Errors.OnlyDecreaseOrderSupported.selector;
            allowedErrors[1] = Errors.MarginModeError.selector;
            allowedErrors[2] = Errors.ExecutionFeeNotEnough.selector;
            allowedErrors[3] = Errors.PlaceOrderWithParamsError.selector;
            allowedErrors[4] = Errors.SymbolStatusInvalid.selector;
            allowedErrors[5] = Errors.OnlyOneShortPositionSupport.selector;
            allowedErrors[6] = TransferUtils.TokenTransferError.selector;
            allowedErrors[7] = Errors.PositionNotExists.selector;

            _assertCustomErrorsAllowed(err, allowedErrors);
        }
    }


    ////////// PositionFacet //////////

    /// createUpdatePositionMarginRequest crytpo token
    function positionFacet_createUpdatePositionMarginRequestCrypto(uint256 _answer, bool _isAdd, uint256 _positionKeyIndex, uint256 _tokenIndex, uint256 _updateMarginAmount) public {
        BeforeAfterParamHelper memory beAfParams;
        IPosition.UpdatePositionMarginParams memory params;
        beAfParams.oracles = getOracleParam(_answer);
        __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);

        params.positionKey = _before.positionKey[EchidnaUtils.clampBetween(_positionKeyIndex, 0, _before.positionKey.length - 1)];
        params.isAdd = _isAdd;
        params.isNativeToken = false;
        params.marginToken = tokens[EchidnaUtils.clampBetween(_tokenIndex, 0, tokens.length - 1)];
        params.updateMarginAmount = EchidnaUtils.clampBetween(_updateMarginAmount, 0, IERC20(params.marginToken).balanceOf(msg.sender));
        params.executionFee = ChainConfig.getPositionUpdateMarginGasFeeLimit();

        vm.prank(msg.sender);
        try diamondPositionFacet.createUpdatePositionMarginRequest{value: params.executionFee}(params)returns(uint256 requestId) {
            __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

            // Add positionMarginRequest to Queue
            PositionMarginRequests memory execution = PositionMarginRequests(
                msg.sender, 
                requestId, 
                params.positionKey,
                params.isAdd,
                params.isNativeToken,
                params.updateMarginAmount,
                params.executionFee,
                false);
            _keeperExecutions.positionMarginRequests.push(execution);

            /// Invariants assessment

            
        }

        /// handle `require` text-based errors
        catch Error(string memory err) {
            string[] memory allowedErrors = new string[](2);
            allowedErrors[0] = "update margin with execution fee error!";
            allowedErrors[1] = "Deposit eth amount error!";

            _assertTextErrorsAllowed(err, allowedErrors);
        }

        /// handle custom errors
        catch(bytes memory err) {
            bytes4[] memory allowedErrors = new bytes4[](5);
            allowedErrors[0] = Errors.AmountZeroNotAllowed.selector;
            allowedErrors[1] = Errors.OnlyIsolateSupported.selector;
            allowedErrors[2] = Errors.ExecutionFeeNotEnough.selector;
            allowedErrors[3] = Errors.PositionNotExists.selector;
            allowedErrors[4] = TransferUtils.TokenTransferError.selector;

            _assertCustomErrorsAllowed(err, allowedErrors);
        }
    }


    function positionFacet_createUpdatePositionMarginRequestNative(uint256 _answer, bool _isAdd, uint256 _positionKeyIndex, uint256 _tokenIndex, uint256 _updateMarginAmount) public {
        BeforeAfterParamHelper memory beAfParams;
        IPosition.UpdatePositionMarginParams memory params;
        beAfParams.oracles = getOracleParam(_answer);
        __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);

        params.positionKey = _before.positionKey[EchidnaUtils.clampBetween(_positionKeyIndex, 0, _before.positionKey.length - 1)];
        params.isAdd = _isAdd;
        params.isNativeToken = true;
        params.marginToken = tokens[EchidnaUtils.clampBetween(_tokenIndex, 0, tokens.length - 1)];
        params.updateMarginAmount = EchidnaUtils.clampBetween(_updateMarginAmount, 0, msg.sender.balance);
        params.executionFee = ChainConfig.getPositionUpdateMarginGasFeeLimit();

        vm.prank(msg.sender);
        try diamondPositionFacet.createUpdatePositionMarginRequest{value: params.updateMarginAmount}(params)returns(uint256 requestId) {
            __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

            // Add positionMarginRequest to Queue
            PositionMarginRequests memory execution = PositionMarginRequests(
                msg.sender, 
                requestId, 
                params.positionKey,
                params.isAdd,
                params.isNativeToken,
                params.updateMarginAmount,
                params.executionFee,
                false);
            _keeperExecutions.positionMarginRequests.push(execution);

            /// Invariants assessment

            
        }

        /// handle `require` text-based errors
        catch Error(string memory err) {
            string[] memory allowedErrors = new string[](2);
            allowedErrors[0] = "update margin with execution fee error!";
            allowedErrors[1] = "Deposit eth amount error!";

            _assertTextErrorsAllowed(err, allowedErrors);
        }

        /// handle custom errors
        catch(bytes memory err) {
            bytes4[] memory allowedErrors = new bytes4[](5);
            allowedErrors[0] = Errors.AmountZeroNotAllowed.selector;
            allowedErrors[1] = Errors.OnlyIsolateSupported.selector;
            allowedErrors[2] = Errors.ExecutionFeeNotEnough.selector;
            allowedErrors[3] = Errors.PositionNotExists.selector;
            allowedErrors[4] = TransferUtils.TokenTransferError.selector;

            _assertCustomErrorsAllowed(err, allowedErrors);
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

    /// createUpdateLeverageRequest native token
    function positionFacet_createUpdateLeverageRequestCrypto(uint256 _answer, bool _isLong, bool _isCrossMargin, uint256 _leverage, uint256 _tokenIndex, uint256 _addMarginAmount ) public {
        // Get oracles
        BeforeAfterParamHelper memory beAfParams;
        IPosition.UpdateLeverageParams memory params;
        beAfParams.oracles = getOracleParam(_answer);

        params.isLong = _isLong;
        params.isNativeToken = false;
        params.isCrossMargin = _isCrossMargin;
        params.leverage =  EchidnaUtils.clampBetween(_leverage, 0, MarketConfig.getMaxLeverage());
        params.marginToken = tokens[EchidnaUtils.clampBetween(_tokenIndex, 0, tokens.length - 1)];
        params.symbol = params.marginToken == address(weth) ? MarketConfig.getWethSymbol() : MarketConfig.getWbtcSymbol();
        params.addMarginAmount = EchidnaUtils.clampBetween(_addMarginAmount, 0, IERC20(params.marginToken).balanceOf(msg.sender));
        params.executionFee = ChainConfig.getPositionUpdateLeverageGasFeeLimit();

        __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, params.symbol);
        vm.prank(msg.sender); 
        try diamondPositionFacet.createUpdateLeverageRequest{value: params.executionFee}(params)returns(uint256 requestId) {
            __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, params.symbol); 

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

            
        }

        /// handle `require` text-based errors
        catch Error(string memory err) {
            string[] memory allowedErrors = new string[](2);
            allowedErrors[0] = "update leverage with execution fee error!";
            allowedErrors[1] = "Deposit eth amount error!";
            
            _assertTextErrorsAllowed(err, allowedErrors);
        }

        /// handle custom errors
        catch(bytes memory err) {
            bytes4[] memory allowedErrors = new bytes4[](5);
            allowedErrors[0] = Errors.SymbolNotExists.selector;
            allowedErrors[1] = Errors.SymbolStatusInvalid.selector;
            allowedErrors[2] = Errors.LeverageInvalid.selector;
            allowedErrors[3] = Errors.ExecutionFeeNotEnough.selector;
            allowedErrors[4] = TransferUtils.TokenTransferError.selector;

            _assertCustomErrorsAllowed(err, allowedErrors);
        }
    }


    /// createUpdateLeverageRequest Crypto
    function positionFacet_createUpdateLeverageRequestNative(uint256 _answer, bool _isLong, bool _isCrossMargin, uint256 _leverage, uint256 _tokenIndex, uint256 _addMarginAmount ) public {
        // Get oracles
        BeforeAfterParamHelper memory beAfParams;
        IPosition.UpdateLeverageParams memory params;
        beAfParams.oracles = getOracleParam(_answer);

        params.isLong = _isLong;
        params.isNativeToken = true;
        params.isCrossMargin = _isCrossMargin;
        params.leverage =  EchidnaUtils.clampBetween(_leverage, 0, MarketConfig.getMaxLeverage());
        params.marginToken = tokens[EchidnaUtils.clampBetween(_tokenIndex, 0, tokens.length - 1)];
        params.symbol = params.marginToken == address(weth) ? MarketConfig.getWethSymbol() : MarketConfig.getWbtcSymbol();
        params.addMarginAmount = EchidnaUtils.clampBetween(_addMarginAmount, 0, msg.sender.balance);
        params.executionFee = ChainConfig.getPositionUpdateLeverageGasFeeLimit();

        __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, params.symbol);
        vm.prank(msg.sender); 
        try diamondPositionFacet.createUpdateLeverageRequest{value: params.addMarginAmount}(params)returns(uint256 requestId) {
            __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, params.symbol); 

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

            
        }

        /// handle `require` text-based errors
        catch Error(string memory err) {
            string[] memory allowedErrors = new string[](2);
            allowedErrors[0] = "update leverage with execution fee error!";
            allowedErrors[1] = "Deposit eth amount error!";
            
            _assertTextErrorsAllowed(err, allowedErrors);
        }

        /// handle custom errors
        catch(bytes memory err) {
            bytes4[] memory allowedErrors = new bytes4[](5);
            allowedErrors[0] = Errors.SymbolNotExists.selector;
            allowedErrors[1] = Errors.SymbolStatusInvalid.selector;
            allowedErrors[2] = Errors.LeverageInvalid.selector;
            allowedErrors[3] = Errors.ExecutionFeeNotEnough.selector;
            allowedErrors[4] = TransferUtils.TokenTransferError.selector;

            _assertCustomErrorsAllowed(err, allowedErrors);
        }
    }

    ////////// StakeFacet //////////

    /// createMintStakeTokenRequest
    function stakeFacet_createMintStakeTokenRequest(
        uint256 _answer, 
        uint256 _stakeTokenIndex, 
        uint256 _requestTokenIndex, 
        uint256 _requestTokenAmount,
        uint256 _walletRequestTokenAmount,
        uint256 _minStakeAmount,
        bool _isCollateral
    ) public {
        BeforeAfterParamHelper memory beAfParams;
        IStake.MintStakeTokenParams memory params;
        StakeParamsHelper memory stakeParamsHelper;
        beAfParams.oracles = getOracleParam(_answer);

        /// createOrder params setup
        stakeParamsHelper.stakeTokenIndex = EchidnaUtils.clampBetween(_stakeTokenIndex, 0, stakedTokens.length - 1);
        params.stakeToken = stakedTokens[stakeParamsHelper.stakeTokenIndex];
        stakeParamsHelper.requestTokenIndex = EchidnaUtils.clampBetween(_requestTokenIndex, 0, tokens.length - 1);
        params.requestToken = tokens[stakeParamsHelper.requestTokenIndex];
        params.requestTokenAmount = _requestTokenAmount;
        params.walletRequestTokenAmount = EchidnaUtils.clampBetween(_walletRequestTokenAmount, 0, IERC20(params.requestToken).balanceOf(msg.sender));
        params.minStakeAmount = _minStakeAmount;
        params.executionFee = ChainConfig.getMintGasFeeLimit();
        params.isCollateral = _isCollateral;
        params.isNativeToken = false;

        /// BeforAfter params setup
        beAfParams.stakeToken = params.stakeToken;

        __before(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);
        vm.prank(msg.sender);
        try diamondStakeFacet.createMintStakeTokenRequest{value: params.executionFee}(params)returns(uint256 requestId) {
            __after(msg.sender, beAfParams.oracles, beAfParams.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

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

            
        }         

        /// handle `require` text-based errors
        catch Error(string memory err) {
            string[] memory allowedErrors = new string[](3);
            allowedErrors[0] = "mint with execution fee error!";
            allowedErrors[1] = "Deposit with token error!";
            allowedErrors[2] = "Deposit eth amount error!";

            _assertTextErrorsAllowed(err, allowedErrors);
        }

        /// handle custom errors
        catch(bytes memory err) {
            bytes4[] memory allowedErrors = new bytes4[](6);
            allowedErrors[0] = Errors.MintWithAmountZero.selector;
            allowedErrors[1] = Errors.MintTokenInvalid.selector;
            allowedErrors[2] = Errors.StakeTokenInvalid.selector;
            allowedErrors[3] = Errors.MintWithParamError.selector;
            allowedErrors[4] = Errors.ExecutionFeeNotEnough.selector;
            allowedErrors[5] = TransferUtils.TokenTransferError.selector;

            _assertCustomErrorsAllowed(err, allowedErrors);
        }
    }

    function stakeFacet_createMintStakeTokenRequestNative(
        uint256 _answer, 
        uint256 _stakeTokenIndex, 
        uint256 _requestTokenIndex, 
        uint256 _requestTokenAmount,
        uint256 _walletRequestTokenAmount,
        uint256 _minStakeAmount,
        bool _isCollateral
    ) public {
        BeforeAfterParamHelper memory beAfParams;
        IStake.MintStakeTokenParams memory params;
        StakeParamsHelper memory stakeParamsHelper;
        beAfParams.oracles = getOracleParam(_answer);

        /// createOrder params setup
        stakeParamsHelper.stakeTokenIndex = EchidnaUtils.clampBetween(_stakeTokenIndex, 0, stakedTokens.length - 1);
        params.stakeToken = stakedTokens[stakeParamsHelper.stakeTokenIndex];
        stakeParamsHelper.requestTokenIndex = EchidnaUtils.clampBetween(_requestTokenIndex, 0, tokens.length - 1);
        params.requestToken = tokens[stakeParamsHelper.requestTokenIndex];
        params.requestTokenAmount = _requestTokenAmount;
        params.walletRequestTokenAmount = EchidnaUtils.clampBetween(_walletRequestTokenAmount, 0, msg.sender.balance);
        params.minStakeAmount = _minStakeAmount;
        params.executionFee = ChainConfig.getMintGasFeeLimit();
        params.isCollateral = _isCollateral;
        params.isNativeToken = true;

        __before(msg.sender, beAfParams.oracles, params.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);
        vm.prank(msg.sender); 
        try diamondStakeFacet.createMintStakeTokenRequest{value: params.walletRequestTokenAmount}(params)returns(uint256 requestId) {
            __after(msg.sender, beAfParams.oracles, params.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

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

            
        }         

        /// handle `require` text-based errors
        catch Error(string memory err) {
            string[] memory allowedErrors = new string[](3);
            allowedErrors[0] = "mint with execution fee error!";
            allowedErrors[1] = "Deposit with token error!";
            allowedErrors[2] = "Deposit eth amount error!";

            _assertTextErrorsAllowed(err, allowedErrors);
        }

        /// handle custom errors
        catch(bytes memory err) {
            bytes4[] memory allowedErrors = new bytes4[](6);
            allowedErrors[0] = Errors.MintWithAmountZero.selector;
            allowedErrors[1] = Errors.MintTokenInvalid.selector;
            allowedErrors[2] = Errors.StakeTokenInvalid.selector;
            allowedErrors[3] = Errors.MintWithParamError.selector;
            allowedErrors[4] = Errors.ExecutionFeeNotEnough.selector;
            allowedErrors[5] = TransferUtils.TokenTransferError.selector;

            _assertCustomErrorsAllowed(err, allowedErrors);
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
        uint256 receiverIndex;
    }

    function stakeFacet_createRedeemStakeTokenRequest(
        uint256 _answer, 
        address _receiver,
        uint256 _receiverIndex,
        uint256 _stakeTokenIndex, 
        uint256 _redeemTokenIndex, 
        uint256 _unStakeAmount,
        uint256 _minRedeemAmount
    ) public {
        // Get oracles
        BeforeAfterParamHelper memory beAfParams;
        IStake.RedeemStakeTokenParams memory params;
        StakeParamsHelper memory stakeParamsHelper;
        beAfParams.oracles = getOracleParam(_answer);

        // params.receiver = msg.sender; // Alt 1
        // params.receiver = _receiver; // Alt 2
        params.receiver = USERS[EchidnaUtils.clampBetween(_receiverIndex, 0, USERS.length - 1)];
        params.stakeToken = stakedTokens[EchidnaUtils.clampBetween(_stakeTokenIndex, 0, stakedTokens.length - 1)];
        params.redeemToken = tokens[EchidnaUtils.clampBetween(_redeemTokenIndex, 0, tokens.length - 1)];
        params.unStakeAmount = _unStakeAmount;
        params.minRedeemAmount = _minRedeemAmount;
        params.executionFee = ChainConfig.getRedeemGasFeeLimit();
        
        __before(msg.sender, beAfParams.oracles, params.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code);
        vm.prank(msg.sender); 
        try diamondStakeFacet.createRedeemStakeTokenRequest{value: params.executionFee}(params)returns(uint256 requestId) {
            __after(msg.sender, beAfParams.oracles, params.stakeToken, beAfParams.collateralToken, beAfParams.token, beAfParams.code); 

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

            
        }

        /// handle `require` text-based errors
        catch Error(string memory err) {
            // require(msg.value == executionFee, "redeem with execution fee error!");
            // require(params.unStakeAmount > 0, "unStakeAmount == 0");
            string[] memory allowedErrors = new string[](2);
            allowedErrors[0] = "redeem with execution fee error!";
            allowedErrors[1] = "unStakeAmount == 0";

            _assertTextErrorsAllowed(err, allowedErrors);
        }
        
        /// handle custom errors
        catch(bytes memory err) {

            bytes4[] memory allowedErrors = new bytes4[](4);
            allowedErrors[0] = AddressUtils.AddressZero.selector;
            allowedErrors[1] = Errors.RedeemWithAmountNotEnough.selector;
            allowedErrors[2] = Errors.RedeemTokenInvalid.selector;
            allowedErrors[3] = Errors.StakeTokenInvalid.selector;

            _assertCustomErrorsAllowed(err, allowedErrors);
        }
    }

}
