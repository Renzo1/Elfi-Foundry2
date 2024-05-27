// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IMarketManager.sol";
import "../process/MarketFactoryProcess.sol";
import "../process/OracleProcess.sol";
import "../storage/RoleAccessControl.sol";
import "../utils/AddressUtils.sol";
import "../utils/TypeUtils.sol";

contract MarketManagerFacet is IMarketManager, ReentrancyGuard {
        // @audit added a return for orderId value for easy testing
    function createMarket(MarketFactoryProcess.CreateMarketParams calldata params) external override nonReentrant returns (address) {
        RoleAccessControl.checkRole(RoleAccessControl.ROLE_CONFIG);
        TypeUtils.validBytes32Empty(params.code);
        TypeUtils.validStringEmpty(params.stakeTokenName);
        AddressUtils.validEmpty(params.indexToken);
        AddressUtils.validEmpty(params.baseToken);
        return MarketFactoryProcess.createMarket(params);
    }

    function createStakeUsdPool(
        string calldata stakeTokenName,
        uint8 decimals
    ) external override nonReentrant returns (address) {
        RoleAccessControl.checkRole(RoleAccessControl.ROLE_CONFIG);
        TypeUtils.validStringEmpty(stakeTokenName);
        return MarketFactoryProcess.createStakeUsdPool(stakeTokenName, decimals);
    }
}
