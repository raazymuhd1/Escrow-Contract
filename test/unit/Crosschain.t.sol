// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test, console  } from "forge-std/Test.sol";
import { Crosschain } from "../../src/Crosschain.sol";
import { DeployCrosschain } from "../../script/DeployCrosschain.s.sol";
import { MockRouter } from "../mocks/MockRouter.sol";
import { MockErc20 } from "../mocks/MockErc20.sol";

contract TestCrosschain is Test {

    Crosschain crosschain;
    DeployCrosschain deployer;
    MockRouter s_router;
    MockErc20 s_linkToken;
    MockErc20 testToken;

    address USER = makeAddr('USER');
    address ZERO_RECEIVER = makeAddr("ZERO");
    address RECEIVER = makeAddr("RECEIVER");
    address SENDER = makeAddr("SENDER");

    uint256 PRECISION = 1e18;

    function setUp() public {

        s_router = new MockRouter();
        s_linkToken = new MockErc20("Link", "LINK");
        testToken = new MockErc20("Test", "Test");
        deployer = new DeployCrosschain();
        crosschain = deployer.run(address(s_router), address(s_linkToken), USER);

        vm.startPrank(USER);
        vm.deal(USER, 10 ether);
        s_linkToken.mintToken(1000_000, USER);
        testToken.mintToken(1000_000, USER);
        testToken.transfer(SENDER, 1000 * PRECISION);

        vm.stopPrank();
    }

    modifier SendFee() {
        vm.prank(USER);
        s_linkToken.transfer(address(crosschain), 5000 * PRECISION);
        _;
    }

    function test_validReceiver() public SendFee {
        uint64 srcChain = 1;
        bool allowed = true;
        uint64 destChain = 96;
        uint256 testAmount = 10 * PRECISION;
        string memory text = "got my token";

        vm.startPrank(USER);
        bool allowedSrcChain = crosschain.allowedSourceChain(srcChain, allowed);
        bool allowedDestChain = crosschain.allowedDestChain(destChain, allowed);
        vm.stopPrank();

        vm.prank(SENDER);
        testToken.approve(address(crosschain), testAmount);
        crosschain.sendMessagePayWithLink(srcChain, destChain, RECEIVER, text, address(testToken), testAmount);

        assertNotEq(RECEIVER, address(0));  
        assertEq(testToken.balanceOf(RECEIVER), testAmount);
    }

}