// SPDX-Licenses-Identifier: MIT;
pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract RefferalSystem  {
    // ERRORS *************
    error RefferalSystem_NotOwner();
    error RefferalSystem_InvalidAddr();
    error RefferalSystem_ContractBalanceIsZero();
    error RefferalSystem_ZeroBonus();
    error RefferalSystem_ZeroRefferal();
    error RefferalSystem_DistributionRewardsFailed();

    // STATE VARIABLES *************
    address private immutable i_owner;
    uint256 private constant BONUS_PERCENTAGE = 5; // 5% bonus
    // this total bonus can be changed too
    uint256 private constant REWARD_SUPPLY = 5000_000 * 1e18; // total refferal bonus being allocated

    // TYPE DECLARATIONS ***********
    IERC20 token;

    mapping(address user => User detail) private userDetail;

    // EVENTS *****************
    event UserRefIncremented(address indexed user_, uint256 indexed refCount_);
    event RewardDistributed(address indexed distributor, uint256 indexed rewardAmount);
    event TokenWithdrew(address indexed to_, uint256 indexed amount_);

    constructor(address owner_, address tokenContract) {
        i_owner = owner_;
        token = IERC20(tokenContract);
    }

    struct User {
        address wallet;
        string refLink;
        uint256 refCount;
        uint256 totalBonus;
    }

    // MODIFIERS ******************
    modifier OnlyOwner() {
        if(msg.sender != i_owner) revert RefferalSystem_NotOwner();
        _;
    }

    modifier InvalidAddress() {
        if(msg.sender == address(0)) revert RefferalSystem_InvalidAddr();
        _;
    }

       // ------------------------ EXTERNAL & INTERNAL FUNCTIONS ----------------------

    /**
    * @dev this function is meant to record user refferal info and refCount
    * frontend dev suppose to send user address and ref link to this function when someone use
    * the ref link
    * @param user_ - user wallet address that on the link 
    * @param refLink_ - a link that associated with the user
     */
    function incrementRef(address user_, string memory refLink_) external InvalidAddress returns(User memory) {
        if(user_ == address(0)) revert RefferalSystem_InvalidAddr();
        string memory userAddressStr = Strings.toHexString(uint256(uint160(user_)), 20);
        // this link https://all4one.vercel.app can be replace according to ur need
        string memory linkType = string.concat("https://all4one.vercel.app/ref?user=", userAddressStr);
        bytes32 link_ = keccak256(abi.encodePacked(refLink_));
        bytes32 expectedLink_ = keccak256(abi.encodePacked(linkType));
        // user rewards
        uint256 totalRewards = 0;

        //  check if the 
        if(link_ == expectedLink_) {
            userDetail[user_] = User({
                wallet: user_,
                refLink: linkType,
                refCount:  userDetail[user_].refCount + 1,
                totalBonus: totalRewards
            });
            totalRewards = _calculateReward(user_); 
            userDetail[user_].totalBonus = totalRewards;
        }

        // emit the event user incremented
        emit UserRefIncremented(user_, userDetail[user_].refCount);

    }

    /**
     * @dev this function use to distribute user rewards 
     * @param user_ - user address
     */
    function distributeReward(address user_) external OnlyOwner InvalidAddress returns(bool, uint256) {
        if(userDetail[user_].totalBonus <= 0) revert RefferalSystem_ZeroBonus();
        if(token.balanceOf(address(this)) <= 0) revert RefferalSystem_ContractBalanceIsZero();

        userDetail[user_].totalBonus = 0;
        bool success = token.transferFrom(address(this), user_, userDetail[user_].totalBonus);

        if(!success) revert RefferalSystem_DistributionRewardsFailed();
        emit RewardDistributed(i_owner, userDetail[user_].totalBonus);
        return (success, userDetail[user_].totalBonus);
    }
    /**
    * @dev this function to calculate the refferal bonus/reward based on the * total refcount
    * @param user_ - user address
     */
    function _calculateReward(address user_) internal returns(uint256 rewards_) {
        if(userDetail[user_].refCount <= 0) {
           userDetail[user_].refCount = 0;
        }
        uint256 totalRefs = userDetail[user_].refCount;
        uint256 bonusPerRef = ((REWARD_SUPPLY * BONUS_PERCENTAGE) / 100) / 5000_000;

        if(totalRefs <= 0) revert RefferalSystem_ZeroRefferal();
        rewards_ = totalRefs * bonusPerRef;
       
    }


    function withdrawToken() external OnlyOwner InvalidAddress() {
        uint256 contractTokenBalance = token.balanceOf(address(this));
         if(contractTokenBalance <= 0) revert RefferalSystem_ContractBalanceIsZero();
         token.transferFrom(address(this), i_owner, contractTokenBalance);
         emit TokenWithdrew(i_owner, contractTokenBalance);
    }

    function allocateRefferalBonus() external OnlyOwner {
    }

    function getUserDetail(address user_) external returns(User memory user) {
        user = userDetail[user_];
    }
}

