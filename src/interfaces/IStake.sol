// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../process/OracleProcess.sol";
import "../storage/Mint.sol";
import "../storage/Redeem.sol";

interface IStake {

    struct MintStakeTokenParams {
        address stakeToken;
        address requestToken;
        uint256 requestTokenAmount;
        uint256 walletRequestTokenAmount;
        uint256 minStakeAmount;
        uint256 executionFee;
        bool isCollateral;
        bool isNativeToken;
    }

    struct RedeemStakeTokenParams {
        address receiver;
        address stakeToken;
        address redeemToken;
        uint256 unStakeAmount;
        uint256 minRedeemAmount;
        uint256 executionFee;
    }

    // @audit added a return for requestId value for easy testing
    function createMintStakeTokenRequest(MintStakeTokenParams calldata params) external payable returns (uint256);

    function executeMintStakeToken(uint256 requestId, OracleProcess.OracleParam[] calldata oracles) external;

    function cancelMintStakeToken(uint256 requestId, bytes32 reasonCode) external;

    // @audit added a return for requestId value for easy testing
    function createRedeemStakeTokenRequest(RedeemStakeTokenParams calldata params) external payable returns (uint256);

    function executeRedeemStakeToken(uint256 requestId, OracleProcess.OracleParam[] calldata oracles) external;

    function cancelRedeemStakeToken(uint256 requestId, bytes32 reasonCode) external;

}
