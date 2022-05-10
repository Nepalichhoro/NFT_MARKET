// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Base64.sol";

contract Base64NFT is ERC721Enumerable, Ownable {
    uint256 public stringLimit = 45;
    using Counters for Counters.Counter;
    using Strings for uint256;
    uint256 public maxSupply = 10;
    uint256 presalePrice = 0.001 ether;
    uint256 publicsalePrice = 0.01 ether;
    uint256 public presaleFixedMinting = 5;
    Counters.Counter private _tokenIdCounter;
    mapping(address => bool) public _allowList;
    mapping (uint256=>uint256) public refundTokenInDate;
    mapping(uint256 => Word) public wordsToTokenId;
    struct Word {
        string name;
        string description;
        string bgHue;
        string textHue;
        string value;
    }

    constructor() ERC721("Big", "Big") {
        // _tokenIdCounter.increment();
    }

    function presaleMint(string memory _userText) public payable{
        require(_allowList[msg.sender] == true, 'Not whitelisted');
        require(balanceOf(msg.sender) <5, 'mint limit reached for this address');
        require(msg.value >=presalePrice, 'Insufficient balance');

        uint256 supply = totalSupply();
        bytes memory strBytes = bytes(_userText);
        require(strBytes.length <= stringLimit, "String input exceeds limit.");
        require(exists(_userText) != true, "String already exists!");

        Word memory newWord = Word(
            string(abi.encodePacked("NFT", uint256(supply + 1).toString())),
            "This is our on-chain NFT",
            randomNum(361, block.difficulty, supply).toString(),
            randomNum(361, block.timestamp, supply).toString(),
            _userText
        );

        uint256 tokenId = supply+1;
        require(tokenId <=maxSupply, 'Max cap reached');
        wordsToTokenId[tokenId] = newWord; //Add word to mapping @tokenId
        _safeMint(msg.sender, tokenId);
    }

    function publicsaleMint(uint256 numoftokens, string memory _userText) public payable {
        require(numoftokens <=5, 'max limit is 5');
        require(msg.value >=(numoftokens * publicsalePrice), 'Insufficient balance');
        uint256 supply = totalSupply();
        require(supply+numoftokens <= maxSupply, 'Max cap would exceed');

        bytes memory strBytes = bytes(_userText);
        require(strBytes.length <= stringLimit, "String input exceeds limit.");
        require(exists(_userText) != true, "String already exists!");
        Word memory newWord = Word(
                string(abi.encodePacked("NFT", uint256(supply + 1).toString())),
                "This is our on-chain NFT",
                randomNum(361, block.difficulty, supply).toString(),
                randomNum(361, block.timestamp, supply).toString(),
                _userText
            );

        for(uint i=0; i<numoftokens; i++){
            uint mintIndex = supply+1;
            wordsToTokenId[mintIndex] = newWord; //Add word to mapping @tokenId
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

    function exists(string memory _text) public view returns (bool) {
        bool result = false;
        //totalSupply function starts at 1, as does out wordToTokenId mapping
        for (uint256 i = 1; i <= totalSupply(); i++) {
            string memory text = wordsToTokenId[i].value;
            if (
                keccak256(abi.encodePacked(text)) ==
                keccak256(abi.encodePacked(_text))
            ) {
                result = true;
            }
        }
        return result;
    }

    function randomNum(
        uint256 _mod,
        uint256 _seed,
        uint256 _salt
    ) public view returns (uint256) {
        uint256 num = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, msg.sender, _seed, _salt)
            )
        ) % _mod;
        return num;
    }

    function buildImage(uint256 _tokenId) private view returns (string memory) {
        Word memory currentWord = wordsToTokenId[_tokenId];
        string memory random = randomNum(361, 3, 3).toString();
        return
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<svg width="500" height="500" xmlns="http://www.w3.org/2000/svg">',
                        '<rect id="svg_11" height="600" width="503" y="0" x="0" fill="hsl(',
                        currentWord.bgHue,
                        ',50%,25%)"/>',
                        '<text font-size="18" y="10%" x="5%" fill="hsl(',
                        random,
                        ',100%,80%)">Some Text</text>',
                        '<text font-size="18" y="15%" x="5%" fill="hsl(',
                        random,
                        ',100%,80%)">Some Text</text>',
                        '<text font-size="18" y="20%" x="5%" fill="hsl(',
                        random,
                        ',100%,80%)">Some Text</text>',
                        '<text font-size="18" y="10%" x="80%" fill="hsl(',
                        random,
                        ',100%,80%)">Token: ',
                        _tokenId.toString(),
                        "</text>",
                        '<text font-size="18" y="50%" x="50%" text-anchor="middle" fill="hsl(',
                        random,
                        ',100%,80%)">',
                        currentWord.value,
                        "</text>",
                        "</svg>"
                    )
                )
            );
    }

    function buildMetadata(uint256 _tokenId)
        private
        view
        returns (string memory)
    {
        Word memory currentWord = wordsToTokenId[_tokenId];
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                currentWord.name,
                                '", "description":"',
                                currentWord.description,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                buildImage(_tokenId),
                                '", "attributes": ',
                                "[",
                                '{"trait_type": "TextColor",',
                                '"value":"',
                                currentWord.textHue,
                                '"}',
                                "]",
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return buildMetadata(_tokenId);
    }

    //only owner
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}