// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Endpoint} from "../src/Endpoint.sol";
import {SolverVault} from "../src/SolverVault.sol";
import {ETHSolverVault} from "../src/ETHSolverVault.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";

contract DeployScript is Script {
    uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PK");

    Endpoint public endpoint;
    SolverVault public solverVault;
    ETHSolverVault public ethSolverVault;
    // address public weth = 0x1BDD24840e119DC2602dCC587Dd182812427A5Cc; // OP Sepolia
    IWETH public weth = IWETH(0x4200000000000000000000000000000000000006); // Base Sepolia
    string public SLAT = vm.envString("VAULT_SALT");
    address owner = vm.envAddress("OWNER");
    address solver = vm.envAddress("SOLVER");

    function setUp() public {}

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        endpoint = new Endpoint();
        solverVault = new SolverVault{salt: keccak256(abi.encode(SLAT))}(weth, address(endpoint), owner);
        ethSolverVault = new ETHSolverVault{salt: keccak256(abi.encode(SLAT))}(weth, address(endpoint), owner);

        endpoint.addVault(address(solverVault));
        endpoint.addVault(address(ethSolverVault));
        endpoint.addSolver(address(ethSolverVault));

        console.log("endpoint", address(endpoint));
        console.log("solverVault", address(solverVault));
        console.log("ethSolverVault", address(ethSolverVault));
        vm.stopBroadcast();
    }
}
