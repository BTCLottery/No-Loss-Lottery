// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract BTCLPMetaGamePass is ERC1155, Ownable, ERC1155Supply { // 0x4715aCa23Edad68C64139f6C43C8652Aa5616801
    uint256 public constant COMMON = 0;
    uint256 public constant EPIC = 1;
    uint256 public constant LEGENDARY = 2;

    uint256 public constant COMMON_SUPPLY = 3000;
    uint256 public constant EPIC_SUPPLY = 2000;
    uint256 public constant LEGENDARY_SUPPLY = 1000;

    uint256 public timeDeployed;
    uint256 public allowMintingAfter;
    
    string public name = "Bitcoin Lottery Protocol (GAME PASS)";
    
    constructor(
        // uint256 _allowMintingOn, 
        // string memory url
        ) ERC1155("https://ipfs.io/ipfs/QmVQBNDGGzC2cunqq53SKezyV8XsB4otvepREJbreXYSuz/") {

        uint256 _allowMintingOn = block.timestamp; // remove in production

        if (_allowMintingOn > block.timestamp) {
            allowMintingAfter = _allowMintingOn - block.timestamp;
        }

        timeDeployed = block.timestamp;
        // _setURI(url);
    }

    // EXPERIMENTAL ONCHAIN GIF IMAGE
    // function getSvg(uint tokenId) private view returns (string memory) {
    //     string memory svg;
    //     svg = "<svg width='350px' height='350px' viewBox='0 0 24 24' fill='none' xmlns='http://www.w3.org/2000/svg'> <path d='M11.55 18.46C11.3516 18.4577 11.1617 18.3789 11.02 18.24L5.32001 12.53C5.19492 12.3935 5.12553 12.2151 5.12553 12.03C5.12553 11.8449 5.19492 11.6665 5.32001 11.53L13.71 3C13.8505 2.85931 14.0412 2.78017 14.24 2.78H19.99C20.1863 2.78 20.3745 2.85796 20.5133 2.99674C20.652 3.13552 20.73 3.32374 20.73 3.52L20.8 9.2C20.8003 9.40188 20.7213 9.5958 20.58 9.74L12.07 18.25C11.9282 18.3812 11.7432 18.4559 11.55 18.46ZM6.90001 12L11.55 16.64L19.3 8.89L19.25 4.27H14.56L6.90001 12Z' fill='red'/> <path d='M14.35 21.25C14.2512 21.2522 14.153 21.2338 14.0618 21.1959C13.9705 21.158 13.8882 21.1015 13.82 21.03L2.52 9.73999C2.38752 9.59782 2.3154 9.40977 2.31883 9.21547C2.32226 9.02117 2.40097 8.83578 2.53838 8.69837C2.67579 8.56096 2.86118 8.48224 3.05548 8.47882C3.24978 8.47539 3.43783 8.54751 3.58 8.67999L14.88 20C15.0205 20.1406 15.0993 20.3312 15.0993 20.53C15.0993 20.7287 15.0205 20.9194 14.88 21.06C14.7353 21.1907 14.5448 21.259 14.35 21.25Z' fill='red'/> <path d='M6.5 21.19C6.31632 21.1867 6.13951 21.1195 6 21L2.55 17.55C2.47884 17.4774 2.42276 17.3914 2.385 17.297C2.34724 17.2026 2.32855 17.1017 2.33 17C2.33 16.59 2.33 16.58 6.45 12.58C6.59063 12.4395 6.78125 12.3607 6.98 12.3607C7.17876 12.3607 7.36938 12.4395 7.51 12.58C7.65046 12.7206 7.72934 12.9112 7.72934 13.11C7.72934 13.3087 7.65046 13.4994 7.51 13.64C6.22001 14.91 4.82 16.29 4.12 17L6.5 19.38L9.86 16C9.92895 15.9292 10.0114 15.873 10.1024 15.8346C10.1934 15.7962 10.2912 15.7764 10.39 15.7764C10.4888 15.7764 10.5866 15.7962 10.6776 15.8346C10.7686 15.873 10.8511 15.9292 10.92 16C11.0605 16.1406 11.1393 16.3312 11.1393 16.53C11.1393 16.7287 11.0605 16.9194 10.92 17.06L7 21C6.8614 21.121 6.68402 21.1884 6.5 21.19Z' fill='red'/> </svg>";
    //     return svg;
    // }

    // function tokenURI(uint256 tokenId) override public view returns (string memory) {
    //     string memory json = Base64.encode(
    //         bytes(string(
    //             abi.encodePacked(
    //                 '{"name": "', attributes[tokenId].name, '",',
    //                 '"image_data": "', getSvg(tokenId), '",',
    //                 '"attributes": [{"trait_type": "Speed", "value": ', uint2str(attributes[tokenId].speed), '},',
    //                 '{"trait_type": "Attack", "value": ', uint2str(attributes[tokenId].attack), '},',
    //                 '{"trait_type": "Defence", "value": ', uint2str(attributes[tokenId].defence), '},',
    //                 '{"trait_type": "Material", "value": "', attributes[tokenId].material, '"}',
    //                 ']}'
    //             )
    //         ))
    //     );
    //     return string(abi.encodePacked('data:application/json;base64,', json));
    // }  
    // EXPERIMENTAL ONCHAIN GIF IMAGE

    function destroy() public {
        selfdestruct(payable(owner()));
    }

    function uri(uint256 _tokenId) override public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "https://ipfs.io/ipfs/QmVQBNDGGzC2cunqq53SKezyV8XsB4otvepREJbreXYSuz/",
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