// SPDX-Licenses-Identifier: MIT;
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { DeployEscrow } from "../script/DeployEscrow.s.sol";
import { Escrow } from "../src/Escrow.sol";

contract EscrowTest is Test {
    Escrow escrow;
    DeployEscrow deployer;

    address USER = makeAddr("USER");
    address DEVELOPER = makeAddr("DEV");
    uint256 constant PROJECT_FEE = 0.05 ether;

    bytes32 public hashMsg = keccak256("HASHED_MESSAGE");

    function setUp() public {
        deployer = new DeployEscrow();
        escrow = deployer.run();

        vm.deal(USER, 10 ether);
    }

    function test_createProject() public {
        vm.startPrank(USER);
        Escrow.Project memory newProject = Escrow.Project({
            projectId: 0,
            owner: USER,
            developer: DEVELOPER,
            title: "make a presale contract",
            description: "Requirements: make a presale contract",
            budget: 0.5 ether,
            deadline: 7 days
        });
        (bool status, Escrow.Project memory project ) = escrow.openProject{value: PROJECT_FEE}(newProject);
        uint256 balance = escrow.getBalance();
        vm.stopPrank();
        console.log(balance);

        assert(status == true);
        assert(balance > 0);
    }

    function test_messageHashed() public view returns(bytes32) {
        console.logBytes32(hashMsg);
        return hashMsg;
    }
}