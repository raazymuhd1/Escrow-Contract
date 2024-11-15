// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockErc20 is ERC20 {

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {

    }

    function mintToken(uint256 amount, address to_) public {
        _mint(to_, amount * 10**18);
    }
}