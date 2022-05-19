// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract BTCLPMetaGamePassERC721 is ERC721, ERC721Enumerable, ERC721Royalty, ContextMixin, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint256 public constant MAX_GAME_PASSES = 5000;
    uint256 public immutable allowMintingAfter;
    uint256 public immutable timeDeployed;

    // 1, 0xe6F7C7caF678A3B7aFb93891907873E88F4FD4AC, 750
    constructor(
        uint256 _allowMintingOn,
        address _royaltiesReceiver, 
        uint96 _royaltiesFeeNumerator
    ) ERC721("No Loss Lottery Game Pass", "NLLGP") {
        allowMintingAfter = _allowMintingOn > block.timestamp ? _allowMintingOn - block.timestamp : 0;
        timeDeployed = block.timestamp;
        _setDefaultRoyalty(_royaltiesReceiver, _royaltiesFeeNumerator);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeicwk5gf5sw7ti5gr7t776aijcfy2ufnffsafnxyc7bqpumkgiskxy";
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmTnq4ZSUqAuqerZtrhatrBAHYkUzjgFhxwZyBpA5aBz93"; // Contract-level metadata for OpenSea
    }

    function safeMint(uint256 amount) public payable {
        require(block.timestamp >= timeDeployed + allowMintingAfter, "Minting now allowed yet");
        require(totalSupply() + amount <= MAX_GAME_PASSES, "Max Supply Reached");
        require(amount > 0 && amount <= 2, "Max 2 NLL Game Passes per transaction");

        if (msg.sender != owner()) {
            require(msg.value >= 0.08 ether * amount);
        }

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function getSecondsUntilMinting() public view returns (uint256) {
        if (block.timestamp < timeDeployed + allowMintingAfter) {
            return (timeDeployed + allowMintingAfter) - block.timestamp;
        } else {
            return 0;
        }
    }

    function tokenURI(uint256 tokenId) public pure override(ERC721) returns (string memory) {
        require(tokenId <= MAX_GAME_PASSES);
        return _baseURI();
    }

     // Maintain flexibility to modify royalties recipient (could also add basis points).
    function setRoyalty(address recipient, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(recipient, feeNumerator);
    }

    function setRoyaltyById(uint256 tokenId, address recipient, uint96 fraction) external onlyOwner {
        _setTokenRoyalty(tokenId, recipient, fraction);
    }

    function isApprovedForAll(address owner, address operator)
        override(ERC721)
        public
        view
        returns (bool)
    {
        address proxy = proxyFor(owner);
        return proxy != address(0) && proxy == operator;
    }

    /**
    @notice Returns the OpenSea proxy address for the owner.
     */
    function proxyFor(address owner) internal view returns (address) {
        address registry;
        uint256 chainId;

        assembly {
            chainId := chainid()
            switch chainId
            // Production networks are placed higher to minimise the number of
            // checks performed and therefore reduce gas. By the same rationale,
            // mainnet comes before Polygon as it's more expensive.
            case 1 {
                // mainnet
                registry := 0xa5409ec958c83c3f309868babaca7c86dcb077c1
            }
            case 137 {
                // polygon
                registry := 0x58807baD0B376efc12F5AD86aAc70E78ed67deaE
            }
            case 4 {
                // rinkeby
                registry := 0xf57b2c51ded3a29e6891aba85459d600256cf317
            }
            case 80001 {
                // mumbai
                registry := 0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c
            }
        }

        // Unlike Wyvern, the registry itself is the proxy for all owners on 0x
        // chains.
        if (registry == address(0) || chainId == 137 || chainId == 80001) {
            return registry;
        }

        return address(ProxyRegistry(registry).proxies(owner));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function destroy() public onlyOwner {
        selfdestruct(payable(owner()));
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

}
