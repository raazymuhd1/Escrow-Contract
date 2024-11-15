// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test, console  } from "forge-std/Test.sol";
import { Crosschain } from "../../src/Crosschain.sol";
import { DeployCrosschain } from "../../script/DeployCrosschain.s.sol";

contract TestCrosschain is Test {

    Crosschain crosschain;
    DeployCrosschain deployer;

    function setUp() public {
        
    }

}