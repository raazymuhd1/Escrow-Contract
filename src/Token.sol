// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    
    // STATE VARIABLES
    address private s_owner;

    constructor(string memory tokenName_, string memory tokenSymbol_) ERC20(tokenName_, tokenSymbol_) {
        s_owner = msg.sender;
    }

    function mintToken(uint256 amount_) public {
        _mint(msg.sender, amount_ * 1e18);
    }

    function sendToken(address to_, uint256 amount_) public {
       transfer(to_, amount_); 
    }
}