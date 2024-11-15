// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Crosschain } from "../src/Crosschain.sol";
import { Script, console } from "forge-std/Script.sol";

contract DeployCrosschain is Script {

    Crosschain crossChain;

    function run(address router_, address linkToken_, address owner_) public returns(Crosschain) {

        vm.broadcast();
        crossChain = new Crosschain(router_, linkToken_, owner_);

        console.log(address(crossChain));
        return crossChain;
    }
}