// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";
import "./@openzeppelin/contracts/security/Pausable.sol";
import "./@openzeppelin/contracts/utils/Strings.sol";
import "./@openzeppelin/contracts/utils/ContextMixin.sol";

// 0x439356Ad40D2f2961c99FFED4453f482AEC453Af
contract BTCLPMetaGamePass is ERC1155, IERC2981, Ownable, ERC1155Supply, ContextMixin { 
    using Strings for uint256;
    string public name = "Bitcoin Lottery Protocol Game Pass";
    string public symbol = "BLPGP";
    address private _treasury;

    uint256 public constant COMMON = 0;
    uint256 public constant EPIC = 1;
    uint256 public constant LEGENDARY = 2;

    uint256 public constant COMMON_SUPPLY = 3000;
    uint256 public constant EPIC_SUPPLY = 2000;
    uint256 public constant LEGENDARY_SUPPLY = 1000;

    uint256 public timeDeployed;
    uint256 public allowMintingAfter;
    
    constructor(
        // uint256 _allowMintingOn,
        // string memory url
        ) ERC1155("") {

        uint256 _allowMintingOn = block.timestamp; // remove in production

        if (_allowMintingOn > block.timestamp) {
            allowMintingAfter = _allowMintingOn - block.timestamp;
        }

        timeDeployed = block.timestamp;
        _treasury = msg.sender;
    }

    function destroy() public {
        selfdestruct(payable(owner()));
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
        // Tokens minted above the supply cap will not have associated metadata.
        require(tokenId >= 1, "ERC1155Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_uriBase, Strings.toString(tokenId), ".json"));
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

    /** @dev EIP2981 royalties implementation. */

    // Maintain flexibility to modify royalties recipient (could also add basis points).
    function _setRoyalties(address newRecipient) internal {
        require(newRecipient != address(0), "Royalties: new recipient is the zero address");
        _treasury = newRecipient;
    }

    function setRoyalties(address newRecipient) external onlyOwner {
        _setRoyalties(newRecipient);
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_treasury, (_salePrice * 1000) / 10000);
    }

    // EIP2981 standard Interface return. Adds to ERC1155 and ERC165 Interface returns.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

    /** @dev Meta-transactions override for OpenSea. */

    function _msgSender() internal override view returns (address) {
        return ContextMixin.msgSender();
    }

    /** @dev Contract-level metadata for OpenSea. */

    // Update for collection-specific metadata.
    function contractURI() public pure returns (string memory) {
        return "https://ipfs.io/ipfs/QmVA6ECJuJSd1w6ZFXs1w6w2EuHSab21K9tEfj8r4KhkG6"; // Contract-level metadata
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    
}
