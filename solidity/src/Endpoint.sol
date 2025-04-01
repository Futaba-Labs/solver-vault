// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ISolverVault} from "./interfaces/ISolverVault.sol";
import {IEndpoint} from "./interfaces/IEndpoint.sol";
import { OrderData, OrderEncoder } from "@intents-framework/src/libs/OrderEncoder.sol";


contract Endpoint is Ownable, IEndpoint {
    mapping (address => bool) public solvers;
    mapping (address => bool) public vaults;

    event AddSolver(address solver);
    event AddVault(address vault);

    error InvalidVault(address vault);
    error InvalidNativeAmount();

    // constructor(address _owner) Ownable(_owner) {}

    function requestBorrowForERC7683(address _vault, address _target, bytes32 _orderId, bytes calldata _originData, bytes calldata _fillerData) external {
        OrderData memory orderData = OrderEncoder.decode(_originData);
        ISolverVault.BorrowParams memory params = ISolverVault.BorrowParams({
            inputAmount: orderData.amountIn,
            outputAmount: orderData.amountOut,
            outputToken: bytes32ToAddress(orderData.outputToken),
            target: _target,
            isNative: bytes32ToAddress(orderData.outputToken) == address(0),
            data: abi.encodeWithSignature("fill(bytes32,bytes,bytes)", _orderId, _originData, _fillerData)
        });

        _requestBorrow(_vault, params);
    }

    function _requestBorrow(address _vault, ISolverVault.BorrowParams memory _params) private {
        if (!vaults[_vault]) {
            revert InvalidVault(_vault);
        }

       ISolverVault(_vault).borrow(_params);
    }

    function addSolver(address _solver) external onlyOwner {
        solvers[_solver] = true;
        emit AddSolver(_solver);
    }

    function addVault(address _vault) external onlyOwner {
        vaults[_vault] = true;
        emit AddVault(_vault);
    }

    function bytes32ToAddress(bytes32 _bytes32) internal pure returns (address) {
        return address(uint160(uint256(_bytes32)));
    }
}