  pragma solidity ^0.8.0;
 // SPDX-License-Identifier: UNLICENSED

contract BettingApp {
    
    address public owner;
    uint256 public minimumBet;
    uint256 public totalBets;
    uint256 public winningOutcome;
    uint256 public poolSize;
    bool public bettingOpen;
    
    struct Bet {
        uint256 outcome;
        uint256 amount;
    }
    
    mapping(address => Bet) public bets;
    address[] public betters;
    mapping(uint256 => uint256) public outcomeBets;
    
    event NewBet(address indexed from, uint256 outcome, uint256 amount);
    event WinningOutcome(uint256 outcome, uint256 poolSize);
    event BetRefunded(address indexed to, uint256 amount);
    
    constructor(uint256 _minimumBet, uint256 _winningOutcome) {
        owner = msg.sender;
        minimumBet = _minimumBet;
        bettingOpen = true;
        winningOutcome = _winningOutcome;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }
    
    modifier duringBetting() {
        require(bettingOpen, "Betting is closed.");
        _;
    }
    
    modifier afterBetting() {
        require(!bettingOpen, "Betting is still open.");
        _;
    }
    
    function bet(uint256 _outcome) external payable duringBetting {
        require(msg.value >= minimumBet, "Bet amount must be greater than or equal to the minimum bet.");
        require(_outcome != winningOutcome, "Outcome cannot be the same as the winning outcome.");
        
        Bet storage playerBet = bets[msg.sender];

        if (playerBet.amount == 0) {
            betters.push(msg.sender);
        }
        
        uint256 refundAmount = playerBet.amount;
        if (playerBet.amount > 0) {
            outcomeBets[playerBet.outcome] -= playerBet.amount;
            refundAmount += playerBet.amount;
        }
        
        playerBet.outcome = _outcome;
        playerBet.amount = msg.value;
        outcomeBets[_outcome] += msg.value;
        totalBets += msg.value;
        poolSize += msg.value;
        
        emit NewBet(msg.sender, _outcome, msg.value);
        
        if (refundAmount > 0) {
            payable(msg.sender).transfer(refundAmount);
            emit BetRefunded(msg.sender, refundAmount);
        }
    }
    
    function closeBetting() external onlyOwner duringBetting {
        bettingOpen = false;
        emit WinningOutcome(winningOutcome, poolSize);
    }
    
    function payWinners() external onlyOwner afterBetting {
        uint256 winningPool = outcomeBets[winningOutcome];
        require(winningPool > 0, "No bets were placed on the winning outcome.");
        
        for (uint256 i = 0; i < betters.length; i++) {
            Bet storage playerBet = bets[betters[i]];
            if (playerBet.outcome == winningOutcome) {
                uint256 payout = (playerBet.amount * poolSize) / winningPool;
                payable(betters[i]).transfer(payout);
            }
        }
    }
    
    function refundBets() external onlyOwner afterBetting {
        for (uint256 i = 0; i < betters.length; i++) {
            Bet storage playerBet = bets[betters[i]];
            uint256 refundAmount = playerBet.amount;
            if (refundAmount > 0) {
                payable(betters[i]).transfer(refundAmount);
                emit BetRefunded(betters[i], refundAmount);
           
    }
}}

function withdrawFunds() external onlyOwner afterBetting {
    payable(owner).transfer(address(this).balance);
}

}
