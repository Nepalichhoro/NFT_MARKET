// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Big is ERC721, ERC721Enumerable, ReentrancyGuard, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    uint256 public maxSupply = 10;
    uint256 presalePrice = 0.001 ether;
    uint256 publicsalePrice = 0.01 ether;
    uint256 public presaleFixedMinting = 5;
    mapping(address => bool) public _allowList;
    mapping (uint256=>uint256) public refundTokenInDate;

    constructor() ERC721("Big", "Big") {
    }

    function presaleMint() public payable{
        require(_allowList[msg.sender] == true, 'Not whitelisted');
        require(balanceOf(msg.sender) <5, 'Mint limit reached for this address');
        require(msg.value >=presalePrice, 'Insufficient balance');
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <=maxSupply, 'Max cap reached');
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function publicsaleMint(uint256 numoftokens) public payable {
        require(numoftokens <=5, 'max limit is 5');
        require(msg.value >=(numoftokens * publicsalePrice), 'Insufficient balance');
        require(totalSupply()+numoftokens <= maxSupply, 'Max cap would exceed');
        for(uint i=0; i<numoftokens; i++){
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);   
        }
    }

    function setAllowList(
        address[] calldata addresses
        ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = true;
        }
    }

    function requestRefund(uint256 tokenId) public{
        require(msg.sender == ownerOf(tokenId), 'You must be the owner');
        require(refundTokenInDate[tokenId] == 0, 'Already requested');
        refundTokenInDate[tokenId] = (block.timestamp + 1 weeks);
    }

    function getRefund(uint256 tokenId) public payable{
        require(msg.sender == ownerOf(tokenId), 'You must be the owner');
        require(refundTokenInDate[tokenId] != 0, 'You must request first');
        require(block.timestamp >= refundTokenInDate[tokenId], 'Must wait for a week after request was made');
        payable(address(msg.sender)).transfer(presalePrice);
    }

    function getBankBalance() public view returns(uint){
        return address(this).balance;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}