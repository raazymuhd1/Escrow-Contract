pragma solidity ^0.8.17;

/**
 * @title Escrow Contract
 * @notice THIS CONTRACT IS NOT PRODUCTION READY YET, WILL BE TESTED IN THE FUTURE
 * @dev This contract provides a basic escrow mechanism, allowing two parties to securely engage in transactions with each other.
 *      It ensures that the developer receives payment only after the client confirms the project is completed.
 *      The contract is designed to be use for transactions between client and developer.
 *      It supports depositing funds into escrow, releasing funds to the developer, and refunding the client.
 *      This contract does not inherently support dispute resolution and assumes that any disputes will be resolved externally.
 */


contract Escrow {
    // CUSTOM ERRORS
    error Escrow_NotOwner();
    error Escrow_InvalidAddress();
    error Escrow_OpenProjectFailed();
    error Escrow_NotEnoughFee();
    error Escrow_FundsNotRelased();
    error Escrow_ProjectNotCompletedOrCanceled();
    error Escrow_DeadlineIsOver();
    error Escrow_NotProjectsOwner();
    error Escrow_NoProjectOwned();
    error Escrow_ProjectNotOverYet();
    error Escrow_RefundFailed();

    // ---------------- STATE VARIABLES ---------------------
   uint256 private constant PROJECT_FEE = 0.02 ether;
   address private s_owner;

    // ------------------- MAPPINGS ------------------------
   mapping(address projectOwner => Project) private s_project;

//   ----------------------- EVENTS --------------------------
   event ProjectCreated(address indexed owner_, Project indexed project);
   event FundReleased(address indexed realeasedTo, uint256 indexed amount);
   event ProjectStarted(address owner, ProjectState state);
   event ProjectHasBeenRefunded(address projectOwner, uint256 budget);

   constructor(address _owner) {
      s_owner = _owner;
   }

    receive() external payable {}
    // fallback() external payable {}

    // ------------------ STRUCT ------------------------
   struct Project {
       bytes32 projectId;
       address payable owner;
       address developer;
       string title;
       string description;
       uint256 budget;
       uint256 deadline;
       ProjectState state;
   }

   enum ProjectState {
       Completed,
       Canceled,
       Started
   } 

    // MODIFIERS ***********************
   modifier StateCompleted() {
      Project memory project = s_project[msg.sender];
      if(project.state != ProjectState.Completed || project.state == ProjectState.Canceled) revert Escrow_ProjectNotCompletedOrCanceled();
      _;
   }
   

    // ----------------------- EXTERNAL & INTERNAL ---------------------------

    function _assignProject(Project calldata projectDetails) private returns(Project memory project) {
         
          project = Project({
          projectId: projectDetails.projectId,
          owner: payable(msg.sender),
          developer: msg.sender,
          title: projectDetails.title,
          description: projectDetails.description,
          budget: s_project[msg.sender].budget + msg.value,
          deadline: projectDetails.deadline,
          state: projectDetails.state
       });

    }

    /**
        @dev this function uses for open a project between client and developer
        @param projectDetails - project details
        @return bool - only returns true if project creation is succeeded
        @return Project - returns the project that was created
     */

   function openProject(Project calldata projectDetails) external payable returns(bool, Project memory) {
       if(msg.value <= 0 || msg.value <= PROJECT_FEE) {
           revert Escrow_NotEnoughFee();
       } 
       if(msg.sender == address(0)) revert Escrow_InvalidAddress();
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
     * @param owner_ - project owner address
     * @param releaseTo - to where the funds should release to
     */
   function releaseFunds(address owner_, address payable releaseTo) external payable StateCompleted returns(bool released) {
       Project memory project = s_project[owner_]; 
       bool fundReleased;
       if(_isDeadlineOver(project) == true) revert Escrow_DeadlineIsOver();
       if(project.budget != 0 && releaseTo != address(0)) { 
           ( fundReleased, ) = payable(releaseTo).call{value: project.budget}("");
       }
       if(!fundReleased) revert Escrow_FundsNotRelased();

       emit FundReleased(releaseTo, project.budget);
       released = fundReleased;
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

  function geProjectState() public view returns(ProjectState state) {
    Project memory _project = s_project[msg.sender];
    state = _project.state;
  }

}