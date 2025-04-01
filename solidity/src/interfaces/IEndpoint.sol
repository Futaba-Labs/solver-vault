// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IEndpoint {
    function requestBorrowForERC7683(address _vault, address _target, bytes32 _orderId, bytes calldata _originData, bytes calldata _fillerData) external;
}
