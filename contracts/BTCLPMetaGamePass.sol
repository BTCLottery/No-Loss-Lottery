// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BTCLPMetaGamePass is ERC1155, Ownable, ERC1155Supply { 
    // 0x4715aCa23Edad68C64139f6C43C8652Aa5616801
    // 0x439356Ad40D2f2961c99FFED4453f482AEC453Af

    // OPENSEA - Royalties 10% (5% TEAM / 5% HODLERS)
    // LOOKSRARE - Royalties 10% (5% TEAM / 5% HODLERS)

    uint256 public constant COMMON = 0;
    uint256 public constant EPIC = 1;
    uint256 public constant LEGENDARY = 2;

    uint256 public constant COMMON_SUPPLY = 3000;
    uint256 public constant EPIC_SUPPLY = 2000;
    uint256 public constant LEGENDARY_SUPPLY = 1000;

    uint256 public timeDeployed;
    uint256 public allowMintingAfter;
    
    string public name = "Bitcoin Lottery Protocol (GAME PASS)";
    string public symbol = "BLPGP";

    constructor(
        // uint256 _allowMintingOn,
        // string memory url
        ) ERC1155("https://gateway.pinata.cloud/ipfs/QmSXi4vWjUi5oQW5XJCKiRX7RVbnBE6G68Hu419y6Uu9tk") {

        uint256 _allowMintingOn = block.timestamp; // remove in production

        if (_allowMintingOn > block.timestamp) {
            allowMintingAfter = _allowMintingOn - block.timestamp;
        }

        timeDeployed = block.timestamp;
        // _setURI(url);
    }

    function destroy() public {
        selfdestruct(payable(owner()));
    }

    function uri(uint256 _tokenId) override public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "https://gateway.pinata.cloud/ipfs/QmSXi4vWjUi5oQW5XJCKiRX7RVbnBE6G68Hu419y6Uu9tk/",
                Strings.toString(_tokenId),
                ".json"
            )
        );
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(uint256 id, uint256 amount) public payable {
        require(block.timestamp >= timeDeployed + allowMintingAfter, "Minting now allowed yet");
        require(amount > 0);

        uint256 price;
        uint256 supply;
        if(id == 0) { price = 0.1 ether; supply = COMMON_SUPPLY; }
        if(id == 1) { price = 0.3 ether; supply = EPIC_SUPPLY; }
        if(id == 2) { price = 0.5 ether; supply = LEGENDARY_SUPPLY; }

        require(totalSupply(id) + amount <= supply, "Minting amount exceeds max limit");

        if (msg.sender != owner()) {
            require(msg.value >= price * amount);
        }

        _mint(msg.sender, id, amount, "0x");
    }

    function mintBatch(uint256[] memory ids, uint256[] memory amounts) public payable {
        require(block.timestamp >= timeDeployed + allowMintingAfter, "Minting now allowed yet");
        require(amounts[0] > 0);

        uint256 price;

        for (uint256 i = 0; i < 3; i++) {
            require(ids[i] < 3); 
            require(amounts[i] > 0);
            if(ids[i] == 0) { price += 0.1 ether * amounts[i]; require(totalSupply(ids[i]) + amounts[i] <= COMMON_SUPPLY); }
            if(ids[i] == 1) { price += 0.3 ether * amounts[i]; require(totalSupply(ids[i]) + amounts[i] <= EPIC_SUPPLY); }
            if(ids[i] == 2) { price += 0.5 ether * amounts[i]; require(totalSupply(ids[i]) + amounts[i] <= LEGENDARY_SUPPLY); }
        }

        if (msg.sender != owner()) {
            require(msg.value >= price);
        }

        // _safeMint(msg.sender, supply + i);
        _mintBatch(msg.sender, ids, amounts, "0x");
    }

    function getSecondsUntilMinting() public view returns (uint256) {
        if (block.timestamp < timeDeployed + allowMintingAfter) {
            return (timeDeployed + allowMintingAfter) - block.timestamp;
        } else {
            return 0;
        }
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}