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
        testToken.transfer(SENDER, 1000);

        vm.stopPrank();
    }

    modifier SendFee() {
        vm.prank(USER);
        s_linkToken.transfer(address(crosschain), 500);
        _;
    }

    function test_InvalidReceiver() public SendFee {
        uint64 srcChain = 1;
        bool allowed = true;
        uint64 destChain = 96;
        string memory text = "got my token";

        vm.startPrank(USER);
        uint64 allowedSrcChain = crosschain.allowedSourceChain(srcChain, allowed);
        uint64 allowedDestChain = crosschain.allowedDestChain(destChain, allowed);

        vm.expectRevert("Invalid Receiver");
        crosschain.sendMessagePayWithLink(destChain, ZERO_RECEIVER, text, address(testToken), 100);
        vm.stopPrank();

        // assertEq(ZERO_RECEIVER, address(0)); 
        // assertEq(uint256(destChain), uint256(96));   

    }

}