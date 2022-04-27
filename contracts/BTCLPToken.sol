// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// ██████╗░░████████╗░░█████╗░░██╗░░░░░░██████╗░
// ██╔══██╗░╚══██╔══╝░██╔══██╗░██║░░░░░░██╔══██╗
// ██████╦╝░░░░██║░░░░██║░░╚═╝░██║░░░░░░██████╔╝
// ██╔══██╗░░░░██║░░░░██║░░██╗░██║░░░░░░██╔═══╝░
// ██████╦╝░░░░██║░░░░╚█████╔╝░███████╗░██║░░░░░
// ╚═════╝░░░░░╚═╝░░░░░╚════╝░░╚══════╝░╚═╝░░░░░

// Useful Links:
// Landing - https://btclottery.io
// IGO - https://igo.btclottery.io
// DEMO - https://demo.btclottery.io
// Github - https://github.com/btclottery
// Youtube - https://www.youtube.com/channel/UCFIqdTB47jtHiM0F0bZc_0Q
// Whitepaper - https://www.btclottery.io/Bitcoin-Lottery-Whitepaper.pdf
// Twitter - https://twitter.com/btclottery_io
// Discord - https://discord.com/channels/806829532081815552/806829532081815555
// Telegram - https://t.me/btclottery_io

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "./utils/token/ERC677/ERC677Receiver.sol";

/// @custom:security-contact support@btclottery.io
contract BTCLPToken is ERC20, ERC20Burnable, Ownable, ERC20Permit, ERC20Votes {
    uint256 public constant minimumMintInterval = 365 days;
    uint256 public constant mintCap = 100; // 1%
    uint256 public nextMint; // Next Timestamp

    constructor()
        ERC20("Bitcoin Lottery Protocol", "BTCLP") 
        ERC20Permit("Bitcoin Lottery Protocol")
    {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
        nextMint = block.timestamp + minimumMintInterval;
    }

    /**
     * @dev Mints new tokens. Can only be executed every `minimumMintInterval`, by the owner, and cannot 
     *      exceed `mintCap / 10000` fraction of the current total supply.
     * @param to The address to mint the new tokens to.
     * @param amount The quantity of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(amount <= (totalSupply() * mintCap) / 10000, "BTCLP: Mint exceeds maximum amount");
        require(block.timestamp >= nextMint, "BTCLP: Cannot mint yet");
        nextMint = block.timestamp + minimumMintInterval;
        _mint(to, amount);
    }

    /** 
    * @dev ERC677 transfer token to a contract address with additional data if the recipient is a contract.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @param _data The extra data to be passed to the receiving contract.
    */
    function transferAndCall(address _to, uint _value, bytes memory _data) public returns (bool success) {
      require(_msgSender() != address(0), "ERC677: can't receive tokens from the zero address");
      require(_to != address(0), "ERC677: can't send to zero address");
      require(_to != address(this), "ERC677: can't send tokens to the token address");

      _transfer(_msgSender(), _to, _value);
      emit Transfer(_msgSender(), _to, _value);

      if (isContract(_to)) {
        contractFallback(_to, _value, _data);
      }
      return true;
    }

    /**
    * @dev ERC677 function that emits _data to contract.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @param _data The extra data to be passed to the receiving contract.
    */
    function contractFallback(address _to, uint _value, bytes memory _data) private {
      ERC677Receiver receiver = ERC677Receiver(_to);
      receiver.onTokenTransfer(msg.sender, _value, _data);
    }

    /**
    * @dev Helper function that identifies if receiving address is a contract.
    * @param _addr The address to transfer to.
    * @return hasCode The bool that checks if address is an EOA or a Smart Contract. 
    */
    function isContract(address _addr) private view returns (bool hasCode) {
      uint length;
      assembly { length := extcodesize(_addr) }
      return length > 0;
    }

    // The following functions are overrides required by Solidity.
    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}