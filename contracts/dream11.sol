// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Dream11 {
    struct Match {
        string name;
        uint256 startTime;
        uint256 endTime;
        uint256 totalPlayers;
        uint256 winningAmount;
        mapping(address => bool) players;
        mapping(address => uint256) scores;
    }

    Match[] public matches;
    mapping(address => uint256) public balances;

    event MatchCreated(
        string name,
        uint256 startTime,
        uint256 endTime,
        uint256 totalPlayers,
        uint256 winningAmount
    );
    event PlayerJoined(uint256 matchIndex, address player);
    event ScoreSubmitted(uint256 matchIndex, address player, uint256 score);
    event PrizeDistributed(
        uint256 matchIndex,
        address[] winners,
        uint256[] prizes
    );

    function createMatch(
        string memory _name,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _totalPlayers,
        uint256 _winningAmount
    ) public {
        matches.push(
            Match(_name, _startTime, _endTime, _totalPlayers, _winningAmount,new  mapping(address => bool)(), new mapping(address => uint256))
        );
        emit MatchCreated(
            _name,
            _startTime,
            _endTime,
            _totalPlayers,
            _winningAmount
        );
    }

    function joinMatch(uint256 _matchIndex) public payable {
        require(_matchIndex < matches.length, "Invalid match index");
        require(
            msg.value == matches[_matchIndex].winningAmount,
            "Incorrect amount sent"
        );
        require(
            !matches[_matchIndex].players[msg.sender],
            "Player already joined"
        );

        matches[_matchIndex].players[msg.sender] = true;
        emit PlayerJoined(_matchIndex, msg.sender);
    }

    function submitScore(uint256 _matchIndex, uint256 _score) public {
        require(_matchIndex < matches.length, "Invalid match index");
        require(matches[_matchIndex].players[msg.sender], "Player not joined");
        require(_score <= 100, "Invalid score");

        matches[_matchIndex].scores[msg.sender] = _score;
        emit ScoreSubmitted(_matchIndex, msg.sender, _score);
    }

    function distributePrizes(uint256 _matchIndex) public {
        require(_matchIndex < matches.length, "Invalid match index");
        require(
            block.timestamp >= matches[_matchIndex].endTime,
            "Match not ended"
        );

        uint256 totalScore = 0;
        address[] memory winners = new address[](
            matches[_matchIndex].totalPlayers
        );
        uint256[] memory scores = new uint256[](
            matches[_matchIndex].totalPlayers
        );

        // Calculate total score and find winners
        for (uint256 i = 0; i < matches[_matchIndex].totalPlayers; i++) {
            address player = getAddressAtIndex(matches[_matchIndex].players, i);
            uint256 score = matches[_matchIndex].scores[player];
            scores[i] = score;
            totalScore += score;

            if (i == 0 || score > matches[_matchIndex].scores[winners[0]]) {
                // Found a new winner
                for (uint256 j = 0; j < winners.length; j++) {
                    winners[j] = address(0);
                }

                winners[0] = player;
            } else if (score == matches[_matchIndex].scores[winners[0]]) {
                // Found another winner with same score
                for (uint256 j = 1; j < winners.length; j++) {
                    if (winners[j] == address(0)) {
                        winners[j] = player;
                        break;
                    }
                }
            }
        }

        // Distribute prizes to winners
        uint256 totalPrize = matches[_matchIndex].totalPlayers *
            matches[_matchIndex].winningAmount;
        uint256 remainingPrize = totalPrize;
        uint256 totalWinnerScore = 0;
        for (uint256 i = 0; i < winners.length; i++) {
            if (winners[i] == address(0)) {
                break;
            }

            uint256 winnerScore = matches[_matchIndex].scores[winners[i]];
            uint256 winnerPrize = (winnerScore * totalPrize) / totalScore;
            balances[winners[i]] += winnerPrize;
            remainingPrize -= winnerPrize;
            totalWinnerScore += winnerScore;
        }

        // Distribute remaining prize equally to non-winners
        uint256 nonWinnerCount = matches[_matchIndex].totalPlayers -
            winners.length;
        uint256 nonWinnerPrize = remainingPrize / nonWinnerCount;

        for (uint256 i = 0; i < matches[_matchIndex].totalPlayers; i++) {
            address player = getAddressAtIndex(matches[_matchIndex].players, i);

            if (!isAddressInArray(player, winners)) {
                balances[player] += nonWinnerPrize;
            }
        }

        emit PrizeDistributed(_matchIndex, winners, scores);
    }

    function withdraw() public {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "Insufficient balance");
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
    }

    function getAddressAtIndex(
        mapping(address => bool) storage _mapping,
        uint256 _index
    ) internal view returns (address) {
        uint256 i = 0;

        for (uint256 j = 0; j < _mapping.keys.length; j++) {
            if (_mapping[_mapping.keys[j]]) {
                if (i == _index) {
                    return _mapping.keys[j];
                }

                i++;
            }
        }

        revert("Invalid index");
    }

    function isAddressInArray(
        address _address,
        address[] memory _array
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < _array.length; i++) {
            if (_array[i] == _address) {
                return true;
            }
        }

        return false;
    }
}
