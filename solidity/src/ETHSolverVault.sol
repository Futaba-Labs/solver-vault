// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {SolverVault} from "./SolverVault.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ETHSolverVault is SolverVault {
    IWETH public immutable weth;

    error InvalidNativeAmount();
    error ERC4626ExceededMaxDeposit(address receiver, uint256 assets, uint256 max);
    error ERC4626ExceededMaxWithdraw(address receiver, uint256 assets, uint256 max);

    constructor(IWETH _asset, address _endpoint, address _owner) SolverVault(_asset, _endpoint, _owner) {
        weth = _asset;
    }   

    // fallback() external payable { }

    receive() external payable { }

    function depositNative(uint256 assets, address receiver) payable external returns (uint256) {
        if (assets != msg.value) {
            revert InvalidNativeAmount();
        }
    
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    function withdrawNative(uint256 assets, address receiver, address owner) external returns (uint256) {
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    function borrow(BorrowParams calldata params) override payable external onlyEndpoint {
        // verify output token address
        if (params.outputToken != address(0) && params.outputToken != address(underlyingAsset)) {
            revert InvalidOutputToken(params.outputToken);
        }

        // verify borrow rate
        // if (params.inputAmount - params.outputAmount < params.inputAmount * BORROW_BPS / 10000) {
        //     revert BorrowRateTooHigh(params.inputAmount, params.outputAmount, BORROW_BPS);
        // }

        // execute the intent
        if (params.isNative) {
            weth.withdraw(params.outputAmount);
            (bool success, ) = params.target.call{value: params.outputAmount}(params.data);
            if (!success) {
                revert BorrowFailed(params.target);
            }
        } else {
            // approve the target to spend the asset
            underlyingAsset.approve(params.target, params.outputAmount);
            (bool success, ) = params.target.call(params.data);
            if (!success) {
                revert BorrowFailed(params.target);
            }
        }
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) override internal virtual {
        // Native ETH is already transferred via msg.value, so we don't need to do a transferFrom
        // We just need to mint the shares
        weth.deposit{value: assets}();

        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) override internal virtual {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If asset() is ERC-777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(owner, shares);
    
        weth.withdraw(assets);

        Address.sendValue(payable(receiver), assets);
    
        emit Withdraw(caller, receiver, owner, assets, shares);
    }
}
