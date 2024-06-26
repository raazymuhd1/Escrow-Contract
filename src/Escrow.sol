pragma solidity ^0.8.13;

/**
 * @title Escrow Contract
 * @dev This contract provides a basic escrow mechanism, allowing two parties to securely engage in transactions with each other.
 *      It ensures that the seller receives payment only after the buyer confirms receipt of the item or service.
 *      The contract is designed to be generic and can be used for various types of transactions where escrow is required.
 *      It supports depositing funds into escrow, releasing funds to the seller, and refunding the buyer.
 *      This contract does not inherently support dispute resolution and assumes that any disputes will be resolved externally.
 */


contract Escrow {
    // CUSTOM ERRORS
    error Escrow_NotOwner();
    error Escrow_InvalidAddress();
    error Escrow_OpenProjectFailed();
    error Escrow_NotEnoughFee();
    error Escrow_FundsNotRelased();
    error Escrow_ProjectNotCompleted();
    error Escrow_DeadlineIsOver();

    // ---------------- STATE VARIABLES ---------------------
   address private s_treasuryWallet;
   uint256 private constant PROJECT_FEE = 0.02 ether;
   ProjectState private s_projectState = ProjectState.Started;

    // ------------------- MAPPINGS ------------------------
   mapping(address projectOwner => Project) private s_project;

//   ----------------------- EVENTS --------------------------
   event ProjectCreated(address indexed owner_, Project indexed project);
   event FundReleased(address indexed realeasedTo, uint256 indexed amount);

   constructor(address _owner) {
      s_treasuryWallet = _owner;
   }

    receive() external payable {}
    // fallback() external payable {}

    // ------------------ STRUCT ------------------------
   struct Project {
       uint16 projectId;
       address owner;
       address developer;
       string title;
       string description;
       uint256 budget;
       uint256 deadline;
   }

   enum ProjectState {
       Completed,
       Canceled,
       Started
   } 

    // MODIFIERS ***********************
   modifier OnlyOwner() {
       if(msg.sender != s_treasuryWallet) revert Escrow_NotOwner();
       _;
   }

   modifier StateCompleted() {
      if(s_projectState != ProjectState.Completed) revert Escrow_ProjectNotCompleted();
      _;
   }
   

    // ----------------------- EXTERNAL & INTERNAL ---------------------------

    function _assignProject(Project calldata projectDetails) internal returns(Project memory project) {
         
          project = Project({
          projectId: projectDetails.projectId,
          owner: msg.sender,
          developer: msg.sender,
          title: projectDetails.title,
          description: projectDetails.description,
          budget: s_project[msg.sender].budget + msg.value,
          deadline: projectDetails.deadline
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
     * @dev this function only can be call by contract owner to release the project funds after client confirm that project is completed
     * @param owner_ - project owner address
     * @param releaseTo - to where the funds should release to
     */
   function releaseFunds(address owner_, address payable releaseTo) external payable OnlyOwner StateCompleted returns(bool released) {
       Project memory project = s_project[owner_]; 
       bool fundReleased;
       if(block.timestamp >= project.deadline) revert Escrow_DeadlineIsOver();
       if(project.budget != 0 && releaseTo != address(0)) { 
           ( fundReleased, ) = payable(releaseTo).call{value: project.budget}("");
       }
       if(!fundReleased) revert Escrow_FundsNotRelased();

       emit FundReleased(releaseTo, project.budget);
       released = fundReleased;
   }

   /**
    * 
    */
    function changeTreasuryWallet(address newWallet) external OnlyOwner {
       s_treasuryWallet = newWallet;
    }


   function getBalance() external returns(uint256 balance) {
      balance = address(this).balance;
   }



}