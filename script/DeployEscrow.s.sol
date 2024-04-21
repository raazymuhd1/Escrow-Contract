// SPDX-Licenses-Identifier: MIT;
pragma solidity ^0.8.13;

import { Script, console } from "forge-std/Script.sol";
import { Escrow } from "../src/Escrow.sol";

contract DeployEscrow is Script {
    Escrow escrow;

    address constant OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function run() public returns(Escrow escrow_) {
        vm.broadcast();
        escrow = new Escrow(OWNER);
        escrow_ = escrow;
    }
}