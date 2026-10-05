// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title ClassToken — supply fijo 7_000, sin mint posterior
contract ClassToken is ERC20 {
    uint256 public constant TOTAL_SUPPLY = 7_000 ether;

    constructor(address recipient) ERC20("Class Token", "CLASS") {
        _mint(recipient, TOTAL_SUPPLY);
    }
}
