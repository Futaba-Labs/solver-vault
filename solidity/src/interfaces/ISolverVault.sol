// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISolverVault {
    struct BorrowParams {
        uint256 inputAmount;
        uint256 outputAmount;
        address outputToken;
        address target;
        bool isNative;
        bytes data;
    }

    function borrow(BorrowParams calldata params) external payable;
    function repay(uint256 amount) external;
}
