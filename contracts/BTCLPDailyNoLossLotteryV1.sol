// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0 < 0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "./utils/util/TimeLibrary.sol";
import "./utils/token/ERC677/IERC677.sol";
import "./utils/token/ERC677/SafeERC677.sol";

// [] 2.5B Billion BTCL Tokens
// [] 1.25B Burned -> $37.500.000 in total
// [] 1.25B Distributed -> $37.500.000 in total
// [] Daily -> 1.110.000 BTCL Daily for 1 Year => *365 = 401.500.000 BTCL
// [] Weekly -> 8.880.000 BTCL Weekly for 1 Year => *48 = 426.240.000 BTCL
// [] Monthly -> 35.188.333 BTCL Monthly for 1 Year => *12 = 422.260.000 BTCL
// 4.468.333 / 150 = 29788 BTCL / 10 Tickets = 2978 BTCL = 89$
// ->> OLD FIX THIS // [] - Monthly = 30.720.000 BTCL Monthly for 1 Year => *12 = 368.640.000 BTCL
// [] Daily -> 1.110.000 BTCL / 10 Winners = 111.000 BTCL * 0.03$ = 3330$ for each winner -> 3.3300$ per day
// [] Weekly -> 8.880.000 BTCL / 20 Winners = 444.000 BTCL * 0.03$ = 13320$ for each winner -> 266.400$ per week
// [] Monthly -> 35.188.333 BTCL / 30 Winners = 1.172.944 BTCL * 0.03$ = 35188$ for each winner -> 422.259 per month

// 4.468.333 DISTRIBUTED     \ 89.366.666 / 10 WINNERS / 150 DAYS = 5957 BTCL * 0.03$ = 178.71$
// 4.468.333 BURNED          /

