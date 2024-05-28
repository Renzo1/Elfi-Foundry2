// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../interfaces/IWETH.sol";
import "../vault/Vault.sol";
import "../storage/AppConfig.sol";
import "../utils/Errors.sol";

// @audit change all functions to internal and param location to memory for easy testing
library VaultProcess {
    function transferOut(address vault, address token, address receiver, uint256 amount) internal returns (bool) {
        return transferOut(vault, token, receiver, amount, false);
    }

    function transferOut(
        address vault,
        address token,
        address receiver,
        uint256 amount,
        bool skipBalanceNotEnough
    ) internal returns (bool) {
        if (amount == 0) {
            return false;
        }
        uint256 tokenBalance = IERC20(token).balanceOf(vault);
        if (tokenBalance >= amount) {
            Vault(vault).transferOut(token, receiver, amount);
            return true;
        } else if (!skipBalanceNotEnough) {
            revert Errors.TransferErrorWithVaultBalanceNotEnough(vault, token, receiver, amount);
        }
        return false;
    }

    function tryTransferOut(address vault, address token, address receiver, uint256 amount) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        uint256 tokenBalance = IERC20(token).balanceOf(vault);
        if (tokenBalance == 0) {
            return 0;
        }
        if (tokenBalance >= amount) {
            Vault(vault).transferOut(token, receiver, amount);
            return amount;
        } else {
            Vault(vault).transferOut(token, receiver, tokenBalance);
            return tokenBalance;
        }
    }

    function withdrawEther(address receiver, uint256 amount) internal {
        address wrapperToken = AppConfig.getChainConfig().wrapperToken;
        IWETH(wrapperToken).withdraw(amount);
        safeTransferETH(receiver, amount);
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "STE");
    }
}
