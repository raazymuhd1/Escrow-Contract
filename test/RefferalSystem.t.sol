// SPDX-Licenses-Identifier: MIT;
pragma solidity ^0.8.20;

import { RefferalSystem } from "../src/RefferalSystem.sol";
import { Token } from "../src/Token.sol";
import { Test, console } from "forge-std/Test.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract RefferalSystemTest is Test {
    RefferalSystem refferal;
    Token token;

    address OWNER = makeAddr("OWNER");
    address USER = makeAddr("USER");
    uint256 totalSupply = 5000_000 * 1e18;

    function setUp() public {
        token  = new Token("Testing", "TEST");
        refferal = new RefferalSystem(OWNER, address(token));
        console.log(address(refferal));
        vm.deal(USER, 10 ether);
        vm.startPrank(USER);
        token.mintToken(totalSupply);
        token.sendToken(address(refferal), totalSupply);
        vm.stopPrank();

        console.log(USER);
    }

    function test_incrementRefferal() public {
        string memory userAddressStr = Strings.toHexString(uint256(uint160(USER)), 20);
        string memory refLink = string.concat("https://all4one.vercel.app/ref?user=", userAddressStr);

        vm.startPrank(USER);
        RefferalSystem.User memory userDetailBfore = refferal.getUserDetail(USER);
        RefferalSystem.User memory user = refferal.incrementRef(USER, refLink);
        RefferalSystem.User memory userDetailAfter = refferal.getUserDetail(USER);

        console.log(userDetailBfore.wallet);
        console.log(userDetailAfter.wallet);
    }

    function test_distributeReward() public {
        string memory userAddressStr = Strings.toHexString(uint256(uint160(USER)), 20);
        string memory refLink = string.concat("https://all4one.vercel.app/ref?user=", userAddressStr);

        vm.prank(USER);
        RefferalSystem.User memory user = refferal.incrementRef(USER, refLink);
        vm.prank(OWNER);
        (bool distributed, uint256 bonus) = refferal.distributeReward(USER);
        uint256 userBalance = token.balanceOf(USER);
        console.log(distributed);
        console.log(token.balanceOf(USER));

        assert(userBalance > 0);
    }
}