// DAILY NO LOSS LOTTERY
contract BTCLPDailyNoLossLotteryV1 is Context, Ownable, ReentrancyGuard, VRFConsumerBase, KeeperCompatible {
    using TimeLibrary for uint;
    using SafeERC677 for IERC677;
    
    IERC677 private btclToken;
    IERC677 private nllToken;

    event LotteryOpen(uint256 lotteryRoundNr);
    event LotteryClose(uint256 lotteryRoundNr, uint256 totalTickets, uint256 totalPlayers);
    event LotteryCompleted(uint256 lotteryRoundNr, uint256[10] winningTicketsNr, address[10] winners);
    event BoughtTickets(address token, address player, uint256 tokens, bytes data);
    event Claim(address claimer, uint256 btclAmount, uint256 nllAmount);

    enum Status {
        Open,           // The lottery is open for ticket purchases
        Closed,         // The lottery is no longer open for ticket purchases
        Completed       // The lottery in this round has closed and the random lucky tickets have been drawn
    }

    struct Round {
        Status lotteryStatus;                       // Status for BTCL Daily No Loss Lottery
        bytes32 requestId;                          // Chainlink VRF Round Request ID
        uint256 randomResult;                       // Chainlink VRF Random Result (hex number)
        uint256 startDate;                          // Current Round Start Time
        uint256 endDate;                            // Current Round End Date
        uint256 totalUniquePlayers;                 // Total Unique Players in active round
        uint256 totalTickets;                       // Total Tickets Bought in active round
        uint256[10] luckyTickets;                   // 10 Lucky Tickets are drawn every round (you can win multiple times with 1 ticket)
        address[10] winners;                        // 10 Lucky Addresses of 10 Lucky Winnings Tickets
        mapping (uint256 => address) ticketNr;      // Get Players Addresses from their Ticket Numbers 
        mapping (address => uint256) totalBTCL;     // Total BTCL Contributed in active round
        mapping (address => uint256) totalNLL;      // Total NLL Contributed in active round
        mapping (address => bool) isUnique;         // Check if Player is Unique in current round
    }

    mapping(uint => Round) public rounds;

    // DAILY JACKPOT ROUND
    uint256 private blocksPerDay = 43200;
    uint256 public igoEndBlock = block.number; // 15 May 2022
    uint256 private btclEntry = 1200e18;
    uint256 private nllEntry = 1e18;
    uint256 public unclaimedTokens;
    uint256 public round;
    uint256 internal fee;
    bytes32 internal keyHash;
    bool public finalRound;

    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Mumbai
     * Chainlink VRF Coordinator address: 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255
     * LINK token address:                0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     * Key Hash: 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4
     */
    constructor(IERC677 _btclToken, IERC677 _nllToken 
        // ,address _burnContract
        ) 
        VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB  // LINK Token
        ){
        btclToken = _btclToken;
        nllToken = _nllToken;
        round = 1;
        rounds[round].startDate = block.timestamp;
        // rounds[round].endDate = rounds[round].startDate.addDays(1); // PRODUCTION
        rounds[round].endDate = rounds[round].startDate.addMinutes(4);
        rounds[round].lotteryStatus = Status.Open;
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 0.0001 * 10 ** 18; // 0.0001 LINK (Varies by network)
    }

    /**
     * @dev Get 1 Ticket Price with BTCL Tokens.
     * @custom:time every hour chance entry price increases by 50 BTCL Tokens
     */
    function getBtclPrice() public view returns (uint ticketPrice) {
        return btclEntry + (50 * (TimeLibrary.diffHours(rounds[round].startDate, block.timestamp) * 1e18));
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
    function claim(uint roundNr) public nonReentrant returns (uint256 claimedBTCL, uint256 claimedNLL) {
        require(roundNr > round, "Wait until round finishes");
        uint btclTokens = 0;
        uint nllTokens = 0;
        
        // CLAIM BTCL TOKENS AFTER IGO ENDS
        if(block.number >= igoEndBlock) {
            if(rounds[roundNr].totalBTCL[_msgSender()] > 0) {
                btclTokens = rounds[roundNr].totalBTCL[_msgSender()];
                rounds[roundNr].totalBTCL[_msgSender()] = 0;
                btclToken.safeTransfer(_msgSender(), btclTokens);
                unclaimedTokens -= btclTokens;
            }
        }

        // CLAIM NLL TOKENS MAX 1 DAY AFTER IGO CLIFF BLOCK
        if(block.number <= igoEndBlock + blocksPerDay) {
            if(rounds[roundNr].totalNLL[_msgSender()] > 0) {
                nllTokens = rounds[roundNr].totalNLL[_msgSender()];
                rounds[roundNr].totalNLL[_msgSender()] = 0;
                nllToken.safeTransfer(_msgSender(), nllTokens);
            }
        }

        emit Claim(_msgSender(), btclTokens, nllTokens);
        return (btclTokens, nllTokens);
    }

    /**
     * @dev Claim locked tokens + rewards from all rounds.
     * @return claimedBTCL and claimnedNLL
     */
    function claimAll() public nonReentrant returns (uint256 claimedBTCL, uint256 claimnedNLL) {
        uint btclTokens = 0;
        uint nllTokens = 0;
        for(uint i = 1; i <= round; i++) {
            // CLAIM BTCL TOKENS AFTER IGO ENDS
            if(block.number >= igoEndBlock) {
                if (rounds[i].totalBTCL[_msgSender()] > 0) {
                    uint btcl = rounds[i].totalBTCL[_msgSender()];
                    rounds[i].totalBTCL[_msgSender()] = 0;
                    btclTokens += btcl;
                }
            }

            // CLAIM NLL TOKENS UNTIL 1 DAY AFTER IGO CLIFF ENDS
            if(block.number <= igoEndBlock + blocksPerDay) {
                if(rounds[i].totalNLL[_msgSender()] > 0) {
                    uint nll = rounds[i].totalNLL[_msgSender()];
                    rounds[i].totalNLL[_msgSender()] = 0;
                    nllTokens += nll;
                }
            }
        }

        if(block.number >= igoEndBlock) {
            btclToken.safeTransfer(_msgSender(), btclTokens);
            unclaimedTokens -= btclTokens;
        }
        
        if(block.number <= igoEndBlock + blocksPerDay) {
            nllToken.safeTransfer(_msgSender(), nllTokens);
        }

        emit Claim(_msgSender(), btclTokens, nllTokens);
        return (btclTokens, nllTokens);
    }

    /**
     * @dev Helper function that is used to display winner addresses, contributions and lucky bonuses won
     * @param roundNr Desired round number.
     * @return bool Function returns round winners statistics.
     */
    function roundStats(uint roundNr) view public returns (address[] memory, uint[] memory, uint[] memory) {
        uint playersLength = rounds[roundNr].winners.length;
        uint[] memory contribution = new uint[](playersLength);
        uint[] memory totalBtclWon = new uint[](playersLength);
        address[] memory addresses = new address[](playersLength);

        for(uint i = 0; i < playersLength; i++){
            addresses[i] = rounds[roundNr].winners[i];
            contribution[i] = rounds[roundNr].totalBTCL[addresses[i]];
            totalBtclWon[i] = rounds[roundNr].totalNLL[addresses[i]];
        }

        return (addresses, contribution, totalBtclWon);
    }

    function getClaimableTokens(uint256 nr) public view returns (uint btcl, uint256 nll) {
        btcl = rounds[nr].totalBTCL[_msgSender()];
        nll = rounds[nr].totalNLL[_msgSender()];
    }

    /**
     * @dev Helper function for ChainLink VRF that extracts multiple random winning tickets from random entropy sources.
     * return array of winning tickets.
     */
    function expand(uint256 randomValue, uint256 totalWinningTickets, uint256 totalWinners) public pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](totalWinners);
        for (uint256 i = 0; i < totalWinners; i++) {
            expandedValues[i] = (uint256(keccak256(abi.encode(randomValue, i))) % totalWinningTickets) + 1;
        }
        return expandedValues;
    }

    /**
     * @dev Private function used by ChainLink Keepers to request one big random number from which we derive 10 winning tickets. 
     * returns requestId used by ChainLink VRF.
     */
    function getRandomNumber() private returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * @dev Callback function used by VRF Coordinator to draw winners, announce and setup next round.
     * @param requestId VRF Coordinator request.
     * @param randomness VRF Coordinator random result.
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual override {
        uint256[] memory winningTickets = expand(randomness, rounds[round].totalTickets, rounds[round].winners.length);
        (uint256 toReward, uint256 toBurn, bool isFinalRound) = rewardBurnRatio();
        for (uint i = 0; i < rounds[round].winners.length; i++) {
            address winnerAddress = rounds[round].ticketNr[winningTickets[i]];
            rounds[round].winners[i] = winnerAddress;
            rounds[round].luckyTickets[i] = winningTickets[i];
            rounds[round].totalBTCL[winnerAddress] = rounds[round].totalBTCL[winnerAddress] + toReward;
            unclaimedTokens += toReward;
        }
        (bool success,) = address(btclToken).call(abi.encodeWithSignature("burn(uint256)",toBurn));
        require(success,"burn FAIL");
        // btclToken.burn(address(this), toBurn);
        // btclToken.burn(toBurn);
        // btclToken.transfer(burnContract, toBurn);
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
            // rounds[round].endDate = rounds[round].startDate.addDays(1);
            rounds[round].endDate = rounds[round].startDate.addMinutes(4);
            emit LotteryOpen(round);
        }

    }

    function rewardBurnRatio() public view returns (uint256 toReward, uint256 toBurn, bool isFinalRound) {
        uint256 dailyPrize = 1111000e18; // added 1000 BTCL for first round
        uint256 deflation = round * 1000e18; // 1000 BTCL deflation deduction each day
        uint256 reward = dailyPrize - deflation; // initial prize minus daily deflation
        uint256 contractBalance = btclToken.balanceOf(address(this)) - unclaimedTokens;
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
            rounds[round].endDate.subMinutes(2) <= block.timestamp &&
            rounds[round].requestId == bytes32(0) &&
            rounds[round].lotteryStatus == Status.Open && 
            rounds[round].lotteryStatus != Status.Completed && 
            // rounds[round].totalUniquePlayers >= 2 && 
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
            block.timestamp >= rounds[round].endDate.subMinutes(2) && 
            rounds[round].lotteryStatus == Status.Open && 
            rounds[round].lotteryStatus != Status.Completed && 
            // rounds[round].totalUniquePlayers >= 2 && 
            rounds[round].totalTickets >= 10, 
            "Could not draw winnings tickets."
        );
        rounds[round].lotteryStatus == Status.Closed;
        emit LotteryClose(round, rounds[round].totalTickets, rounds[round].totalUniquePlayers);
        getRandomNumber();
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
    function withdrawLink() external onlyOwner {
        // require(round >= 365, "Can only be called after all rounds have finished");
        require(LINK.transfer(_msgSender(), LINK.balanceOf(address(this))), "Unable to transfer");
    }

    /**
     * @dev Helper function used to withdraw remaining LINK Tokens after all Daily Games have finished.
     */
    function withdrawBTCL() external onlyOwner {
        // require(round >= 365, "Can only be called after all rounds have finished");
        require(btclToken.transfer(_msgSender(), btclToken.balanceOf(address(this))), "Unable to transfer");
    }

    function getCurrentTime() public view returns (uint time) { time = block.timestamp; }
    function getCurrentBlockTime() public view returns (uint blockNr) { blockNr = block.number; }
    function getCurrentRoundTimeDiff() public view returns (uint time) { time = rounds[round].endDate - block.timestamp; }
    function getCurrentRoundEndRound() public view returns (bool time) { time = block.timestamp.addMinutes(2) >= rounds[round].endDate; }
    function getCurrentRoundNLLIgoRound() public view returns (bool time) { time = block.number >= igoEndBlock + blocksPerDay; }

    /**
     * @dev ERC677 TokenFallback Function.
     * @param _wallet The player address that sent tokens to the BTCL Daily No Loss Lottery Contract.
     * @param _value The amount of tokens sent by the player to the BTCL Daily No Loss Lottery Contract.
     * @param _data  The transaction metadata.
     */
    function onTokenTransfer(address _wallet, uint256 _value, bytes memory _data) public {
        // address parsed;
        // assembly {parsed := mload(add(_data, 32))}
        require(finalRound == false, "The daily BTCL No Loss Lottery has successfully distributed all 401.500.000 BTCL Tokens!");
        uint ticketPrice = getBtclPrice();
        buyTicket(_wallet, _value, ticketPrice, round, _data);
    }

    /**
     * @dev Helper function called by ERC677 onTokenTransfer function to 
     * calculate ticket slots for player and keep count of total tickets bought in the current round. 
     * @param _wallet The player address that sent tokens to the BTCL Daily No Loss Lottery Contract.
     * @param _totalTickets The amount of tokens sent by the player to the BTCL Daily No Loss Lottery Contract.
     */
    function buyTickets(address _wallet, uint _totalTickets) private {
        Round storage activeRound = rounds[round];
        uint total = activeRound.totalTickets;
        for(uint i = 1; i <= _totalTickets; i++){
            activeRound.ticketNr[total + i] = _wallet;
        }
        activeRound.totalTickets = total + _totalTickets;
    }

    // "0xA83299a769066869D5B539E1DD54D9EB6cb8aA30", "0xbdab7deBD24073aA9B4a9188E1010Ec36627Dba6"
    function buyTicket(address _wallet, uint256 _value, uint256 _btclEntryPrice, uint256 _round, bytes memory _data) private {    
        // BUY TICKET WITH BTCL
        if(_msgSender() == address(btclToken)) {
            require(_value % _btclEntryPrice == 0, "The Daily No Loss Lottery accepts multiple 1200 BTCL + Hourly increases of 50 BTCL for each chance.");
            require(_value / _btclEntryPrice <= 250, "Max 250 Tickets can be reserved at once using BTCL Tokens.");
            buyTickets(_wallet, _value / _btclEntryPrice);
            rounds[_round].totalBTCL[_wallet] = rounds[_round].totalBTCL[_wallet] + _value;
            unclaimedTokens += _value;
            emit BoughtTickets(address(btclToken), _wallet, _value, _data);
        // BUY TICKET WITH NLL
        } else if (_msgSender() == address(nllToken)) {
            require(_value % nllEntry == 0, "1 NLL Token = 1 Chance at any time.");
            require(_value / nllEntry <= 250, "Max 250 Tickets can be reserved at once using NLL Tokens.");
            buyTickets(_wallet, _value / nllEntry);
            rounds[_round].totalNLL[_wallet] = rounds[_round].totalNLL[_wallet] + _value;
            // se activeaza dubios mai bine il fac cu timestamp sau round numbers
            // if(block.number >= igoEndBlock + blocksPerDay) {
                // nllToken.burn(_msgSender(), _value);
                // nllToken.burn(_value);
                // nllToken.transfer(address(0), _value); // send and lock NLL Tokens using the 0x0 address
                (bool success,) = address(nllToken).call(abi.encodeWithSignature("burn(uint256)",_value));
                require(success,"burn FAIL");
            // }
            emit BoughtTickets(address(nllToken), _wallet, _value, _data);
            // BURN NLL TOKENS
        } else {
            revert("Provided amounts are not valid.");
        }
        // HIDRATE UNIQUE PLAYERS IN CURRENT ROUND
        if(rounds[_round].isUnique[_wallet] == false) {
            rounds[_round].isUnique[_wallet] = true;
            rounds[_round].totalUniquePlayers = rounds[_round].totalUniquePlayers + 1;
        }
    }

}