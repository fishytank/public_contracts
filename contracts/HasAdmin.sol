// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract HasAdmin is Ownable {
  event AdminAdded(address admin);
  event AdminRemoved(address indexed _oldAdmin);

  // address public admin;
  address[] private knownedAdmins;
  mapping(address => bool) admins;

  modifier onlyAdmin {
    require(admins[msg.sender] == true, "HasAdmin: not admin");
    _;
  }

  constructor() {
    admins[msg.sender] = true;
    emit AdminAdded(msg.sender);
  }

  function isAdmin() view external returns (bool) {
    return admins[msg.sender];
  }

  function allKnownedAdmin() view external returns (address[] memory) {
    return knownedAdmins;
  }

  function addAdmin(address _newAdmin) external onlyOwner {
    require(_newAdmin != address(0), "HasAdmin: new admin is the zero address");
    emit AdminAdded(_newAdmin);
    admins[_newAdmin] = true;
  }

  function addAdmins(address[] memory _newAdmins) external onlyOwner {
    for (uint256 index = 0; index < _newAdmins.length; index++) {
      if (!admins[address(_newAdmins[index])]) {
        admins[address(_newAdmins[index])] = true;
      }
    }
  }

  function removeAdmin(address _admin) external onlyOwner {
    emit AdminRemoved(_admin);
    admins[_admin] = false;
  }


}