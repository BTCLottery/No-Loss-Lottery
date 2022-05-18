// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0 < 0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract BTCLPDailyNoLossLottery is Context, Ownable, ReentrancyGuard, VRFConsumerBaseV2, KeeperCompatible {
    using SafeERC20 for IERC20;
    
    IERC20 private immutable btclpToken; // BTCLP TOKENS ARE RECLAIMABLE AFTER THE ROUND ENDS
    IERC20 private immutable nllToken;   // NLL TOKENS ARE BURNED ON EVERY USE 1 NLL = 1 TICKET
    IERC1155 private immutable nftToken; // META GAME PASS NFTS - DAILY PRIVATE NFT NO LOSS LOTTERY

    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    event LotteryOpen(uint256 lotteryRoundNr);
    event LotteryClose(uint256 lotteryRoundNr, uint256 totalTickets, uint256 totalPlayers);
    event LotteryCompleted(uint256 lotteryRoundNr, uint256[] winningTicketsNr, address[] winners);
    event TicketsPurchased(address token, address player, uint256 tokens, bytes data);
    event Claim(address claimer, uint256 btclpAmount);

    enum Status {
        Open,           // The lottery is open for ticket purchases
        Closed,         // The lottery is no longer open for ticket purchases
        Completed       // The lottery in this round has closed and the random lucky tickets have been drawn
    }

    struct Round {
        Status lotteryStatus;                       // Daily No Loss Lottery Rounds Status
        uint256 requestId;                          // Round Chainlink VRF Request ID
        uint256 startDate;                          // Round Start Time
        uint256 endDate;                            // Round End Date
        uint256 totalUniquePlayers;                 // Total Unique Players in active round
        uint256 totalTickets;                       // Total Tickets Bought in active round
        uint256[] randomResult;                     // Chainlink VRF Random Result (hex number)
        uint256[] luckyTickets;                     // Lucky Tickets are drawn every round (you can win multiple times with 1 ticket)
        address[] winners;                          // Lucky Addresses of Lucky Winnings Tickets
        mapping (uint256 => address) ticketNr;      // Players Addresses from their Ticket Numbers 
        mapping (address => uint256) totalBTCLP;    // Total BTCLP Contributed in active round
        mapping (address => uint256) totalNLL;      // Total NLL Contributed in active round
        mapping (address => bool) isUnique;         // Check if Player is Unique in current round
    }

    mapping(uint => Round) public rounds;

    // CHAINLINK VRF V2
    bytes32 public keyHash = 0xd4bb89654db74673a187bd804519e65e3f71a52bc55f11da7601a13dcf505314; // 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc; // Rinkeby
    address public link = 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06; // 0x01BE23585060835E02B77ef475b0Cc51aA1e0709; // Rinkeby
    address public vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab; // 0x6A2AAd07396B36Fe02a22b33cf443582f682c82f; // 0x6168499c0cFfCaCD319c818142124B7A15E857ab; // Rinkeby
    address public treasury;                   // GNOSIS TREASURY FOR REWARDS AND BURNING MECHANISM

    // DAILY JACKPOT ROUND
    uint256 public round;
    uint256 public drawFrequency = 1 days;
    uint256 public unclaimedTokens;            // total BTCLP Tokens that are Claimable
    uint256 public btclpEntry = 1e18;          // 1 BTCLP per Ticket that is reclaimable at the end of the round
    uint256 public nllEntry = 1e18;            // 1 NLL Token per Ticket that get's burned after it is used
    uint256 public reservedNFTs = 500;
    uint16 private requestConfirmations = 3;   // Longest Chain of Blocks after which Chainlink VRF makes the Random Hex Request 
    uint32 private callbackGasLimit = 100000;  // Amount of gas used for Chainlink Keepers Network calling Chainlink VRF V2 Randomness Function
    uint32 public totalWinnersPASS;            // total NFT Meta Game Pass Winners to Request for Random Numbers
    uint32 public totalWinnersDAO;             // total BTCLP and NLL Winners to Request for Random Numbers
    uint64 public subscriptionId;              // Chainlink Subscription ID
    bool public finalRound;                    // Last round 

    constructor(IERC20 _btclpToken, IERC20 _nllToken, IERC1155 _nftToken, address _treasury) VRFConsumerBaseV2(vrfCoordinator) {
        btclpToken = _btclpToken;
        nllToken = _nllToken;
        nftToken = _nftToken;
        treasury = _treasury;
        round = 1;
        rounds[round].lotteryStatus = Status.Open;
        rounds[round].startDate = block.timestamp;
        rounds[round].endDate = block.timestamp + drawFrequency;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        createNewSubscription();
    }

    function destroy() public {
        selfdestruct(payable(owner()));
    }

    function getGamePassByID(uint256 _id) public view returns (uint256 totalSupply) {
        return ERC1155Supply(address(nftToken)).totalSupply(_id);
    }

    function getAddressByID(uint256 _id) public view returns (uint256 totalSupply) {
        return ERC1155Supply(address(nftToken)).totalSupply(_id);
    }

    function totalGamePasses() public view returns (uint256 totalSupply) {
        uint256 total;
        for (uint256 i = 0; i < 3; i++) {
            total += ERC1155Supply(address(nftToken)).totalSupply(i);
        }
        return total;
    }

    // Create a new subscription when the contract is initially deployed.
    function createNewSubscription() private onlyOwner {
        subscriptionId = COORDINATOR.createSubscription();
        COORDINATOR.addConsumer(subscriptionId, address(this));
    }

    // Assumes this contract owns link. 1000000000000000000 = 1 LINK
    function topUpSubscription(uint256 amount) external onlyOwner {
        LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(subscriptionId));
    }

    // Add a consumer contract to the subscription.
    function addConsumer(address consumerAddress) external onlyOwner {
        COORDINATOR.addConsumer(subscriptionId, consumerAddress);
    }

    // Remove a consumer contract from the subscription.
    function removeConsumer(address consumerAddress) external onlyOwner {
        COORDINATOR.removeConsumer(subscriptionId, consumerAddress);
    }

    // Cancel the subscription and send the remaining LINK to a wallet address.
    function cancelSubscription(address receivingWallet) external onlyOwner {
        COORDINATOR.cancelSubscription(subscriptionId, receivingWallet);
        subscriptionId = 0;
    }

    // Set total number of winners for NFT Meta Game Pass
    function setTotalWinnersPASSReward (uint32 _totalWinnersPASS) public onlyOwner returns (bool) {
        totalWinnersPASS = _totalWinnersPASS;
        return true;
    }

    // Set total number of winners for BTCLP and NLL Token Daily Draw
    function setTotalWinnersDAOReward (uint32 _totalWinnersDAO) public onlyOwner returns (bool) {
        totalWinnersDAO = _totalWinnersDAO;
        return true;
    }

    // Set GNOSIS Treasury Wallet Address
    function setTreasuryAddress (address _treasury) public onlyOwner returns (bool) {
        treasury = _treasury;
        return true;
    }

    /**
     * @dev Get 1 Ticket Price with BTCLP Tokens.
     * @custom:time every hour entry price increases by 1 BTCLP Tokens for each chance
     */
    function getBtclpPrice() public view returns (uint ticketPrice) {
        uint TICKET_PRICE_INCREASE = 1; // 1 BTCLP token every hour
        uint SECONDS_PER_HOUR = 60 * 60; // 3600 seconds
        uint HOUR_DIFFERENCE = (block.timestamp - rounds[round].startDate) / SECONDS_PER_HOUR;
        return btclpEntry + (TICKET_PRICE_INCREASE * (HOUR_DIFFERENCE * 1e18));
    }

    /**
     * @dev Get Round Winners
     * returns luckyTickets and luckyWinners
     */
    function getWinners(uint roundNr) public view returns (uint256[] memory luckyTicket, address[] memory luckyWinner) {
        return (rounds[roundNr].luckyTickets, rounds[roundNr].winners);
    }

    /**
     * @dev Claim locked tokens + rewards from a specific round.
     * @param roundNr Desired round number.
     * returns claimed BTCL Tokens.
     */
    function claim(uint roundNr) public nonReentrant returns (uint256 claimedBTCL) {
        require(roundNr > round, "Wait until round finishes");
        uint btclpTokens = 0;
        
        if(rounds[roundNr].totalBTCLP[_msgSender()] > 0) {
            btclpTokens = rounds[roundNr].totalBTCLP[_msgSender()];
            rounds[roundNr].totalBTCLP[_msgSender()] = 0;
            btclpToken.safeTransfer(_msgSender(), btclpTokens);
            unclaimedTokens -= btclpTokens;
        }

        emit Claim(_msgSender(), btclpTokens);
        return btclpTokens;
    }

    /**
     * @dev Claim locked tokens + rewards from all rounds.
     * @return claimedBTCLP and claimnedNLL
     */
    function claimAll() public nonReentrant returns (uint256 claimedBTCLP) {
        uint btclpTokens = 0;
        for(uint i = 1; i <= round; i++) {
            if (rounds[i].totalBTCLP[_msgSender()] > 0) {
                uint btclp = rounds[i].totalBTCLP[_msgSender()];
                rounds[i].totalBTCLP[_msgSender()] = 0;
                btclpTokens += btclp;
            }
        }

        btclpToken.safeTransfer(_msgSender(), btclpTokens);
        unclaimedTokens -= btclpTokens;

        emit Claim(_msgSender(), btclpTokens);
        return btclpTokens;
    }

    /**
     * @dev Helper function that is used to display winner addresses, contributions and lucky bonuses won
     * @param roundNr Desired round number.
     * @return bool Function returns round winners statistics.
     */
    function roundStats(uint roundNr) view public returns (address[] memory, uint[] memory, uint[] memory) {
        uint playersLength = rounds[roundNr].winners.length;
        uint[] memory contribution = new uint[](playersLength);
        uint[] memory totalBtclpWon = new uint[](playersLength);
        address[] memory addresses = new address[](playersLength);

        for(uint i = 0; i < playersLength; i++){
            addresses[i] = rounds[roundNr].winners[i];
            contribution[i] = rounds[roundNr].totalBTCLP[addresses[i]];
            totalBtclpWon[i] = rounds[roundNr].totalNLL[addresses[i]];
        }

        return (addresses, contribution, totalBtclpWon);
    }

    function getClaimableTokens(uint256 nr) public view returns (uint btclp, uint256 nll) {
        btclp = rounds[nr].totalBTCLP[_msgSender()];
        nll = rounds[nr].totalNLL[_msgSender()];
    }

    /**
     * @dev Helper function for ChainLink VRF that extracts multiple random winning tickets from random entropy sources.
     * return array of winning tickets.
     */
    // function expand(uint256[] memory _randomValue, uint256 _totalWinningTickets, uint256 _totalWinners) public pure returns (uint256[] memory expandedValues) {
    //     expandedValues = new uint256[](_totalWinners);
    //     for (uint256 i = 0; i < _totalWinners; i++) {
    //         expandedValues[i] = (uint256(keccak256(abi.encode(_randomValue, i))) % _totalWinningTickets) + 1;
    //     }
    //     return expandedValues;
    // }

    function expand(uint256[] memory randomValue, uint256 totalWinningTickets, uint256 totalWinners) public pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](totalWinners);
        for (uint256 i = 0; i < totalWinners; i++) {
            expandedValues[i] = (uint256(keccak256(abi.encode(randomValue, i))) % totalWinningTickets) + 1;
        }
        return expandedValues;
    }

    /**
     * @dev Callback function used by VRF Coordinator to draw winners, announce and setup next round.
     * @param requestId VRF Coordinator request.
     * @param randomness VRF Coordinator random result.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomness) internal override {
        uint256[] memory winningTickets = expand(randomness, rounds[round].totalTickets, totalWinnersDAO);
        (uint256 toRewardDAO, uint256 toRewardNFT, uint256 toBurn, bool isFinalRound) = rewardBurnRatio();
        
        for (uint i = 0; i < rounds[round].winners.length; i++) {
            address winnerAddress = rounds[round].ticketNr[winningTickets[i]];
            rounds[round].winners[i] = winnerAddress;
            rounds[round].luckyTickets[i] = winningTickets[i];
            rounds[round].totalBTCLP[winnerAddress] = rounds[round].totalBTCLP[winnerAddress] + toRewardDAO;
            unclaimedTokens += toRewardDAO;
        }
        
        uint256 totalNFTs = totalGamePasses();
        for (uint i = 0; i < totalWinnersPASS; i++) {
            address winnerAddress = rounds[round].ticketNr[randomness[totalWinnersPASS + i]];
            rounds[round].winners[totalWinnersPASS + i] = winnerAddress;
            // rounds[round].luckyTickets[totalWinnersPASS + i] = randomness[totalWinnersPASS + i];
            // rounds[round].totalBTCLP[winnerAddress] = rounds[round].totalBTCLP[winnerAddress] + toRewardDAO;
            // unclaimedTokens += toRewardDAO; transfer tokens directly to wallets daily
        }

        (bool success,) = address(btclpToken).call(abi.encodeWithSignature("burn(uint256)",toBurn));
        require(success,"burn FAIL");

        rounds[round].lotteryStatus = Status.Completed;
        rounds[round].randomResult = randomness;
        rounds[round].requestId = requestId;
        emit LotteryCompleted(round, rounds[round].luckyTickets, rounds[round].winners);

        if(isFinalRound) {
            finalRound = true;
        } else {
            // INITIATE NEXT ROUND
            round = round + 1;
            rounds[round].lotteryStatus = Status.Open;
            rounds[round].startDate = block.timestamp;
            rounds[round].endDate = rounds[round].startDate + drawFrequency;
            emit LotteryOpen(round);
        }

    }

    // 10 Years of BTCLP / NLL / NFT - 100 winners daily
    // 1,25 Billion BTCLP / 3650 days = 342.464 BTCLP Daily / 100 winners = 3424 BTCLP Daily to 100 Winners for 10 years * 0.10$ = 342$
    // 342.465 BTCLP Daily / 2 Draws = 171.232 BTCLP
    // 10.000 NLL / 100 winners = 100 NLL
    // 10 Years of Game Pass BTCLP and NLL Rewards

    function rewardBurnRatio() public view returns (uint256 toRewardDAO, uint256 toRewardNFT, uint256 toBurn, bool isFinalRound) {
        uint256 treasuryBalance = btclpToken.balanceOf(address(treasury)); // aproval check
        uint256 reward = 342465 * 1e18; // 342.465 BTCLP Tokens / 2 pots = 171232,5 BTCLP Tokens
        if(reward * 2 <= treasuryBalance) {
            toRewardDAO = reward / 2 / totalWinnersDAO;
            toRewardNFT = reward / 2 / totalWinnersPASS;
            toBurn = reward;
            isFinalRound = false;
        } else if (reward * 2 >= treasuryBalance) {
            toRewardDAO = treasuryBalance / 2 / 2 / totalWinnersDAO;
            toRewardNFT = treasuryBalance / 2 / 2 / totalWinnersPASS;
            toBurn = treasuryBalance / 2;
            isFinalRound = true;
        }
    }

    /**
     * @dev ChainLink Keepers function that checks if round draw conditions have been met and initiates draw when they are true.
     * return bool upkeepNeeded if random winning tickets are ready to be drawn.
     * return bytes performData contain the current encoded round number.
     */
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = 
            rounds[round].endDate - 5 minutes <= block.timestamp &&
            rounds[round].requestId == 0 &&
            rounds[round].lotteryStatus == Status.Open && 
            rounds[round].lotteryStatus != Status.Completed && 
            rounds[round].totalTickets >= 10;
        performData = abi.encode(round);
    }

    /**
     * @dev ChainLink Keepers function that is executed by the Chainlink Keeper.
     * @param performData encoded round number sent over from checkUpKeep
     */
    function performUpkeep(bytes calldata performData) external override {
        uint256 verifyRound = abi.decode(performData, (uint256));
        require(verifyRound == round, "Round mismatch.");
        require(
            rounds[round].endDate - 5 minutes <= block.timestamp &&
            rounds[round].requestId == 0 &&
            rounds[round].lotteryStatus == Status.Open && 
            rounds[round].lotteryStatus != Status.Completed && 
            rounds[round].totalTickets >= 10, 
            "Could not draw winnings tickets."
        );
        rounds[round].lotteryStatus == Status.Closed;
        emit LotteryClose(round, rounds[round].totalTickets, rounds[round].totalUniquePlayers);
        COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            totalWinnersDAO + totalWinnersPASS // numWords
        );
    }

    /**
     * @dev Helper function used to view ticket number ownership.
     * @param roundNr The round from which we want to inspect ticket slots
     * @param nr The ticket slot numbers
     * return totalTickets the total Number tickets purchased in the round selected
     * return ticketNr the address of the player that owns the round ticket
     */
    function getTicketNumber(uint roundNr, uint nr) public view returns(uint totalTickets, address ticketNr) {
        return (rounds[roundNr].totalTickets, rounds[roundNr].ticketNr[nr]);
    }

    /**
     * @dev Helper function used to withdraw remaining LINK Tokens after all Daily Games have finished.
     */
    function withdrawLink(uint256 amount, address to) external onlyOwner {
        LINKTOKEN.transfer(to, amount);
    }

    /**
     * @dev Helper function used to withdraw remaining LINK Tokens after all Daily Games have finished.
     */
    function withdrawBTCLP() external onlyOwner {
        require(btclpToken.transfer(_msgSender(), btclpToken.balanceOf(address(this))), "Unable to transfer");
    }

    function getCurrentTime() public view returns (uint time) { time = block.timestamp; }
    function getCurrentBlockTime() public view returns (uint blockNr) { blockNr = block.number; }
    function getCurrentRoundTimeDiff() public view returns (uint time) { time = rounds[round].endDate - block.timestamp; }

    /**
     * @dev ERC677 TokenFallback Function.
     * @param _wallet The player address that sent tokens to the BTCLP Daily No Loss Lottery Contract.
     * @param _value The amount of tokens sent by the player to the BTCLP Daily No Loss Lottery Contract.
     * @param _data  The transaction metadata.
     */
    function onTokenTransfer(address _wallet, uint256 _value, bytes memory _data) public {
        require(finalRound == false, "The daily BTCLP No Loss Lottery has successfully distributed all 401.500.000 BTCLP Tokens!");
        uint ticketPrice = getBtclpPrice();
        buyTicket(_wallet, _value, ticketPrice, round, _data);
    }

    function buyTicket(address _wallet, uint256 _value, uint256 _btclpEntryPrice, uint256 _round, bytes memory _data) private {    
        // HIDRATE UNIQUE PLAYERS IN CURRENT ROUND
        if(rounds[_round].isUnique[_wallet] == false) {
            rounds[_round].isUnique[_wallet] = true;
            rounds[_round].totalUniquePlayers = rounds[_round].totalUniquePlayers + 1;
        }
        // BUY TICKET WITH BTCLP
        if(_msgSender() == address(btclpToken)) {
            require(_value % _btclpEntryPrice == 0, "The Daily No Loss Lottery accepts multiple 1200 BTCLP + Hourly increases of 50 BTCLP for each chance.");
            require(_value / _btclpEntryPrice <= 250, "Max 250 Tickets can be reserved at once using BTCLP Tokens.");
            _addTickets(_wallet, _value / _btclpEntryPrice);
            rounds[_round].totalBTCLP[_wallet] = rounds[_round].totalBTCLP[_wallet] + _value;
            unclaimedTokens += _value;
            emit TicketsPurchased(address(btclpToken), _wallet, _value, _data);
        // BUY TICKET WITH NLL
        } else if (_msgSender() == address(nllToken)) {
            require(_value % nllEntry == 0, "1 NLL Token = 1 Chance at any time.");
            require(_value / nllEntry <= 250, "Max 250 Tickets can be reserved at once using NLL Tokens.");
            _addTickets(_wallet, _value / nllEntry);
            rounds[_round].totalNLL[_wallet] = rounds[_round].totalNLL[_wallet] + _value;
            (bool success,) = address(nllToken).call(abi.encodeWithSignature("burn(uint256)",_value));
            require(success, "burn FAIL");
            emit TicketsPurchased(address(nllToken), _wallet, _value, _data);
        } else {
            revert("Provided amounts are not valid.");
        }
    }

    /**
     * @dev Helper function called by ERC677 onTokenTransfer function to calculate ticket slots for player and keep count of total tickets bought in the current round. 
     * @param _wallet The player address that sent tokens to the BTCLP Daily No Loss Lottery Contract.
     * @param _totalTickets The amount of tokens sent by the player to the BTCLP Daily No Loss Lottery Contract.
     */
    function _addTickets(address _wallet, uint _totalTickets) private {
        Round storage activeRound = rounds[round];
        uint total = activeRound.totalTickets;
        for(uint i = 1; i <= _totalTickets; i++){
            activeRound.ticketNr[total + i] = _wallet;
        }
        activeRound.totalTickets = total + _totalTickets;
    }

}