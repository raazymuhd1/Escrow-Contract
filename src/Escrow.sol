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
    error Escrow_FundNotRelased();
    error Escrow_ProjectNotCompleted();

    // STATE VARIABLES
   address private immutable i_treasuryWallet;
   uint256 private constant PROJECT_FEE = 0.02 ether;
   ProjectState private s_projectState = ProjectState.Started;

   mapping(address projectOwner => Project) private s_project;

//    EVENTS
   event ProjectCreated(address indexed owner_, Project indexed project);
   event FundReleased(address indexed realeasedTo, uint256 indexed amount);

   constructor(address _owner) {
      i_treasuryWallet = _owner;
   }

    receive() external payable {}
    // fallback() external payable {}

   struct Project {
       uint16 projectId;
       address owner;
       address developer;
       string title;
       string description;
       uint256 budget;
   }

   enum ProjectState {
       Completed,
       Canceled,
       Started
   } 

    // MODIFIERS ***********************
   modifier OnlyOwner() {
       if(msg.sender != i_treasuryWallet) revert Escrow_NotOwner();
       _;
   }

   modifier StateCompleted() {
      if(s_projectState != ProjectState.Completed) revert Escrow_ProjectNotCompleted();
      _;
   }
   
   function openProject(Project memory projectDetails) external payable returns(bool, Project memory) {
       if(msg.value <= 0 || msg.value <= PROJECT_FEE) {
           revert Escrow_NotEnoughFee();
       } 
       if(msg.sender == address(0)) revert Escrow_InvalidAddress();

       s_project[msg.sender] = Project({
          projectId: projectDetails.projectId,
          owner: msg.sender,
          developer: msg.sender,
          title: projectDetails.title,
          description: projectDetails.description,
          budget: s_project[msg.sender].budget + msg.value
       });

       emit ProjectCreated(msg.sender, s_project[msg.sender]); 
       return (true, s_project[msg.sender]);
   }

    /**
     * @dev this function only can be call by contract owner to release the project funds after client confirm that project is completed
     * @param owner_ - project owner address
     * @param releaseTo - to where the funds should release to
     */
   function releaseFunds(address owner_, address payable releaseTo) external payable OnlyOwner StateCompleted returns(bool released) {
       uint256 projectFunds = s_project[owner_].budget; 
       bool fundReleased;
       if(projectFunds != 0 && releaseTo != address(0)) { 
           ( fundReleased, ) = payable(releaseTo).call{value: projectFunds}("");
       }
       if(!fundReleased) revert Escrow_FundNotRelased();

       emit FundReleased(releaseTo, projectFunds);
       released = fundReleased;
   }

   function getBalance() external returns(uint256 balance) {
      balance = address(this).balance;
   }


}