// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Fishy.sol";
import "./FishyToken.sol";

contract FishyMarket is Ownable {
  using SafeMath for uint256;

  uint256 public MARKET_FEE = 10;
  // Market Event
  event FishyAddedToMarket (uint256 id, uint256 tokenId, uint256 date, uint256 price);
  event ItemHaveNewBidder (uint256 id, uint256 tokenId,  uint256 date, address bidder, uint256 bidPrice);
  event ItemSold (uint256 id, uint256 tokenId, uint256 date, uint256 price);
  event ItemBidSold (uint256 id, uint256 tokenId, uint256 date, uint256 price, address bidder);
  event ItemBidCancel (uint256 id, uint256 tokenId, uint256 date, address bidder);

  // bidstatus
  // 0 - available
  // 1 - dealed
  // 2 - ended

  struct Bidder {
    address bidder;
    uint256 price;
    uint256 startDate;
    uint256 endDate;
    uint8 status;
  }

  struct MarketFishy {
    uint256 id;
    uint256 tokenId;
    address seller;
    uint256 price;
    bool isSold;
    bool isRemove;
  }

  mapping (uint256 => MarketFishy) marketFishys;
  uint256 private marketFishysLength = 0;

  mapping (uint256 => uint256) activeItems;
  mapping (uint256 => Bidder[]) activeBidItems;
  mapping (address => uint256[]) bidItems;

  mapping (uint256 => bool) soldItems;
  mapping (uint256 => bool) removeItems;

  uint256 private transferFee = 0;
  uint256 private marketVolume = 0;
  uint256 private marketTransaction = 0;


  mapping (address => bool) isInWhitelist;
  address[] public whitelist;

  constructor() {
  }

  function getWhiteList() view public returns (address[] memory) {
    return whitelist;
  }

  function addWhitelist(address user) internal {
    if (isInWhitelist[user] == false) {
      isInWhitelist[user] = true;
      whitelist.push(user);
    }
  }

  modifier onlyItemOwner(address fishyAddress, uint256 tokenId) {
    Fishy fishy = Fishy(fishyAddress);
    require(fishy.ownerOf(tokenId) == msg.sender, "You are not the owner");
    _;
  } 

  modifier hasApproval(address fishyAddress, uint256 tokenId) {
    Fishy fishy = Fishy(fishyAddress);
    require(fishy.getApproved(tokenId) == address(this), "Owner not approve yet");
    _;
  }

  modifier itemExists(uint256 id) {
    require(id < marketFishysLength + 1 && getItem(id).id == id, "Could not find item");
    _;
  }

  modifier isForSale(uint256 id) {
    require(getItem(id).isSold == false, "Item already sold");
    _;
  }

  modifier isNotRemove(uint256 id) {
    require(getItem(id).isRemove == false, "Item removed");
    _;
  }

  function getTransferFee() view external returns(uint256) {
    return transferFee;
  }

  function getMarketVolume() view external returns(uint256) {
    return marketVolume;
  }

  function getMarketTransaction() view external returns(uint256) {
    return marketTransaction;
  }

  function setMarketFee(uint256 value) public onlyOwner {
    MARKET_FEE = value;
  }

  function getMarketItems() view external returns (uint256) {
    return marketFishysLength;
  }

  function getMarketAvailableItems() view external returns (uint256[] memory) {
    uint256 avaiItemCount = 0;
    for (uint256 i = 1; i < marketFishysLength + 1; i++) {
      if (!soldItems[i] && !removeItems[i]) {
        avaiItemCount++;
      }
    }

    uint256[] memory avaiItemIds = new uint256[](avaiItemCount);
    uint256 index = 0;
    for (uint256 i = 1; i < marketFishysLength + 1; i++) {
      if (!soldItems[i] && !removeItems[i]) {
        avaiItemIds[index] = i;
        index++;
      }
    }

    return avaiItemIds;
  }

  function getMarketSoldItems() view external returns (uint256[] memory) {
    uint256 soldItemCount = 0;
    for (uint256 i = 1; i < marketFishysLength + 1; i++) {
      if (soldItems[i]) {
        soldItemCount++;
      }
    }

    uint256[] memory soldItemIds = new uint256[](soldItemCount);
    uint256 index = 0;
    for (uint256 i = 1; i < marketFishysLength + 1; i++) {
      if (soldItems[i]) {
        soldItemIds[index] = i;
        index++;
      }
    }

    return soldItemIds;
  }

  function getMarketRemovedItems() view external returns (uint256[] memory) {
    uint256 removedItemCount = 0;
    for (uint256 i = 1; i < marketFishysLength + 1; i++) {
      if (removeItems[i]) {
        removedItemCount++;
      }
    }

    uint256[] memory removedItemIds = new uint256[](removedItemCount);
    uint256 index = 0;
    for (uint256 i = 1; i < marketFishysLength + 1; i++) {
      if (soldItems[i]) {
        removedItemIds[index] = i;
        index++;
      }
    }

    return removedItemIds;
  }

  function getMarketItem(uint256 id) view external returns (MarketFishy memory) {
    return getItem(id);
  }

  function getItemBidder(uint256 id) view external returns(Bidder[] memory) {
    require(id >= 0);
    return activeBidItems[id];
  }

  function isInMarket(uint256 tokenId) view external returns(uint256) {
    return activeItems[tokenId];
  }

  function getItem(uint256 id) view internal returns (MarketFishy memory) {
    require(id < marketFishysLength + 1);
    return marketFishys[id];
  }

  function addMarket(address fishyAddress, uint256 tokenId, uint256 price) 
      onlyItemOwner(fishyAddress, tokenId)
      hasApproval(fishyAddress, tokenId)  external returns(uint256) {
    require(activeItems[tokenId] == 0, "Item already up for sale!");
    marketFishysLength++;
    uint256 newItemId = marketFishysLength;
    // marketFishys.push(MarketFishy(newItemId, tokenId, msg.sender, price, false, false));
    marketFishys[newItemId] = MarketFishy(newItemId, tokenId, msg.sender, price, false, false);
    activeItems[tokenId] = newItemId;

    emit FishyAddedToMarket(newItemId, tokenId, block.timestamp, price);
    return newItemId;
  }

  function changePrice(uint256 id, uint256 amount) external {
    uint256 tokenId = getItem(id).tokenId;
    require(getItem(id).seller == msg.sender, "You are not the seller");
    require(activeItems[tokenId] != 0, "Item is not up for sale!");

    marketFishys[id].price = amount;
  }

  function removeFromMarket(uint256 id)
      external {
    uint256 tokenId = getItem(id).tokenId;
    require(getItem(id).seller == msg.sender, "You are not the seller");
    require(activeItems[tokenId] != 0, "Item is not up for sale!");

    marketFishys[id].isRemove = true;
    activeItems[tokenId] = 0;
    removeItems[id] = true;

    endStatusBidderItem(id);
  }

  function buyItem(address fishyAddress, address payable tokenAddress, uint256 id) 
      itemExists(id)
      isForSale(id)
      isNotRemove(id)
      hasApproval(fishyAddress, getItem(id).tokenId) external {
    require(activeItems[getItem(id).tokenId] != 0, "Item is not up for sale!");
    require(msg.sender != getItem(id).seller, "Can't buy your own item");
    uint256 price = getItem(id).price;
    require(FishyToken(tokenAddress).balanceOf(msg.sender) >= price, "Not enough FET");

    marketFishys[id].isSold = true;
    soldItems[id] = true;

    activeItems[getItem(id).tokenId] = 0;
    uint256 fee = price.mul(MARKET_FEE).div(100);
    uint256 sellAmount = price.sub(fee);

    FishyToken(tokenAddress).transferFrom(msg.sender, owner(), fee);
    FishyToken(tokenAddress).transferFrom(msg.sender, getItem(id).seller, sellAmount);
    ERC721(fishyAddress).safeTransferFrom(getItem(id).seller, msg.sender, getItem(id).tokenId);

    transferFee += fee;
    marketVolume += price;
    marketTransaction++;

    // change status of all bidder
    endStatusBidderItem(id);

    // For WL
    addWhitelist(msg.sender);

    emit ItemSold(id, getItem(id).tokenId, block.timestamp, price);
  }

  function sellItem(address fishyAddress, address payable tokenAddress, uint256 id, address bidder)
      isNotRemove(id)
      isForSale(id) external {
    Bidder[] memory bidders = activeBidItems[id];
    bool correctBidder = false;
    uint256 index;
    for (uint256 s = 0; s < bidders.length; s += 1){
      if (bidder == bidders[s].bidder) {
        correctBidder = true;
        index = s;
      }
    }
    require(activeItems[getItem(id).tokenId] != 0, "Item is not up for sale!");
    require(correctBidder, "This bidder is not bid");
    require(FishyToken(tokenAddress).balanceOf(bidder) >= bidders[index].price, "Bidder dont have enough balance");

    marketFishys[id].isSold = true;
    activeItems[getItem(id).tokenId] = 0;
    soldItems[id] = true;

    uint256 fee = bidders[index].price.mul(MARKET_FEE).div(100);
    uint256 sellAmount = bidders[index].price.sub(fee);

    if (FishyToken(tokenAddress).allowance(address(this), address(this)) < bidders[index].price) {
      FishyToken(tokenAddress).approve(address(this), ~uint256(0));
    }
    FishyToken(tokenAddress).transferFrom(bidder, owner(), fee);
    FishyToken(tokenAddress).transferFrom(bidder, msg.sender, sellAmount);
    ERC721(fishyAddress).safeTransferFrom(msg.sender, bidder, getItem(id).tokenId);

    transferFee += fee;
    marketVolume += bidders[index].price;
    marketTransaction++;

    // end status of all bidder
    endStatusBidderItem(id);

    // change status of this bidder
    activeBidItems[id][index].status = 1; // dealed

    // remove item from bidder
    uint256 bidItemIndex;
    for (uint256 s = 0; s < bidItems[bidder].length; s += 1){
      if (id == bidItems[bidder][s]) {
        bidItemIndex = s;
      }
    }
    bidItems[bidder][bidItemIndex] = bidItems[bidder][bidItems[bidder].length - 1];
    bidItems[bidder].pop();

    // For WL
    addWhitelist(bidder);

    emit ItemBidSold(id, getItem(id).tokenId, block.timestamp, bidders[index].price, bidder);
  }

  function bidItem(address payable tokenAddress, uint256 id, uint256 bidPrice) 
      itemExists(id)
      isNotRemove(id)
      isForSale(id) external {
    require(activeItems[getItem(id).tokenId] != 0, "Item is not up for sale!");
    require(msg.sender != getItem(id).seller, "Can't offer your own item");
    Bidder[] memory bidders = activeBidItems[id];
    bool alreadyBid = false;
    for (uint256 s = 0; s < bidders.length; s += 1){
      if (msg.sender == bidders[s].bidder) {
        alreadyBid = true;
      }
    }
    require(!alreadyBid, "You already offer this item");
    require(bidPrice >= 10, "Minimum offer is 10");
    require(FishyToken(tokenAddress).balanceOf(msg.sender) >= bidPrice, "Not enough FET");

    // add bidder to item
    Bidder memory bidder = Bidder(msg.sender, bidPrice, block.timestamp, 0, 0);
    activeBidItems[id].push(bidder);

    // add item to bidder
    bidItems[msg.sender].push(id);

    emit ItemHaveNewBidder(id, getItem(id).tokenId, block.timestamp, msg.sender, bidPrice);
  }

  function cancelBidItem(uint256 id) 
      itemExists(id) external {
    Bidder[] memory bidders = activeBidItems[id];
    bool alreadyBid = false;
    uint256 bidIndex;
    for (uint256 s = 0; s < bidders.length; s += 1){
      if (msg.sender == bidders[s].bidder) {
        alreadyBid = true;
        bidIndex = s;
      }
    }
    require(alreadyBid, "You dont bid this item");
    require(bidders[bidIndex].status != 1, "You already won this item");

    // remove bidder from item
    activeBidItems[id][bidIndex] = activeBidItems[id][activeBidItems[id].length - 1];
    activeBidItems[id].pop();

    // remove item from bidder
    uint256 bidItemIndex;
    for (uint256 s = 0; s < bidItems[msg.sender].length; s += 1){
      if (id == bidItems[msg.sender][s]) {
        bidItemIndex = s;
      }
    }
    bidItems[msg.sender][bidItemIndex] = bidItems[msg.sender][bidItems[msg.sender].length - 1];
    bidItems[msg.sender].pop();

    emit ItemBidCancel(id, getItem(id).tokenId, block.timestamp, msg.sender);
  }

  function endStatusBidderItem(uint256 id) internal {
    for (uint256 i = 0; i < activeBidItems[id].length; i++) {
      activeBidItems[id][i].status = 2; // ended
      activeBidItems[id][i].endDate = block.timestamp;
    }
  }

  function getBidItems() view external returns(uint256[] memory) {
    return bidItems[msg.sender];
  }
}