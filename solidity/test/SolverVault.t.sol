// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {SolverVault} from "../src/SolverVault.sol";
import {ETHSolverVault} from "../src/ETHSolverVault.sol";
import {ISolverVault} from "../src/interfaces/ISolverVault.sol";
import {Endpoint} from "../src/Endpoint.sol";
import {MockToken} from "../src/mocks/MockToken.sol";
import {WETHMock} from "../src/mocks/WETHMock.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import { Base7683 } from "@intents-framework/src/Base7683.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TypeCasts} from "@hyperlane-xyz/libs/TypeCasts.sol";
import {OrderEncoder, OrderData} from "@intents-framework/src/libs/OrderEncoder.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {
    GaslessCrossChainOrder,
    OnchainCrossChainOrder,
    ResolvedCrossChainOrder,
    Output,
    FillInstruction
} from "@intents-framework/src/ERC7683/IERC7683.sol";

event Filled(bytes32 orderId, bytes originData, bytes fillerData);

contract Base7683ForTest is Base7683, StdCheats {
    bytes32 public counterpart;

    bool internal _native = false;
    uint32 internal _origin;
    uint32 internal _destination;
    address internal inputToken;
    address internal outputToken;

    bytes32 public filledId;
    bytes public filledOriginData;
    bytes public filledFillerData;

    bytes32[] public settledOrderIds;
    bytes[] public settledOrdersOriginData;
    bytes[] public settledOrdersFillerData;

    bytes32[] public refundedOrderIds;

    constructor(
        address _permit2,
        uint32 _local,
        uint32 _remote,
        address _inputToken,
        address _outputToken
    )
        Base7683(_permit2)
    {
        _origin = _local;
        _destination = _remote;
        inputToken = _inputToken;
        outputToken = _outputToken;
    }

    function setNative(bool _isNative) public {
        _native = _isNative;
    }

    function setCounterpart(bytes32 _counterpart) public {
        counterpart = _counterpart;
    }

    function _resolveOrder(GaslessCrossChainOrder memory order, bytes calldata)
        internal
        view
        override
        returns (ResolvedCrossChainOrder memory, bytes32 orderId, uint256 nonce)
    {
        return _resolvedOrder(order.user, order.openDeadline, order.fillDeadline, order.orderData);
    }

    function _resolveOrder(OnchainCrossChainOrder memory order)
        internal
        view
        override
        returns (ResolvedCrossChainOrder memory, bytes32 orderId, uint256 nonce)
    {
        return _resolvedOrder(msg.sender, type(uint32).max, order.fillDeadline, order.orderData);
    }

    function _resolvedOrder(
        address _sender,
        uint32 _openDeadline,
        uint32 _fillDeadline,
        bytes memory _orderData
    )
        internal
        view
        virtual
        returns (ResolvedCrossChainOrder memory resolvedOrder, bytes32 orderId, uint256 nonce)
    {
        // this can be used by the filler to approve the tokens to be spent on destination
        Output[] memory maxSpent = new Output[](1);
        maxSpent[0] = Output({
            token: _native ? TypeCasts.addressToBytes32(address(0)) : TypeCasts.addressToBytes32(outputToken),
            amount: 100,
            recipient: counterpart,
            chainId: _destination
        });

        // this can be used by the filler know how much it can expect to receive
        Output[] memory minReceived = new Output[](1);
        minReceived[0] = Output({
            token: _native ? TypeCasts.addressToBytes32(address(0)) : TypeCasts.addressToBytes32(inputToken),
            amount: 100,
            recipient: bytes32(0),
            chainId: _origin
        });

        // this can be user by the filler to know how to fill the order
        FillInstruction[] memory fillInstructions = new FillInstruction[](1);
        fillInstructions[0] = FillInstruction({
            destinationChainId: _destination,
            destinationSettler: counterpart,
            originData: _orderData
        });

        orderId = keccak256("someId");

        resolvedOrder = ResolvedCrossChainOrder({
            user: _sender,
            originChainId: _origin,
            openDeadline: _openDeadline,
            fillDeadline: _fillDeadline,
            orderId: orderId,
            minReceived: minReceived,
            maxSpent: maxSpent,
            fillInstructions: fillInstructions
        });

        nonce = 1;
    }

    function _getOrderId(GaslessCrossChainOrder memory order) internal pure override returns (bytes32) {
        return keccak256(order.orderData);
    }

    function _getOrderId(OnchainCrossChainOrder memory order) internal pure override returns (bytes32) {
        return keccak256(order.orderData);
    }

     function _fillOrder(bytes32 _orderId, bytes calldata _originData, bytes calldata _fillerData) internal override virtual {
        filledId = _orderId;
        filledOriginData = _originData;
        filledFillerData = _fillerData;

        OrderData memory orderData = OrderEncoder.decode(_originData);

        // if (_orderId != OrderEncoder.id(orderData)) revert InvalidOrderId();
        // if (block.timestamp > orderData.fillDeadline) revert OrderFillExpired();
        // if (orderData.destinationDomain != _localDomain()) revert InvalidOrderDomain();

        address filledOutputToken = TypeCasts.bytes32ToAddress(orderData.outputToken);
        address recipient = TypeCasts.bytes32ToAddress(orderData.recipient);

        if (filledOutputToken == address(0)) {
            if (orderData.amountOut != msg.value) revert InvalidNativeAmount();
            Address.sendValue(payable(recipient), orderData.amountOut);
        } else {
            IERC20(filledOutputToken).transferFrom(msg.sender, recipient, orderData.amountOut);
        }
    }

    function _settleOrders(
        bytes32[] calldata _orderIds,
        bytes[] memory _ordersOriginData,
        bytes[] memory _ordersFillerData
    )
        internal
        override
    {
        settledOrderIds = _orderIds;
        settledOrdersOriginData = _ordersOriginData;
        settledOrdersFillerData = _ordersFillerData;
    }

    function _refundOrders(GaslessCrossChainOrder[] memory, bytes32[] memory _orderIds) internal override {
        refundedOrderIds = _orderIds;
    }

    function _refundOrders(OnchainCrossChainOrder[] memory, bytes32[] memory _orderIds) internal override {
        refundedOrderIds = _orderIds;
    }

    function _localDomain() internal view override returns (uint32) {
        return _origin;
    }

    function localDomain() public view returns (uint32) {
        return _localDomain();
    }
}

