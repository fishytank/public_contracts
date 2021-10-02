// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FishyToken is ERC20 {

    uint8 private _decimals;

    uint256 private constant _decimalFactor = 10 ** 18;
    uint256 private constant _million = 1000000;

    constructor () ERC20("Fishy Tank Token", "FTE") {
        _decimals = 18;
        _mint(msg.sender, 10 * _million * _decimalFactor);
    }
}