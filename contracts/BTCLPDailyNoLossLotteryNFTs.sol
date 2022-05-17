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

contract BTCLPDailyNoLossLotteryNFTs is Context, Ownable, ReentrancyGuard, VRFConsumerBaseV2, KeeperCompatible {
    using SafeERC20 for IERC20;
    
    IERC20 private btclpToken; // GET TOKENS BACK AFTER THE GAME ENDS
    IERC20 private nllToken;   // TOKENS ARE BURNED AFTER USE
    IERC1155 private nftToken; // META GAME PASS NFTS

    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    event LotteryCompleted(uint256 lotteryRoundNr, uint256[10] winningTicketsNr, address[10] winners);
    event Claim(address claimer, uint256 btclpAmount);

    struct Round {
        bool lotteryStatus;                         // Status for NFT Daily No Loss Lottery
        uint256 requestId;                          // Chainlink VRF Round Request ID
        uint256[] randomResult;                     // Chainlink VRF Random Result (hex number)
        uint256 startDate;                          // Current Round Start Time
        uint256 endDate;                            // Current Round End Date
        uint256[10] luckyTickets;                   // 10 Lucky Tickets are drawn every round (you can win multiple times with 1 ticket)
        address[10] winners;                        // 10 Lucky Addresses of 10 Lucky Winnings Tickets
        mapping (uint256 => address) ticketNr;      // Get Players Addresses from their Ticket Numbers 
        mapping (address => uint256) totalBTCLP;    // Total BTCLP Contributed in active round
        mapping (address => uint256) totalNLL;      // Total NLL Contributed in active round
    }

    mapping(uint => Round) public rounds;

    // CHAINLINK BSC - VRF V2
    address public vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab; // 0x6A2AAd07396B36Fe02a22b33cf443582f682c82f; // 0x6168499c0cFfCaCD319c818142124B7A15E857ab; // Rinkeby
    address public link = 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06; // 0x01BE23585060835E02B77ef475b0Cc51aA1e0709; // Rinkeby
    bytes32 public keyHash = 0xd4bb89654db74673a187bd804519e65e3f71a52bc55f11da7601a13dcf505314; // 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc; // Rinkeby

    // DAILY JACKPOT ROUND
    uint256 public round;
    uint256 public unclaimedTokens;            // total BTCLP Tokens that can be claimed
    uint256 private blocksPerDay = 6446;       // 28700 for BSC // 6446 for Rinkeby // 43200 for MATIC
    uint16 private requestConfirmations = 3;   // Min Blocks after 
    uint32 private callbackGasLimit = 100000;  // Amount of gas used for Chainlink Keepers Network calling Chainlink VRF V2 Randomness Function
    uint32 private numWords = 1;               // Request 10 Random bytes32
    uint64 public subscriptionId;              // Chainlink Subscription ID
    bool public finalRound;                    // Last round 

    constructor(IERC20 _btclpToken, IERC20 _nllToken, IERC1155 _nftToken) VRFConsumerBaseV2(vrfCoordinator) {
        btclpToken = _btclpToken;
        nllToken = _nllToken;
        nftToken = _nftToken;
        round = 1;
        rounds[round].startDate = block.timestamp;
        rounds[round].endDate = addMinutes(block.timestamp, 4); // 4 minutes -> addDays(1) in Production
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        createNewSubscription();
    }

    function destroy() public {
        selfdestruct(payable(owner()));
    }

    function test(uint256 _id) public view returns (uint256 totalSupply) {
        return ERC1155Supply(address(nftToken)).totalSupply(_id);
    }

    function multiTest(uint256 _id) public view returns (uint256 totalSupply) {
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

    // Transfer this contract's funds to an address.
    function withdraw(uint256 amount, address to) external onlyOwner {
        LINKTOKEN.transfer(to, amount);
    }

    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        uint SECONDS_PER_MINUTE = 60;
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        uint SECONDS_PER_MINUTE = 60;
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        uint SECONDS_PER_HOUR = 60 * 60; // 3600
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    /**
     * @dev Get Round Winners
     * returns luckyTickets and luckyWinners
     */
    function getWinners(uint roundNr) public view returns (uint256[10] memory luckyTicket, address[10] memory luckyWinner) {
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
        uint256[] memory winningTickets = expand(randomness, rounds[round].totalTickets, rounds[round].winners.length);
        (uint256 toReward, uint256 toBurn, bool isFinalRound) = rewardBurnRatio();
        for (uint i = 0; i < rounds[round].winners.length; i++) {
            address winnerAddress = rounds[round].ticketNr[winningTickets[i]];
            rounds[round].winners[i] = winnerAddress;
            rounds[round].luckyTickets[i] = winningTickets[i];
            rounds[round].totalBTCLP[winnerAddress] = rounds[round].totalBTCLP[winnerAddress] + toReward;
            unclaimedTokens += toReward;
        }
        (bool success,) = address(btclpToken).call(abi.encodeWithSignature("burn(uint256)",toBurn));
        require(success,"burn FAIL");

        rounds[round].randomResult = randomness;
        rounds[round].requestId = requestId;
        emit LotteryCompleted(round, rounds[round].luckyTickets, rounds[round].winners);

        if(isFinalRound) {
            finalRound = true;
        } else {
            // INITIATE NEXT ROUND
            round = round + 1;
            rounds[round].startDate = block.timestamp;
            rounds[round].endDate = addMinutes(rounds[round].startDate, 4); // addDays(1) in production
        }

    }

    function rewardBurnRatio() public view returns (uint256 toReward, uint256 toBurn, bool isFinalRound) {
        uint256 dailyPrize = 1111000e18; // added 1000 BTCLP for first round
        uint256 deflation = round * 1000e18; // 1000 BTCLP deflation deduction each day
        uint256 reward = dailyPrize - deflation; // initial prize minus daily deflation
        uint256 contractBalance = btclpToken.balanceOf(address(this)) - unclaimedTokens;
        if(reward * 2 <= contractBalance)  {
            toReward = reward / 10; 
            toBurn = reward;
            isFinalRound = false;
        } else if (reward * 2 >= contractBalance) {
            toReward = contractBalance / 2 / 10;
            toBurn = contractBalance / 2;
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
            subMinutes(rounds[round].endDate, 2) <= block.timestamp && 
            rounds[round].requestId == 0 && 
            rounds[round].lotteryStatus == false;
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
            block.timestamp >= subMinutes(rounds[round].endDate, 2) && 
            rounds[round].lotteryStatus == false, 
            "Could not draw winnings tickets."
        );
        COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
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
    function withdrawBTCLP() external onlyOwner {
        require(btclpToken.transfer(_msgSender(), btclpToken.balanceOf(address(this))), "Unable to transfer");
    }

    function getCurrentTime() public view returns (uint time) { time = block.timestamp; }
    function getCurrentBlockTime() public view returns (uint blockNr) { blockNr = block.number; }
    function getCurrentRoundTimeDiff() public view returns (uint time) { time = rounds[round].endDate - block.timestamp; }
    function getCurrentRoundEndRound() public view returns (bool time) { time = addMinutes(block.timestamp, 2) >= rounds[round].endDate; }

}