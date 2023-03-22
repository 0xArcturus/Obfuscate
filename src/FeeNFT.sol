// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error FeeNft__NeedMoreETHSent();
error FeeNft__TransferFailed();
error FeeNFT__NoLongerMintable();

contract FeeNFT is ERC721URIStorage, Ownable {
  uint256 private immutable MINT_LIMIT;
  uint256 private immutable MINT_FEE;
  uint256 private immutable SUBSCRIPTION_FEE;
  uint256 private immutable TIME;
  string internal s_activatedUri;
  string internal s_notActivatedUri;
  uint256 private s_tokenCounter;

  mapping(uint256 => uint256) private s_validUntil;

  event Deactivated(uint256 indexed tokenId, address indexed from, uint256 indexed timestamp);
  event FeePayed(uint256 indexed tokenId, address indexed payer, uint256 indexed timestamp);

  constructor(
    uint256 mintLimit,
    uint256 mintFee,
    uint256 monthlyFee,
    uint256 subscriptionTime,
    string memory activatedUri,
    string memory inactiveUri
  ) ERC721("feeNft", "FEE") {
    MINT_LIMIT = mintLimit;
    MINT_FEE = mintFee;
    SUBSCRIPTION_FEE = monthlyFee;
    TIME = subscriptionTime;
    s_activatedUri = activatedUri;
    s_notActivatedUri = inactiveUri;
    s_tokenCounter = 0;
  }

  modifier requireMinted(uint256 tokenId) {
    _requireMinted(tokenId);
    _;
  }

  function mint() public payable returns (uint256) {
    if (msg.value < MINT_FEE) {
      revert FeeNft__NeedMoreETHSent();
    }
    if (s_tokenCounter >= MINT_LIMIT) {
      revert FeeNFT__NoLongerMintable();
    }
    uint256 newItemId = s_tokenCounter;
    s_tokenCounter = s_tokenCounter + 1;
    _safeMint(_msgSender(), newItemId);
    return newItemId;
  }

  function payFee(uint256 tokenId) public payable requireMinted(tokenId) {
    if (msg.value < SUBSCRIPTION_FEE) revert FeeNft__NeedMoreETHSent();

    s_validUntil[tokenId] = block.timestamp + TIME;
    emit FeePayed(tokenId, msg.sender, block.timestamp);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

    _transfer(from, to, tokenId);
    s_validUntil[tokenId] = block.timestamp - 1;

    emit Deactivated(tokenId, from, block.timestamp);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
    _safeTransfer(from, to, tokenId, data);
    s_validUntil[tokenId] = block.timestamp - 1;

    emit Deactivated(tokenId, from, block.timestamp);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override {
    safeTransferFrom(from, to, tokenId, "");
  }

  function withdraw() public onlyOwner {
    uint256 amount = address(this).balance;
    (bool success, ) = payable(_msgSender()).call{ value: amount }("");
    if (!success) {
      revert FeeNft__TransferFailed();
    }
  }

  function tokenURI(uint256 tokenId) public view override requireMinted(tokenId) returns (string memory) {
    if (block.timestamp <= s_validUntil[tokenId]) {
      return s_activatedUri;
    } else {
      return s_notActivatedUri;
    }
  }

  function getValidUntil(uint256 tokenId) public view requireMinted(tokenId) returns (uint256) {
    return s_validUntil[tokenId];
  }

  function getIsActivated(uint256 tokenId) public view requireMinted(tokenId) returns (bool) {
    return s_validUntil[tokenId] >= block.timestamp;
  }

  function getMintFee() public view returns (uint256) {
    return MINT_FEE;
  }

  function getSubscriptionFee() public view returns (uint256) {
    return SUBSCRIPTION_FEE;
  }

  function getSubscriptionTime() public view returns (uint256) {
    return TIME;
  }

  function getMintLimit() public view returns (uint256) {
    return MINT_LIMIT;
  }

  function getTokenCounter() public view returns (uint256) {
    return s_tokenCounter;
  }
}
