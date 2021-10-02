// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./FishyToken.sol";
import "./Fishy.sol";
import "./HasAdmin.sol";

contract FishyTank is Ownable, HasAdmin {
  using SafeMath for uint256;
  using SafeMath for uint8;

  uint256 public MAX_PRESALE_NFT = 5000;
  uint256 public FISHY_PRICE = 250;

  uint256 public publicSaleTime = 1633280400;

  uint256 private currentSold = 0;

  mapping(uint256 => bool) isBreedable;

  event UserTopUpEgg (address user, uint256 amount);

  bool private isPackageOpenSale = true;

  constructor() {
  }

  function getRemainingFishyPackage() view public returns(uint256) {
    return MAX_PRESALE_NFT - currentSold;
  }

  function getPackageOpenSale() view external returns(bool) {
    return isPackageOpenSale;
  }

  function setPackageOpenSale(bool value) external onlyOwner {
    isPackageOpenSale = value;
  }

  function setMaxPresale(uint256 value) public onlyOwner {
    MAX_PRESALE_NFT = value;
  }

  function setPackagePrice(uint256 price) public onlyOwner {
    FISHY_PRICE = price;
  }

  function getPublicSaleTime() view external returns(uint256) {
    return publicSaleTime;
  }

  function setPublicSaleTime(uint256 value) external onlyOwner {
    publicSaleTime = value;
  }

  function claimNFT(address user, address fishyAddress, address payable tokenAddress) external {
    require(isPackageOpenSale, "Sale Closed");
    require(block.timestamp > publicSaleTime, "Sale Not Open Yet");
    require(currentSold < MAX_PRESALE_NFT, "Exceed Max Presale");
    require(FishyToken(tokenAddress).balanceOf(user) >= FISHY_PRICE * (10 ** 18), "Not enough FTE");
    FishyToken(tokenAddress).transferFrom(user, owner(), FISHY_PRICE * (10 ** 18));
    Fishy(fishyAddress).claim(user);
    currentSold++;
  }

  function giveBirth(address user, address fishyAddress, uint256 maleId, uint256 femaleId) external {
    require(isBreedable[femaleId] == true, "This Female Fishy can't give birth");
    Fishy fishy = Fishy(fishyAddress);                 
    fishy.giveBirth(user, maleId, femaleId);
    isBreedable[femaleId] = false;
  }

  function isFishBreedable(uint256 femaleId) view external returns(bool) {
    return isBreedable[femaleId] || false;
  }

  function setBreedable(uint256 femaleId) external onlyAdmin {
    isBreedable[femaleId] = true;
  }

  function userLevelUpFishy(address user, address fishyAddress, uint256 tokenId) external onlyAdmin {
    Fishy fishy = Fishy(fishyAddress);
    require(fishy.ownerOf(tokenId) == user, "only the owner of this Fishy can do this");

    // Level Up
    fishy.levelUpFishy(tokenId);
  }

  function setFishyFree(address user, uint256 tokenId, address fishyAddress) external {
    Fishy fishy = Fishy(fishyAddress);
    require(fishy.ownerOf(tokenId) == user, "Only owner can do this");
    fishy.burn(tokenId);
  }

  function userFusionFishy(address user, address fishyAddress, uint256 tokenIdA, uint256 tokenIdB, uint256 maxPercent) external onlyAdmin {
    Fishy fishy = Fishy(fishyAddress);
    fishy.fusion(user, tokenIdA, tokenIdB, maxPercent);
  }

  function userFusionFishyWithLock(address user, address fishyAddress, uint256 tokenIdA, uint256 tokenIdB, uint256 lockId, uint256 maxPercent) external onlyAdmin {
    Fishy fishy = Fishy(fishyAddress);
    fishy.fusionWithLock(user, tokenIdA, tokenIdB, lockId, maxPercent);
  }
}