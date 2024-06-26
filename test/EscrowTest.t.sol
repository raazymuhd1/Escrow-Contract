// SPDX-Licenses-Identifier: MIT;
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { DeployEscrow } from "../script/DeployEscrow.s.sol";
import { Escrow } from "../src/Escrow.sol";

contract EscrowTest is Test {
    Escrow escrow;
    DeployEscrow deployer;

    address payable USER = payable(makeAddr("USER"));
    address payable DEVELOPER = payable(makeAddr("DEV"));
    uint256 constant PROJECT_FEE = 0.02 ether;
    uint256 constant TEST_BUDGET = 1 ether;
    uint256 constant TEST_DEADLINE = 6 days;

    bytes32 public hashMsg = keccak256("HASHED_MESSAGE");

    function setUp() public {
        deployer = new DeployEscrow();
        escrow = deployer.run();

        vm.deal(USER, 10 ether);
    }

    function test_createProject() public {
        bytes32 projectId = keccak256(abi.encodePacked(USER, DEVELOPER, TEST_BUDGET, TEST_DEADLINE));

        vm.startPrank(USER);
        Escrow.Project memory newProject = Escrow.Project({
            projectId: projectId,
            owner: USER,
            developer: DEVELOPER,
            title: "make a presale contract",
            description: "Requirements: make a presale contract",
            budget: TEST_BUDGET,
            deadline: TEST_DEADLINE,
            state: Escrow.ProjectState.Started
        });

        uint256 balanceBefore = escrow.getBalance();
        console.log(balanceBefore);
        (bool projectCreated, ) = escrow.openProject{value: TEST_BUDGET + PROJECT_FEE}(newProject);
        uint256 balanceAfter = escrow.getBalance();
        console.log(balanceAfter);
        console.log(projectCreated);
        console.log(balanceAfter);
        vm.stopPrank();

        assert(projectCreated == true);
        assert(balanceAfter > 0);
    }

    function test_messageHashed() public view returns(bytes32) {
        console.logBytes32(hashMsg);
        return hashMsg;
    }
}