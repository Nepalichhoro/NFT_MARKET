// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Big is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    uint256 public maxSupply = 1000;
    uint256 presalePrice = 0.001 ether;
    uint256 publicsalePrice = 0.01 ether;
    uint256 public presaleFixedMinting = 5;
    Counters.Counter private _tokenIdCounter;
    mapping(address => bool) _allowList;
    mapping (uint256=>uint256) refundTokenInDate;

    constructor() ERC721("Big", "Big") {
        _tokenIdCounter.increment();
    }

    function presaleMint() public {
        require(_allowList[msg.sender] == true, 'not allowed');
        require(balanceOf(msg.sender) <=5, 'mint limit reached for this address');
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <=maxSupply, 'Max cap reached');
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function publicsaleMint(uint256 numoftokens) public payable {
        require(numoftokens <=5, 'max limit is 5');
        require(msg.value >=(numoftokens * publicsalePrice), 'Insufficient balance');
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <=maxSupply, 'Max cap reached');
        for(uint i=0; i<= numoftokens; i++){
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
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
        refundTokenInDate[tokenId] = block.timestamp;
    }

    function getRefund(uint256 tokenId) public payable{
        require(msg.sender == ownerOf(tokenId), 'You must be the owner');
        require(refundTokenInDate[tokenId] != 0, 'You must request first');
        uint256 requestedRefund = refundTokenInDate[tokenId];
        if(block.timestamp >= requestedRefund){
            payable(address(msg.sender)).transfer(presalePrice);
        }
    }

    // The following functions are overrides required by Solidity.

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