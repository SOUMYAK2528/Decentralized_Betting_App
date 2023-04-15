// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Dream11 {
    struct Match {
        string name;
        uint256 startTime;
        uint256 endTime;
        uint256 totalPlayers;
        uint256 winningAmount;
        Player[] players;
    }

    struct Player {
        address playerAddress;
        string name;
        uint256 score;
        bool isPlaying;
    }

    Match[] public matches;
    mapping(address => uint256) public balances;
    address payable public owner;

    event MatchCreated(uint256 indexed matchId, string name, uint256 startTime, uint256 endTime, uint256 totalPlayers, uint256 winningAmount);
    event PlayerJoined(uint256 indexed matchId, address playerAddress, string playerName, uint256 score, bool isPlaying);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function createMatch(string memory _name, uint256 _startTime, uint256 _endTime, uint256 _totalPlayers, uint256 _winningAmount) external onlyOwner {
        matches.push(Match(_name, _startTime, _endTime, _totalPlayers, _winningAmount, new Player[]()));
        emit MatchCreated(matches.length - 1, _name, _startTime, _endTime, _totalPlayers, _winningAmount);
    }

    function joinMatch(uint256 _matchId, string memory _name, uint256 _score) external payable {
        require(_matchId < matches.length, "Invalid match id");
        Match storage match = matches[_matchId];
        require(match.players.length < match.totalPlayers, "Match is full");
        require(msg.value == match.winningAmount, "Incorrect amount");
        match.players.push(Player(msg.sender, _name, _score, true));
        emit PlayerJoined(_matchId, msg.sender, _name, _score, true);
    }

    function getPlayerDetails(uint256 _matchId, address _playerAddress) external view returns (string[] memory, uint256[] memory, bool[] memory) {
        require(_matchId < matches.length, "Invalid match id");
        Match storage match = matches[_matchId];
        uint256 length = match.players.length;
        string[] memory playerNames = new string[](length);
        uint256[] memory playerScores = new uint256[](length);
        bool[] memory isPlaying = new bool[](length);
        for (uint256 i = 0; i < length; i++) {
            Player storage player = match.players[i];
            playerNames[i] = player.name;
            playerScores[i] = player.score;
            isPlaying[i] = player.isPlaying;
        }
        return (playerNames, playerScores, isPlaying);
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Withdraw failed");
    }
}
