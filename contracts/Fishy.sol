// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./HasAdmin.sol";

contract Fishy is ERC721, ERC721Burnable, ERC721Enumerable, Ownable, HasAdmin {
  using Counters for Counters.Counter;
  using SafeMath for uint256;
  using SafeMath for uint16;
  Counters.Counter private currentTokenId;

  struct Metadata {
    uint16 body;
    uint8 color;
    uint16 eye;
    uint16 mouth;
    uint16 pattern;
    uint16 fin;
    uint8 sex; // 0 male 1 female
    uint8 rarity;
    string name;
    bool isOriginal;
  }

  struct PlayToEarn {
    uint256 level;
  }

  struct Life {
    uint256 dad;
    uint256 mom;
    uint256 giveBirthCount;
    uint256[] childrens;
    uint256 lastDatePregnant;
  }

  mapping(uint256 => Metadata) id_to_fishy;
  mapping(uint256 => PlayToEarn) id_to_earn;
  mapping(uint256 => Life) id_to_life;

  string private _currentBaseURI;
  uint16 private _maxBody;
  uint16 private _maxColor;
  uint16 private _maxEye;
  uint16 private _maxMouth;
  uint16 private _maxPattern;
  uint16 private _maxRarity;
  uint16 private _maxFin;

  uint256 private nonce;

  event FishyUpdated(uint256 tokenId);

  constructor() ERC721("Fishy", "FISHY") {
    setBaseURI("");
    setMaxBody(20);
    setMaxColor(5);
    setMaxEye(20);
    setMaxMouth(20);
    setMaxPattern(20);
    setMaxFin(20);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _currentBaseURI = baseURI;
  }

  function setMaxBody(uint16 body) public onlyOwner {
    _maxBody = body;
  }

  function setMaxColor(uint16 color) public onlyOwner {
    _maxColor = color;
  }

  function setMaxEye(uint16 eye) public onlyOwner {
    _maxEye = eye;
  }

  function setMaxMouth(uint16 mouth) public onlyOwner {
    _maxMouth = mouth;
  }

  function setMaxPattern(uint16 pattern) public onlyOwner {
    _maxPattern = pattern;
  }

  function setMaxFin(uint16 fin) public onlyOwner {
    _maxFin = fin;
  }

  function getMaxBody() view public onlyOwner returns (uint16) {
    return _maxBody;
  }

  function getMaxColor() view public onlyOwner returns (uint16) {
    return _maxColor;
  }

  function getMaxEye() view public onlyOwner returns (uint16) {
    return _maxEye;
  }

  function getMaxMouth() view public onlyOwner returns (uint16) {
    return _maxMouth;
  }

  function getMaxPattern() view public onlyOwner returns (uint16) {
    return _maxPattern;
  }

  function getMaxFin() view public onlyOwner returns (uint16) {
    return _maxFin;
  }
  
  function getCurrentTokenCount() view public onlyOwner returns (uint256) {
    return currentTokenId.current();
  }

  function setName(uint256 tokenId, string memory name) public {
    require(ownerOf(tokenId) == msg.sender, "only the owner of this Fishy can do this");
    id_to_fishy[tokenId].name = name;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _currentBaseURI;
  }

  function mintFor(address userAddress, 
                        Metadata memory metadata) internal returns (uint256) {
    uint256 _tokenId = currentTokenId.current();

    id_to_fishy[_tokenId] = metadata;
    id_to_earn[_tokenId] = PlayToEarn(1);

    _safeMint(userAddress, _tokenId);

    currentTokenId.increment();
    return _tokenId;
  }

  function claim(address userAddress) public onlyAdmin {
    uint8 rarity;

    uint16 body = uint16(random(_maxBody));
    uint8 color = uint8(random(_maxColor));
    uint16 eye = uint16(random(_maxEye));
    uint16 mouth = uint16(random(_maxMouth));
    uint16 pattern = uint16(random(_maxPattern));
    uint16 fin = uint16(random(_maxFin));
    uint8 sex = uint8(random(2));

    uint256 r = pseudoRNG(body, color, eye, mouth, pattern, fin, sex) % 1000000;
    if (r < 500) {
        rarity = 7;
    } else if (r < 3000) {
        rarity = 6;
    } else if (r < 8000) {
        rarity = 5;
    } else if (r < 33000) {
        rarity = 4;
    } else if (r < 83000) {
        rarity = 3;
    } else if (r < 200000) {
        rarity = 2;
    } else if (r < 400000) {
        rarity = 1;
    } else {
        rarity = 0;
    }

    mintFor(userAddress, Metadata(body, color, eye, mouth, pattern, fin, sex, rarity, "", true));
  }

  function giveBirth(address userAddress, 
                    uint256 dadId, 
                    uint256 momId) public onlyAdmin {
    uint8 rarity;

    uint16 body = uint16(random(_maxBody));
    uint8 color = uint8(random(_maxColor));
    uint16 eye = uint16(random(_maxEye));
    uint16 mouth = uint16(random(_maxMouth));
    uint16 pattern = uint16(random(_maxPattern));
    uint16 fin = uint16(random(_maxFin));
    uint8 sex = uint8(random(2));
    uint256 r = pseudoRNG(body, color, eye, mouth, pattern, fin, sex) % 1000000;
    if (r < 1000) {
        rarity = 7;
    } else if (r < 6000) {
        rarity = 6;
    } else if (r < 16000) {
        rarity = 5;
    } else if (r < 66000) {
        rarity = 4;
    } else if (r < 166000) {
        rarity = 3;
    } else if (r < 366000) {
        rarity = 2;
    } else if (r < 666000) {
        rarity = 1;
    } else {
        rarity = 0;
    }

    uint256 tokenId = mintFor(userAddress, Metadata(body, color, eye, mouth, pattern, fin, sex, rarity, "", false));
    id_to_life[momId].giveBirthCount = id_to_life[momId].giveBirthCount.add(1);
    id_to_life[momId].childrens.push(tokenId);
    id_to_life[momId].lastDatePregnant = block.timestamp;

    id_to_life[dadId].giveBirthCount = id_to_life[dadId].giveBirthCount.add(1);
    id_to_life[dadId].childrens.push(tokenId);
    uint256[] memory childrens;
    id_to_life[tokenId] = Life(dadId, momId, 0, childrens, 0);
  }

  function fusion(address user, uint256 tokenIdA, uint256 tokenIdB, uint256 maxPercent) external onlyAdmin {
    require(ownerOf(tokenIdA) == user, "only the owner of this Fishy can do this");
    require(ownerOf(tokenIdB) == user, "only the owner of this Fishy can do this");

    uint256 tokenARarity = getFishyRarity(tokenIdA);
    uint256 tokenBRarity = getFishyRarity(tokenIdB);
    require(tokenARarity == tokenBRarity, "Not same rarity");
    require(tokenARarity < 7, "Your fishy reached maximum Rarity");

    uint256 luck = uint256(random(100 * 10 ** 18));
    uint256 deadIndex = uint256(random(2));
    if (luck <= maxPercent) {
      // Got Super Fish
      if (deadIndex == 0) {
        burn(tokenIdA);
        id_to_fishy[tokenIdB].rarity++;
      } else {
        burn(tokenIdB);
        id_to_fishy[tokenIdA].rarity++;
      }
    } else {
      // No Luck
      if (deadIndex == 0) {
        burn(tokenIdA);
      } else {
        burn(tokenIdB);
      }
    }
  } 

  function fusionWithLock(address user, uint256 tokenIdA, uint256 tokenIdB, uint256 lockId, uint256 maxPercent) external onlyAdmin {
    require(ownerOf(tokenIdA) == user, "only the owner of this Fishy can do this");
    require(ownerOf(tokenIdB) == user, "only the owner of this Fishy can do this");

    uint256 tokenARarity = getFishyRarity(tokenIdA);
    uint256 tokenBRarity = getFishyRarity(tokenIdB);
    require(tokenARarity == tokenBRarity, "Not same rarity");
    require(tokenARarity < 7, "Your fishy reached maximum Rarity");
    require(tokenIdA == lockId || tokenIdB == lockId, "Fishy Lock Id not correct");

    uint256 luck = uint256(random(100 * 10 ** 18));
    if (luck < maxPercent) {
      // Got Super Fish
      if (tokenIdA == lockId) {
        burn(tokenIdB);
        id_to_fishy[tokenIdA].rarity++;
      } else {
        burn(tokenIdA);
        id_to_fishy[tokenIdB].rarity++;
      }
    } else {
      // No luck
      if (tokenIdA == lockId) {
        burn(tokenIdB);
      } else {
        burn(tokenIdA);
      }
    }
  }

  function transfer(address to, uint256 tokenId) public {
    _transfer(msg.sender, to, tokenId);
  }

  function uintToString(uint v) public pure returns (string memory) {
    uint maxlength = 100;
    bytes memory reversed = new bytes(maxlength);
    uint i = 0;
    while (v != 0) {
        uint remainder = v % 10;
        v = v / 10;
        reversed[i++] = bytes1(uint8(48 + remainder));
    }
    bytes memory s = new bytes(i); // i + 1 is inefficient
    for (uint j = 0; j < i; j++) {
        s[j] = reversed[i - j - 1]; // to avoid the off-by-one error
    }
    string memory str = string(s);  // memory isn't implicitly convertible to storage
    return str;
  }

  function get(uint256 _tokenId) view external 
    returns (string memory detail, 
            uint256 tokenId,
            uint256 rarity,
            bool isOriginal) {
    Metadata memory fishy = id_to_fishy[_tokenId];
    string memory fishDetail = string(abi.encodePacked(uintToString(fishy.body), "-", 
                                            uintToString(fishy.color), "-", 
                                            uintToString(fishy.eye), "-", 
                                            uintToString(fishy.mouth), "-", 
                                            uintToString(fishy.pattern), "-", 
                                            uintToString(fishy.fin), "-",
                                            uintToString(fishy.sex), "-",
                                            fishy.name));
    return (fishDetail, _tokenId, fishy.rarity, fishy.isOriginal);
  }

  function getEarnDetail(uint256 tokenId) view external 
    returns(uint256 rarity, uint256 level) {
    return (id_to_fishy[tokenId].rarity, id_to_earn[tokenId].level);
  }

  function getLifeDetail(uint256 tokenId) view external 
    returns(Life memory) {
    return id_to_life[tokenId];
  }

  function getFishyRarity(uint256 tokenId) view public returns(uint256) {
    return id_to_fishy[tokenId].rarity;
  }

  function getFishyLevel(uint256 tokenId) view public returns(uint256) {
    return id_to_earn[tokenId].level;
  }

  function levelUpFishy(uint256 tokenId) external onlyAdmin {
    id_to_earn[tokenId].level = id_to_earn[tokenId].level.add(1);
  }

  function setNonce(uint256 value) external onlyOwner {
    nonce = value;
  }

  function random(uint256 maxIndex) internal returns (uint256) {
      uint256 randomnumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % maxIndex;
      if (nonce >= (~uint256(0) - 10)) {
        nonce = 0;
      }
      nonce++;
      return randomnumber;
  }

  function pseudoRNG(uint16 body, uint8 color, uint16 eye, uint16 mouth, uint16 pattern, uint16 fin, uint8 sex) internal view returns (uint256) {
    return uint256(keccak256(abi.encode(block.timestamp, block.difficulty, body, color, eye, mouth, pattern, fin, sex)));
  }
}