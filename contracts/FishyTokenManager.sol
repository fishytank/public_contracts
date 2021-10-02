// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./HasAdmin.sol";
import "./FishyEgg.sol";

contract FishyTokenManager is Ownable, HasAdmin {
    using SafeMath for uint256;

    struct LockDetail {
        uint8 currentClaim;
        uint256 lockAmount;
        uint256 amountPerClaim;
        uint256 nextTime;
    }

    struct Allocation {
        uint256 date;
        uint256 bnb;
        uint256 token;
    }

    uint256 private constant _million = 1000000;

    // Private
    uint256 private totalFTEPrivateSale = 1 * _million * 10 ** 18;  // 1 mil
    uint256 private privatePrice = 15 * 10 ** 16;
    mapping(address => uint256) private airdropWhitelist;
    mapping(address => bool) private privateSaleWhitelist;
    mapping(address => bool) private privateSaleBought;
    mapping(address => Allocation) private privateSaleAllocation;
    mapping(address => LockDetail) private fteLocks;

    uint256 private lockPeriod = 10 days;
    bool public isPrivateSaleOpen = false;
    uint256 public privateSaleTime = 1633183200;
    uint256 private percentLock = 50;
    uint256 private percentRelease = 20;

    // Public
    uint256 private totalFTEPublicSale = 2 * _million * 10 ** 18; // 2 mil
    uint256 private publicPrice = 25 * 10 ** 16;
    mapping(address => bool) private publicSaleBought;
    mapping(address => Allocation) private publicSaleAllocation;

    bool public isPublicSaleOpen = false;
    uint256 public publicSaleTime = 1633269600;

    // FEG
    mapping(address => uint256) private currentFegAmount;
    mapping(address => bool) private blackList;

    
    uint256 private bnbSnapshotPrice = 400 * 10 ** 18;
    uint256 private numWhitelistSlot = 0;

    // Airdrop
    bool public airdropEnabled = false;

    // FEG Manager
    uint256 private totalFEGBurn = 0;

    constructor() {}

    function getTotalPublicSale() view external onlyOwner returns(uint256) {
        return totalFTEPublicSale;
    }

    function setTotalPublicSale(uint256 value) external onlyOwner {
        totalFTEPublicSale = value;
    }

    function getSnapshotPrice() external view returns(uint256) {
        return bnbSnapshotPrice;
    }

    function setSnapshotPrice(uint256 value) external onlyOwner {
        bnbSnapshotPrice = value;
    }

    function getPublicSaleTime() view external returns(uint256) {
        return publicSaleTime;
    }

    function setPublicSaleTime(uint256 value) external onlyOwner {
        publicSaleTime = value;
    }

    function getPrivateSaleTime() view external returns(uint256) {
        return privateSaleTime;
    }

    function setPrivateSaleTime(uint256 value) external onlyOwner {
        privateSaleTime = value;
    }

    // FEG Manager
    event UserTopUpFEG(address user, uint256 amount, uint256 date);
    event UserClaimFEG(address user, uint256 amount, uint256 date);
    event UserSyncFEG(address user, uint256 amount, uint256 date);

    function getClaimableFEG(address user) view external returns(uint256) {
        return currentFegAmount[user];
    }

    function claimFEG(address payable fegAddress) external {
        require(blackList[msg.sender] == false, "You are banned");
        require(currentFegAmount[msg.sender] > 0, "Not enough balance");
        
        FishyEgg(fegAddress).mint(msg.sender, currentFegAmount[msg.sender]);
        currentFegAmount[msg.sender] = 0;

        emit UserClaimFEG(msg.sender, currentFegAmount[msg.sender], block.timestamp);
    }

    function syncFEGFromBackend(address user, uint256 amount) external onlyAdmin {
        currentFegAmount[user] = currentFegAmount[user].add(amount);

        emit UserSyncFEG(user, amount, block.timestamp);
    }

    function clearFegBacket(address user) external onlyAdmin {
        currentFegAmount[user] = 0;
    }

    function topUpFEG(address payable fegAddress, uint256 amount) external {
        require(blackList[msg.sender] == false, "You are banned");

        uint256 currentAmount = currentFegAmount[msg.sender];
        if (currentAmount < amount) {
            uint256 diff = amount.sub(currentAmount);
            require(IERC20(fegAddress).balanceOf(msg.sender) >= diff, "Not enough FEG");

            FishyEgg(fegAddress).doBurnFrom(msg.sender, diff);
            currentFegAmount[msg.sender] = currentFegAmount[msg.sender].add(diff);

            emit UserTopUpFEG(msg.sender, diff, block.timestamp);
        }
    }

    // For Airdrop
    function setAirdropEnabled(bool enabled) public onlyOwner {
        airdropEnabled = enabled;
    }

    function addAirdropWhitelist(address[] memory to, uint256[] memory amount)
        public
        onlyAdmin
    {
        require(to.length == amount.length, "Invalid arguments");

        for (uint256 index = 0; index < to.length; index++) {
            airdropWhitelist[address(to[index])] = amount[index];
        }
    }

    function getAirdropBalance(address user) view external returns (uint256) { 
        return airdropWhitelist[user];
    }

    function claimAirdrop(address tokenAddress) public {
        require(airdropEnabled, "It's not able to claim airdrop yet");
        require(
            airdropWhitelist[_msgSender()] > 0,
            "It's not possible to claim an airdrop at this address."
        );
        require(
            IERC20(tokenAddress).balanceOf(address(this)) >
                airdropWhitelist[_msgSender()],
            "No more token"
        );

        IERC20(tokenAddress).transferFrom(
            address(this),
            _msgSender(),
            airdropWhitelist[_msgSender()]
        );
        airdropWhitelist[_msgSender()] = 0;
    }

    // For Private Sale
    function setPrivateSaleOpen(bool value) external onlyOwner {
        isPrivateSaleOpen = value;
    }

    function getWhitelistSlot() view external returns (uint256) {
        return numWhitelistSlot;
    }

    function addPrivateWhitelist(address to) external onlyAdmin {
        if (!privateSaleWhitelist[to]) {
            privateSaleWhitelist[to] = true;
            numWhitelistSlot++;
        }
    }

    function addPrivateWhitelists(address[] memory to) external onlyAdmin {
        for (uint256 index = 0; index < to.length; index++) {
            if (!privateSaleWhitelist[address(to[index])]) {
                privateSaleWhitelist[address(to[index])] = true;
                numWhitelistSlot++;
            }
        }
    }

    function getPrivateSaleAllocation(address user) view external returns(Allocation memory) {
        return privateSaleAllocation[user];
    }

    function buyPrivate(address tokenAddress) public payable {
        require(privateSaleWhitelist[msg.sender], "You are not in the Whitelist");
        require(privateSaleBought[msg.sender] == false, "You already bought");
        require(isPrivateSaleOpen, "Private sale not open yet");
        require(block.timestamp > privateSaleTime, "Sale Not Open Yet");
        require(msg.value >= 0.1 ether, "Minimum amount is 0.1");
        require(msg.value <= 1 ether, "Maximum amount is 1");

        uint256 totalBNB = msg.value.mul(bnbSnapshotPrice);
        uint256 totalFTE = totalBNB.div(privatePrice);
        uint256 lockFTE = totalFTE.mul(percentLock).div(100);
        uint256 receiveFTE = totalFTE.sub(lockFTE);
        uint256 amountPerClaim = lockFTE.div(5);

        require(totalFTEPrivateSale >= totalFTE, "Sold Out!");
        require(IERC20(tokenAddress).balanceOf(address(this)) >= totalFTE, "Sold Out!");

        bool sent = payable(owner()).send(msg.value);
        require(sent, "Failed to send BNB");
        if (IERC20(tokenAddress).allowance(address(this), address(this)) < receiveFTE) {
            IERC20(tokenAddress).approve(address(this), ~uint256(0));
        }
        IERC20(tokenAddress).transferFrom(address(this), msg.sender, receiveFTE);
        totalFTEPrivateSale -= totalFTE;
        privateSaleBought[msg.sender] = true;
        fteLocks[msg.sender] = LockDetail(0, lockFTE, amountPerClaim, block.timestamp + lockPeriod);
        privateSaleAllocation[msg.sender] = Allocation(block.timestamp, msg.value, totalFTE);
    }

    function claimLock(address tokenAddress) public {
        LockDetail memory lockDetail = fteLocks[msg.sender];
        require(lockDetail.lockAmount > 0, "You don't have any amount");
        require(lockDetail.nextTime <= block.timestamp, "You still not able to claim yet");
        if (lockDetail.currentClaim >= 4) {
            IERC20(tokenAddress).transferFrom(address(this), msg.sender, lockDetail.lockAmount);
            fteLocks[msg.sender].lockAmount = 0;
        } else {
            IERC20(tokenAddress).transferFrom(address(this), msg.sender, lockDetail.amountPerClaim);
            fteLocks[msg.sender].lockAmount = fteLocks[msg.sender].lockAmount - lockDetail.amountPerClaim;
            fteLocks[msg.sender].currentClaim = fteLocks[msg.sender].currentClaim + 1;
            fteLocks[msg.sender].nextTime = fteLocks[msg.sender].nextTime + lockPeriod;
        }
    }

    function getClaimableTime(address user) view external returns (uint256) {
        LockDetail memory lockDetail = fteLocks[user];
        return lockDetail.nextTime;
    }

    function getClaimableToken(address user) view external returns (uint256) {
        LockDetail memory lockDetail = fteLocks[user];
        if (lockDetail.lockAmount == 0) {
            return 0;
        }
        if (lockDetail.nextTime > block.timestamp) {
            return 0;
        }
        if (lockDetail.currentClaim >= 4) {
            return lockDetail.lockAmount;
        }
        return lockDetail.amountPerClaim;
    }

    function getLockedBalance(address user) view external returns (uint256) {
        LockDetail memory lockDetail = fteLocks[user];
        return lockDetail.lockAmount;
    }

    // For Public sale
    function setPublicSaleOpen(bool value) external onlyAdmin {
        isPublicSaleOpen = value;
    }

    function getPublicSaleAllocation(address user) view external returns(Allocation memory) {
        return publicSaleAllocation[user];
    }

    function buyPublicSale(address tokenAddress) public payable {
        require(isPublicSaleOpen, "Public sale is Closed");
        require(publicSaleBought[msg.sender] == false, "You already bought");
        require(block.timestamp > publicSaleTime, "Sale Not Open Yet");
        require(msg.value >= 0.1 ether, "Minimum amount is 0.1");
        require(msg.value <= 2 ether, "Maximum amount is 2");

        uint256 totalBNB = msg.value.mul(bnbSnapshotPrice);
        uint256 totalFTE = totalBNB.div(publicPrice);

        require(totalFTEPublicSale >= totalFTE, "Sold Out!");
        require(IERC20(tokenAddress).balanceOf(address(this)) >= totalFTE, "Sold Out!");

        bool sent = payable(owner()).send(msg.value);
        require(sent, "Failed to send BNB");
        if (IERC20(tokenAddress).allowance(address(this), address(this)) < totalFTE) {
            IERC20(tokenAddress).approve(address(this), ~uint256(0));
        }
        IERC20(tokenAddress).transferFrom(address(this), msg.sender, totalFTE);
        totalFTEPublicSale -= totalFTE;
        publicSaleBought[msg.sender] = true;
        publicSaleAllocation[msg.sender] = Allocation(block.timestamp, msg.value, totalFTE);
    }

    function withdraw(address tokenAddress, uint256 amount) external onlyOwner {
        if (IERC20(tokenAddress).allowance(address(this), address(this)) < amount) {
            IERC20(tokenAddress).approve(address(this), ~uint256(0));
        }
        IERC20(tokenAddress).transferFrom(address(this), msg.sender, amount);
    }

}
