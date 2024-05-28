// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

// @audit change all functions to internal and param location to memory for easy testing
library CommonData {
    bytes32 private constant COMMON_DATA = keccak256(abi.encode("xyz.elfi.storage.CommonData"));

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    struct Props {
        address stakeUsdToken;
        bytes32[] symbols;
        EnumerableSet.AddressSet stakeTokens;
        mapping(address => TokenData) tradeCollateralTokenDatas;
        mapping(address => uint256) stakeCollateralAmount;
        mapping(address => uint256) tokensTotalLiability;
        uint256 totalLossExecutionFee;
        EnumerableMap.AddressToUintMap cleanFunds;
    }

    struct TokenData {
        uint256 totalCollateral;
        uint256 totalLiability;
    }

    event LossExecutionFeeUpdateEvent(uint256 preAmount, uint256 amount);
    event CleanFundsUpdateEvent(address token, uint256 preAmount, uint256 amount);

    function load() internal pure returns (Props storage self) {
        bytes32 s = COMMON_DATA;
        assembly {
            self.slot := s
        }
    }

    function getStakeUsdToken() internal view returns (address) {
        Props storage self = load();
        return self.stakeUsdToken;
    }

    function setStakeUsdToken(address stakeUsdToken) internal {
        Props storage self = load();
        self.stakeUsdToken = stakeUsdToken;
    }

    function addSymbol(bytes32 code) internal {
        Props storage self = load();
        self.symbols.push(code);
    }

    function addStakeTokens(address stakeToken) internal {
        Props storage self = load();
        self.stakeTokens.add(stakeToken);
    }

    function isStakeTokenSupport(address stakeToken) internal view returns (bool) {
        Props storage self = load();
        return self.stakeTokens.contains(stakeToken);
    }

    function getAllSymbols() internal view returns (bytes32[] memory) {
        Props storage self = load();
        return self.symbols;
    }

    function getAllStakeTokens() internal view returns (address[] memory) {
        Props storage self = load();
        return self.stakeTokens.values();
    }

    function addTradeTokenCollateral(Props storage self, address token, uint256 amount) internal {
        self.tradeCollateralTokenDatas[token].totalCollateral += amount;
    }

    function subTradeTokenCollateral(Props storage self, address token, uint256 amount) internal {
        require(
            self.tradeCollateralTokenDatas[token].totalCollateral >= amount,
            "subTradeTokenCollateral less than amount"
        );
        self.tradeCollateralTokenDatas[token].totalCollateral -= amount;
    }

    function addTradeTokenLiability(Props storage self, address token, uint256 amount) internal {
        self.tradeCollateralTokenDatas[token].totalLiability += amount;
    }

    function subTradeTokenLiability(Props storage self, address token, uint256 amount) internal {
        require(
            self.tradeCollateralTokenDatas[token].totalLiability >= amount,
            "subTradeTokenLiability less than amount"
        );
        self.tradeCollateralTokenDatas[token].totalLiability -= amount;
    }

    function getTradeTokenCollateral(Props storage self, address token) internal view returns (uint256) {
        return self.tradeCollateralTokenDatas[token].totalCollateral;
    }

    function getTradeTokenLiability(Props storage self, address token) internal view returns (uint256) {
        return self.tradeCollateralTokenDatas[token].totalLiability;
    }

    function addStakeCollateralAmount(Props storage self, address token, uint256 amount) internal {
        self.stakeCollateralAmount[token] += amount;
    }

    function subStakeCollateralAmount(Props storage self, address token, uint256 amount) internal {
        require(self.stakeCollateralAmount[token] >= amount, "subStakeCollateralAmount less than amount");
        self.stakeCollateralAmount[token] -= amount;
    }

    function getStakeCollateralAmount(Props storage self, address token) internal view returns (uint256) {
        return self.stakeCollateralAmount[token];
    }

    function addTokenLiability(Props storage self, address token, uint256 addLiability) internal {
        self.tokensTotalLiability[token] += addLiability;
    }

    function subTokenLiability(Props storage self, address token, uint256 subLiability) internal {
        require(self.tokensTotalLiability[token] >= subLiability, "subTokenLiability less than liability");
        self.tokensTotalLiability[token] -= subLiability;
    }

    function getTokenLiability(Props storage self, address token) internal view returns (uint256) {
        return self.tokensTotalLiability[token];
    }

    function addLossExecutionFee(uint256 amount) internal {
        Props storage self = load();
        self.totalLossExecutionFee += amount;
        emit LossExecutionFeeUpdateEvent(self.totalLossExecutionFee - amount, self.totalLossExecutionFee);
    }

    function subLossExecutionFee(uint256 amount) internal {
        Props storage self = load();
        uint256 preLossFee = self.totalLossExecutionFee;
        if (self.totalLossExecutionFee <= amount) {
            self.totalLossExecutionFee = 0;
        } else {
            self.totalLossExecutionFee -= amount;
        }
        emit LossExecutionFeeUpdateEvent(preLossFee, self.totalLossExecutionFee);
    }

    function addCleanFunds(address token, uint256 amount) internal {
        Props storage self = load();
        (bool exists, uint256 preAmount) = self.cleanFunds.tryGet(token);
        if (exists) {
            self.cleanFunds.set(token, preAmount + amount);
        } else {
            self.cleanFunds.set(token, amount);
        }
        emit CleanFundsUpdateEvent(token, preAmount, preAmount + amount);
    }
}
