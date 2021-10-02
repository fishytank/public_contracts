// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./HasAdmin.sol";
import "./Uniswap.sol";

contract FishyEgg is ERC20, ERC20Burnable, Ownable, HasAdmin {
  using SafeMath for uint256;

  uint256 private totalBurn = 0;
  uint256 private totalReward = 0;

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;

  uint256 public sellFeeRate = 3;
  uint256 public buyFeeRate = 1;
  address public addressForMarketing;


  // Anti bot-trade
  mapping(address => bool)    botAddresses;
  bool public antiBotEnabled;
  uint256 public antiBotDuration = 10 minutes;
  uint256 public antiBotTime;
  uint256 public antiBotAmount;

  constructor() ERC20("Fishy Egg", "FEG") {
    _mint(owner(), 20000 * 10 ** 18); // initial amount for liquidary
    addressForMarketing = msg.sender;
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x10ED43C718714eb63d5aA57B78B54704E256024E
    );

    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
    .createPair(address(this), _uniswapV2Router.WETH());

    uniswapV2Router = _uniswapV2Router;
    _approve(address(this), address(uniswapV2Router), ~uint256(0));
  }

  function setMarketingAddress(address newAddress) external onlyOwner {
    addressForMarketing = newAddress;
  }

  function getTotalBurn() view external returns(uint256) {
    return totalBurn;
  }

  function getTotalReward() view external returns(uint256) {
    return totalReward;
  }

  function doBurnFrom(address account, uint256 amount) external onlyAdmin {
    burnFrom(account, amount);
    totalBurn += amount;
  }

  function mint(address to, uint256 value) external onlyAdmin {
    _mint(to, value);
    totalReward += value;
  }

  function swapTokensForEth(uint256 tokenAmount) private {
    require(addressForMarketing != address(0), "Invalid marketing address");
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    // make the swap
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenAmount,
        0, // accept any amount of ETH
        path,
        addressForMarketing, // The contract
        block.timestamp
    );
  }

  function _transfer(
        address sender,
        address recipient,
        uint256 amount
  ) internal virtual override {
    if (
        antiBotTime > block.timestamp &&
        amount > antiBotAmount &&
        botAddresses[sender]
    ) {
        revert("Anti Bot");
    }

    uint256 transferFeeRate = recipient == uniswapV2Pair
        ? sellFeeRate
        : (sender == uniswapV2Pair ? buyFeeRate : 0);

    if (
        transferFeeRate > 0 &&
        sender != address(this) &&
        recipient != address(this)
    ) {
        uint256 _fee = amount.mul(transferFeeRate).div(100);
        super._transfer(sender, address(this), _fee); // TransferFee
        amount = amount.sub(_fee);
    }

    super._transfer(sender, recipient, amount);
  }

  function setBotAddresses (address[] memory _addresses) external onlyOwner {
    require(_addresses.length > 0);

    for (uint256 index = 0; index < _addresses.length; index++) {
        botAddresses[address(_addresses[index])] = true;
    }
  }

  function addBotAddress (address _address) external onlyOwner {
    require(!botAddresses[_address]);

    botAddresses[_address] = true;
  }

  function antiBot(uint256 amount) external onlyOwner {
    require(amount > 0, "not accept 0 value");
    require(!antiBotEnabled);

    antiBotAmount = amount;
    antiBotTime = block.timestamp + antiBotDuration;
    antiBotEnabled = true;
  }

  // receive eth from uniswap swap
  receive() external payable {}

}