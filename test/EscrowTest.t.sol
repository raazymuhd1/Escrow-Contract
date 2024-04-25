// // SPDX-Licenses-Identifier: MIT;
// pragma solidity ^0.8.13;

// import { Test, console } from "forge-std/Test.sol";
// import { DeployEscrow } from "../script/DeployEscrow.s.sol";
// import { Escrow } from "../src/Escrow.sol";

// contract EscrowTest is Test {
//     Escrow escrow;
//     DeployEscrow deployer;

//     address USER = makeAddr("USER");
//     uint256 constant PROJECT_FEE = 0.05 ether;

//     function setUp() public {
//         deployer = new DeployEscrow();
//         escrow = deployer.run();

//         vm.deal(USER, 10 ether);
//     }

//     function test_createProject() public {
//         Escrow.Project memory newProject = Escrow.Project({
//             projectId: 0,
//             owner: msg.sender,
//             title: "make a presale contract",
//             description: "Requirements: make a presale contract",
//             budget: 0.5 ether
//         });

//         vm.startPrank(USER);
//         (bool status, Escrow.Project memory project ) = escrow.openProject{value: PROJECT_FEE}(newProject);
//         uint256 balance = escrow.getBalance();
//         vm.stopPrank();
//         console.log(balance);

//         assert(status == true);
//         assert(balance > 0);
//     }
// }