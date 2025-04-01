// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {Endpoint} from "../src/Endpoint.sol";
import {SolverVault} from "../src/SolverVault.sol";
import {ETHSolverVault} from "../src/ETHSolverVault.sol";

contract DeployScript is Script {
    uint256 deployerPrivateKey = vm.envUint("DEPOSITOR_PK");

    // Endpoint public endpoint = Endpoint(vm.envAddress("ENDPOINT"));
    SolverVault public solverVault = SolverVault(vm.envAddress("SOLVER_VAULT"));
    ETHSolverVault public ethSolverVault = ETHSolverVault(payable(vm.envAddress("ETH_SOLVER_VAULT")));
    address owner = vm.envAddress("OWNER");
    address depositor = payable(vm.envAddress("DEPOSITOR"));
    uint256 amount = 0.01 ether;

    function setUp() public {}

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        ethSolverVault.depositNative{value: amount}(amount, depositor);

        vm.stopBroadcast();
    }
}
