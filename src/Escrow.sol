// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Escrow Contract
 * @notice THIS CONTRACT IS NOT PRODUCTION READY YET, WILL BE TESTED IN THE FUTURE
 * @dev This contract provides a basic escrow mechanism, allowing two parties to securely engage in transactions with each other.
 *      It ensures that the developer receives payment only after the client confirms the project is completed.
 *      The contract is designed to be use for transactions between client and developer.
 *      It supports depositing funds into escrow, releasing funds to the developer, and refunding the client.
 *      This contract does not inherently support dispute resolution and assumes that any disputes will be resolved externally.
 */
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract Escrow is Ownable {
    // CUSTOM ERRORS
    error Escrow_NotOwner();
    error Escrow_InvalidAddress();
    error Escrow_InvalidCaller();
    error Escrow_OpenProjectFailed();
    error Escrow_NotEnoughFeeOrBudget();
    error Escrow_FundsNotRelased();
    error Escrow_ProjectNotCompletedOrCanceled();
    error Escrow_DeadlineIsOver();
    error Escrow_NotProjectsOwner();
    error Escrow_NoProjectOwned();
    error Escrow_ProjectNotOverYet();
    error Escrow_RefundFailed();
    error Escrow_ReleasingFundFailed();
    error Escrow_BudgetDepositFailed();
    error Escrow_ProjectHasBeenCompleted();

    // ---------------- STATE VARIABLES ---------------------
   uint256 private constant ESCROW_FEE = 0.02 ether;

    // ------------------- MAPPINGS ------------------------
   mapping(address projectOwner => Project) private s_project;

//   ----------------------- EVENTS --------------------------
   event ProjectCreated(address indexed owner_, Project indexed project);
   event FundReleased(address indexed realeasedTo, uint256 indexed amount);
   event ProjectStarted(address owner, ProjectState state);
   event ProjectHasBeenRefunded(address projectOwner, uint256 budget);

   constructor(address _intialOwner_) Ownable(_intialOwner_) {
   }

    receive() external payable {}
    // fallback() external payable {}

    // ----------------------------------------- STRUCTs ------------------------------------------------------
   struct Project {
       bytes32 projectId;
       address payable owner;
       address payable developer;
       string title;
       string description;
       uint256 budget;
       uint256 deadline;
       ProjectState state;
   }

     // ----------------------------------------- ENUMs ------------------------------------------------------
   enum ProjectState {
       Completed,
       Canceled,
       Started
   } 

     // ----------------------------------------- MODIFIERs ------------------------------------------------------
   modifier StateCompleted() {
      Project memory project = getProjectByOwner(msg.sender);
      if(project.state != ProjectState.Completed || project.state == ProjectState.Canceled) revert Escrow_ProjectNotCompletedOrCanceled();
      _;
   }
   
   modifier InvalidCaller() {
      if(msg.sender == address(0)) revert Escrow_InvalidCaller();
      _;
   }

    // ----------------------- EXTERNAL & INTERNAL ---------------------------

    function _assignProject(Project calldata projectDetails) private view returns(Project memory project) {
         
          project = Project({
          projectId: projectDetails.projectId,
          owner: payable(msg.sender),
          developer: payable(projectDetails.developer),
          title: projectDetails.title,
          description: projectDetails.description,
          budget: msg.value - ESCROW_FEE,
          deadline: block.timestamp,
          state: projectDetails.state
       });

    }

    /**
        @dev this function uses for open a project between client and developer
        @param projectDetails - project details
        @return bool - only returns true if project creation is succeeded
        @return Project - returns the project that was created
     */

    /**
        @dev user will have to deposit the budget using native token (ETH, BNB, etc)
        @param projectDetails - a project details in struct format
        @return bool - true/false
        @return Project - return a project created
     */
   function openProject(Project calldata projectDetails) external payable InvalidCaller returns(bool, Project memory) {
    //    uint256 expectedTobeDeposited = projectDetails.budget + ESCROW_FEE;
       if(msg.value <= 0) revert Escrow_NotEnoughFeeOrBudget();
       if(msg.sender == address(0)) revert Escrow_InvalidAddress();
      // deposit budget into this contract
      (bool deposited, ) = payable(address(this)).call{value: msg.value + ESCROW_FEE}("");  
       
       if(!deposited) revert Escrow_BudgetDepositFailed();

        // assigns a project 
       s_project[msg.sender] = _assignProject(projectDetails);
       emit ProjectCreated(msg.sender, s_project[msg.sender]); 
       return (true, s_project[msg.sender]);
   }

    /**
        @dev checking whether the deadline is over or not
        @param project - The project based on caller;
     */
    function _isDeadlineOver(Project memory project) private view returns(bool isOver) {
          if(block.timestamp >= project.deadline) {
             isOver = true;
          }
          isOver = false;
    }



    /**
     * @dev this function only can be call by contract owner to release the project funds after client confirm that project is completed
     * @param projectOwner_ - project owner address
     */
   function releaseFunds(address projectOwner_, address dev_) external payable StateCompleted returns(bool released) {
       Project memory project = getProjectByOwner(projectOwner_); 
       bool fundReleased;

       if(_isDeadlineOver(project) == true) revert Escrow_DeadlineIsOver();
       if(project.budget != 0 && projectOwner_ != address(0) && msg.sender == project.owner) { 
           ( fundReleased, ) = payable(dev_).call{value: project.budget}("");

           if(!fundReleased) revert Escrow_ReleasingFundFailed();
         //   resetting project's budget to zerp
           s_project[projectOwner_].budget = 0;

           emit FundReleased(dev_, project.budget);
           released = fundReleased;
       }

       released = fundReleased;
   }

   function confirmProjectIsCompleted() external returns(bool confirmed) {
        Project memory project = getProjectByOwner(msg.sender);
        if(msg.sender != project.owner) revert Escrow_NotOwner();
        if(project.state == ProjectState.Completed) {
            revert Escrow_ProjectHasBeenCompleted();
            confirmed = false;
        }

        project.state = ProjectState.Completed;
        confirmed = true;
   }

   
   function cancelAndRefund() external returns(bool refunded) {
       Project memory project = getProjectByOwner(msg.sender);
       if(project.owner == address(0)) revert Escrow_NoProjectOwned();
       if(block.timestamp < project.deadline || project.state == ProjectState.Completed) revert Escrow_ProjectNotOverYet();
       project.budget = 0;
       ( refunded, ) = project.owner.call{value: project.budget}("");
       
       if(!refunded) revert Escrow_RefundFailed();
       emit ProjectHasBeenRefunded(project.owner, project.budget);
       refunded;
   }

   function setState() external returns(bool stateSet) {
      Project memory project = s_project[msg.sender];
      if(msg.sender != project.owner) revert Escrow_NotProjectsOwner();

      project.state = ProjectState.Started;
      stateSet = true;
      emit ProjectStarted(msg.sender, project.state);
   }

    /**
      @dev get total funds in this contract
     */
   function getBalance() external view returns(uint256 balance) {
      balance = address(this).balance;
   }

   function getProjectByOwner(address _owner) public view returns(Project memory project) {
       project = s_project[_owner];
   }

   function getProjectBudgets() external view returns(uint256 budget_) {
      Project memory project = getProjectByOwner(msg.sender);
      budget_ = project.budget;
   }

  function geProjectState() public view returns(ProjectState state) {
    Project memory _project = s_project[msg.sender];
    state = _project.state;
  }

}