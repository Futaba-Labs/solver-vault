// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISolverVault} from "./interfaces/ISolverVault.sol";

contract SolverVault is ERC4626, ISolverVault {
    uint256 public constant BORROW_BPS = 1;
    address public endpoint;
    address public owner;
    IERC20 public underlyingAsset;

    error OnlyEndpoint();
    error InvalidOutputToken(address outputToken);
    error BorrowRateTooHigh(uint256 inputAmount, uint256 outputAmount, uint256 borrowBps);
    error BorrowFailed(address target);

    constructor(IERC20 _asset, address _endpoint, address _owner) ERC4626(_asset) ERC20("Miki ETH", "mETH") {
        endpoint = _endpoint;
        owner = _owner;
        underlyingAsset = IERC20(_asset);
    }

    modifier onlyEndpoint() {
        if (msg.sender != endpoint) {
            revert OnlyEndpoint();
        }
        _;
    }

    function borrow(BorrowParams calldata params) override virtual payable external onlyEndpoint {
        // verify output token address
        if (params.outputToken != address(underlyingAsset)) {
            revert InvalidOutputToken(params.outputToken);
        }

        // verify borrow rate
        // if (params.inputAmount - params.outputAmount < params.inputAmount * BORROW_BPS / 10000) {
        //     revert BorrowRateTooHigh(params.inputAmount, params.outputAmount, BORROW_BPS);
        // }

        // execute the intent
        underlyingAsset.approve(params.target, params.outputAmount);
            (bool success, ) = params.target.call(params.data);
            if (!success) {
                revert BorrowFailed(params.target);
            }
    }

    function repay(uint256 amount) external onlyEndpoint {}
}
