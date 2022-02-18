// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestCoin is ERC20 {

    constructor(address _vestContract) ERC20("Synapse", "SYN") {
        _mint(_vestContract, 100000 * 10**18);
    }
}