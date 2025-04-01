// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {Endpoint} from "../src/Endpoint.sol";
import {SolverVault} from "../src/SolverVault.sol";
import {ETHSolverVault} from "../src/ETHSolverVault.sol";
import {OrderEncoder, OrderData} from "@intents-framework/src/libs/OrderEncoder.sol";
import {TypeCasts} from "@hyperlane-xyz/libs/TypeCasts.sol";

contract DeployScript is Script {
    uint256 deployerPrivateKey = vm.envUint("SOLVER_PK");

    Endpoint public endpoint = Endpoint(vm.envAddress("ENDPOINT"));
    SolverVault public solverVault = SolverVault(vm.envAddress("SOLVER_VAULT"));
    ETHSolverVault public ethVault = ETHSolverVault(payable(vm.envAddress("ETH_SOLVER_VAULT")));

    address depositor = vm.envAddress("DEPOSITOR");
    address solver = vm.envAddress("SOLVER");
    address intentEndpoint = vm.envAddress("INTENT_ENDPOINT");
    address inputToken = 0x1BDD24840e119DC2602dCC587Dd182812427A5Cc; // OP Sepolia WETH
    uint256 amountIn = 0.001 ether;
    uint256 amountOut = 0.0009 ether;
    uint256 senderNonce = 3;
    uint32 origin = 11155420;
    uint32 destination = 84532;

    function setUp() public {}

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        OrderData memory order = OrderData(
            TypeCasts.addressToBytes32(depositor),
            TypeCasts.addressToBytes32(depositor),
            TypeCasts.addressToBytes32(address(0)),
            TypeCasts.addressToBytes32(address(0)),
            amountIn,
            amountOut,
            senderNonce,
            origin,
            destination,
            TypeCasts.addressToBytes32(address(intentEndpoint)),
            type(uint32).max,
            new bytes(0)
        );

        bytes memory orderData = OrderEncoder.encode(order);
        bytes32 orderId = OrderEncoder.id(order);
        bytes memory fillerData = abi.encode(TypeCasts.addressToBytes32(solver));

        endpoint.requestBorrowForERC7683(address(ethVault), address(intentEndpoint), orderId, orderData, fillerData);

        vm.stopBroadcast();
    }
}