contract Base7683ForTestNative is Base7683ForTest {
    constructor(
        address _permit2,
        uint32 _local,
        uint32 _remote,
        address _inputToken,
        address _outputToken
    )
        Base7683ForTest(_permit2, _local, _remote, _inputToken, _outputToken)
    { }

    function _resolvedOrder(
        address _sender,
        uint32 _openDeadline,
        uint32 _fillDeadline,
        bytes memory _orderData
    )
        internal
        view
        override
        returns (ResolvedCrossChainOrder memory resolvedOrder, bytes32 orderId, uint256 nonce)
    {
        // this can be used by the filler to approve the tokens to be spent on destination
        Output[] memory maxSpent = new Output[](1);
        maxSpent[0] = Output({
            token: TypeCasts.addressToBytes32(address(0)),
            amount: 100,
            recipient: counterpart,
            chainId: _destination
        });

        // this can be used by the filler know how much it can expect to receive
        Output[] memory minReceived = new Output[](1);
        minReceived[0] = Output({
            token: TypeCasts.addressToBytes32(address(0)),
            amount: 100,
            recipient: bytes32(0),
            chainId: _origin
        });

        // this can be user by the filler to know how to fill the order
        FillInstruction[] memory fillInstructions = new FillInstruction[](1);
        fillInstructions[0] = FillInstruction({
            destinationChainId: _destination,
            destinationSettler: counterpart,
            originData: _orderData
        });

        orderId = keccak256("someId");

        resolvedOrder = ResolvedCrossChainOrder({
            user: _sender,
            originChainId: _origin,
            openDeadline: _openDeadline,
            fillDeadline: _fillDeadline,
            orderId: orderId,
            minReceived: minReceived,
            maxSpent: maxSpent,
            fillInstructions: fillInstructions
        });

        nonce = 1;
    }
}

