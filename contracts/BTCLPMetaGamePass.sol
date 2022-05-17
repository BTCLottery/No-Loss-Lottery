// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";
import "./@openzeppelin/contracts/security/Pausable.sol";
import "./@openzeppelin/contracts/utils/Strings.sol";
import "./@openzeppelin/contracts/utils/ContextMixin.sol";

contract BTCLPMetaGamePass is ERC1155, IERC2981, Ownable, ERC1155Supply, ContextMixin { 
    using Strings for uint256;

    string public constant name = "Bitcoin Lottery Protocol Meta Game Pass";
    string public constant symbol = "BLPMGP";

    uint256 public constant COMMON = 0;
    uint256 public constant EPIC = 1;
    uint256 public constant LEGENDARY = 2;

    uint256 public constant COMMON_SUPPLY = 3000;
    uint256 public constant EPIC_SUPPLY = 2000;
    uint256 public constant LEGENDARY_SUPPLY = 1000;

    uint256 public immutable allowMintingAfter;
    uint256 public immutable timeDeployed;
    address private treasury;

    /** @dev Bitcoin Lottery Protocol - Metaverse Game Pass
    * Unlocks future access and a daily chance to win BTCLP Governance Tokens & NLL Utility Tokens
    * HODL any Meta Pass and participate daily in the Deflationary DAO No Loss Lottery
    * Backed by Chainlink Verifiable Random Function (VRF) & Chainlink Keepers  
    * Reserved 500 Legendary Meta Passes for:
    * 50 for Advisors, Influencers
    * 100 for Team and Early Adopters
    * 150 for Partnering Companies
    * 200 for Future Governments
    */
    constructor(uint256 _allowMintingOn) ERC1155("") {
        allowMintingAfter = _allowMintingOn > block.timestamp ? _allowMintingOn - block.timestamp : block.timestamp;
        timeDeployed = block.timestamp;
        treasury = msg.sender;
        _mint(msg.sender, 2, 500, "0x");
    }

    function destroy() public {
        selfdestruct(payable(owner()));
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
        require(tokenId >= 0, "ERC1155Metadata: URI query for nonexistent token");
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
        if(id == 0) { price = 0.25 ether; supply = COMMON_SUPPLY; }
        if(id == 1) { price = 0.5 ether; supply = EPIC_SUPPLY; }
        if(id == 2) { price = 2.5 ether; supply = LEGENDARY_SUPPLY; }

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
            if(ids[i] == 0) { price += 0.25 ether * amounts[i]; require(totalSupply(ids[i]) + amounts[i] <= COMMON_SUPPLY); }
            if(ids[i] == 1) { price += 0.5 ether * amounts[i]; require(totalSupply(ids[i]) + amounts[i] <= EPIC_SUPPLY); }
            if(ids[i] == 2) { price += 2.5 ether * amounts[i]; require(totalSupply(ids[i]) + amounts[i] <= LEGENDARY_SUPPLY); }
        }

        if (msg.sender != owner()) {
            require(msg.value >= price);
        }

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
        treasury = newRecipient;
    }

    function setRoyalties(address newRecipient) external onlyOwner {
        _setRoyalties(newRecipient);
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (treasury, (_salePrice * 1000) / 10000);
    }

    // EIP2981 standard Interface return. Adds to ERC1155 and ERC165 Interface returns.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
    }

    /** @dev Meta-transactions override for OpenSea. */
    function _msgSender() internal override view returns (address) {
        return ContextMixin.msgSender();
    }

    /** @dev Contract-level metadata for OpenSea. */
    // Update for collection-specific metadata.
    function contractURI() public pure returns (string memory) {
        return "ipfs://QmTnq4ZSUqAuqerZtrhatrBAHYkUzjgFhxwZyBpA5aBz93"; // Contract-level metadata
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    
}