contract SolverVaultTest is Test {
    uint32 internal origin = 1;
    uint32 internal destination = 2;
    uint256 internal amountIn = 100_000_000_000;
    uint256 internal amountOut = 90_000_000_000;
    uint256 internal senderNonce = 1;

    SolverVault public vault;
    ETHSolverVault public ethVault;
    Endpoint public endpoint;
    MockToken public inputToken;
    MockToken public outputToken;
    WETHMock public wrappedNativeToken;
    Base7683ForTest public intentEndpoint;

    address payable public solver = payable(makeAddr("solver"));
    address payable public depositor = payable(makeAddr("depositor"));
    address payable public swapper = payable(makeAddr("swapper"));
    address internal counterpart = makeAddr("counterpart");

    address permit2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    function setUp() public {
        inputToken = new MockToken("Input Mock Token", "IMOCK", 18, 1_000_000_000_000);
        outputToken = new MockToken("Output Mock Token", "OMOCK", 18, 1_000_000_000_000);
        wrappedNativeToken = new WETHMock();
        endpoint = new Endpoint();
        vault = new SolverVault(IERC20(outputToken), address(endpoint), address(this));
        ethVault = new ETHSolverVault(IWETH(wrappedNativeToken), address(endpoint), address(this));
        intentEndpoint = new Base7683ForTest(permit2, origin, destination, address(inputToken), address(outputToken));
        // intentEndpointNative = new Base7683ForTestNative(permit2, origin, destination, address(0), address(0));
        
        // set up vault and solver
        endpoint.addVault(address(vault));
        endpoint.addVault(address(ethVault));
        endpoint.addSolver(solver);

        // set up depositor and swapper
        inputToken.mint(swapper, 100_000_000_000);
        outputToken.mint(depositor, 100_000_000_000);
        
        // send native token to depositor
        vm.deal(depositor, 100_000_000_000);

        // set up intent endpoint
        // intentEndpoint.setCounterpart(_addressToBytes32(counterpart));
    }

    function test_deposit() public {
        vm.startPrank(depositor);

        outputToken.approve(address(vault), 100_000_000_000);
        vault.deposit(100_000_000_000, depositor);

        assertEq(outputToken.balanceOf(depositor), 0);
        assertEq(vault.balanceOf(depositor), 100_000_000_000);
        assertEq(outputToken.balanceOf(address(vault)), 100_000_000_000);

        vm.stopPrank();
    }

    function test_depositNative() public {
        vm.startPrank(depositor);
        ethVault.depositNative{value: 100_000_000_000}(100_000_000_000, depositor);
        
        // check if the native token is deposited
        assertEq(depositor.balance, 0);
        assertEq(ethVault.balanceOf(depositor), 100_000_000_000);
        assertEq(wrappedNativeToken.balanceOf(address(ethVault)), 100_000_000_000);
        vm.stopPrank();
    }

    function test_withdraw() public {
        vm.startPrank(depositor);
        outputToken.approve(address(vault), 100_000_000_000);
        vault.deposit(100_000_000_000, depositor);

        vault.withdraw(100_000_000_000, depositor, depositor);

        assertEq(outputToken.balanceOf(depositor), 100_000_000_000);
        assertEq(vault.balanceOf(depositor), 0);
        assertEq(outputToken.balanceOf(address(vault)), 0);

        vm.stopPrank();
    }

    function test_withdrawNative() public {
        vm.startPrank(depositor);
        ethVault.depositNative{value: 100_000_000_000}(100_000_000_000, depositor);
        ethVault.withdrawNative(100_000_000_000, depositor, depositor);
    
        assertEq(depositor.balance, 100_000_000_000);
        assertEq(ethVault.balanceOf(depositor), 0);
        assertEq(wrappedNativeToken.balanceOf(address(ethVault)), 0);

        vm.stopPrank();
    }

    function test_borrow() public {
        vm.startPrank(depositor);
        outputToken.approve(address(vault), 100_000_000_000);
        vault.deposit(100_000_000_000, depositor);
        vm.stopPrank();

        OrderData memory order = OrderData(
            TypeCasts.addressToBytes32(swapper),
            TypeCasts.addressToBytes32(swapper),
            TypeCasts.addressToBytes32(address(inputToken)),
            TypeCasts.addressToBytes32(address(outputToken)),
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
        bytes32 orderId = "test";
        bytes memory fillerData = abi.encode(TypeCasts.addressToBytes32(solver));

        vm.startPrank(solver);
        vm.expectEmit(false, false, false, true);
        emit Filled(orderId, orderData, fillerData);

        endpoint.requestBorrowForERC7683(address(vault), address(intentEndpoint), orderId, orderData, fillerData);

        assertEq(intentEndpoint.orderStatus(orderId), intentEndpoint.FILLED());

        (bytes memory _originData, bytes memory _fillerData) = intentEndpoint.filledOrders(orderId);

        assertEq(_originData, orderData);
        assertEq(_fillerData, fillerData);

        assertEq(intentEndpoint.filledId(), orderId);
        assertEq(intentEndpoint.filledOriginData(), orderData);
        assertEq(intentEndpoint.filledFillerData(), fillerData);

        assertEq(outputToken.balanceOf(address(vault)), 10_000_000_000);
        assertEq(outputToken.balanceOf(address(swapper)), 90_000_000_000);
        vm.stopPrank();
    }

    function test_borrowNative() public {
        vm.startPrank(depositor);
        ethVault.depositNative{value: 100_000_000_000}(100_000_000_000, depositor);
        vm.stopPrank();

        OrderData memory order = OrderData(
            TypeCasts.addressToBytes32(swapper),
            TypeCasts.addressToBytes32(swapper),
            TypeCasts.addressToBytes32(address(inputToken)),
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
        bytes32 orderId = "test";
        bytes memory fillerData = abi.encode(TypeCasts.addressToBytes32(solver));

        vm.startPrank(solver);
        vm.expectEmit(false, false, false, true);
        emit Filled(orderId, orderData, fillerData);

        endpoint.requestBorrowForERC7683(address(ethVault), address(intentEndpoint), orderId, orderData, fillerData);

        assertEq(intentEndpoint.orderStatus(orderId), intentEndpoint.FILLED());

        (bytes memory _originData, bytes memory _fillerData) = intentEndpoint.filledOrders(orderId);

        assertEq(_originData, orderData);
        assertEq(_fillerData, fillerData);

        assertEq(intentEndpoint.filledId(), orderId);
        assertEq(intentEndpoint.filledOriginData(), orderData);
        assertEq(intentEndpoint.filledFillerData(), fillerData);

        assertEq(wrappedNativeToken.balanceOf(address(ethVault)), 10_000_000_000);
        assertEq(swapper.balance, 90_000_000_000);
        vm.stopPrank();
    }
}
