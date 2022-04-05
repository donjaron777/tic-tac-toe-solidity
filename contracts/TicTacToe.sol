//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract TicTacToe {
    uint256 gamesCount = 0;

    enum GameState {
        Start,
        Draw,
        XPlaying,
        OPlaying,
        XVictory,
        OVictory,
        XVictoryByTimeout,
        YVictoryByTimeOut
    }

    enum BoardMove {
        None,
        X,
        O
    }

    struct TTTGame {
        address player1;
        address player2;
        uint256 player1Bet;
        uint256 player2Bet;
        uint256 lastTimeStamp;
        uint256 startTimeStamp;
        GameState gameState;
        BoardMove[3][3] board;
    }

    mapping(uint256 => TTTGame) private games;
    mapping(address => uint256) private gameUserMappings;

    event Player1Created(uint256 gameId, address player1, uint256 timeStamp);
    event Player2Joined(
        uint256 gameId,
        TTTGame game,
        address player2,
        uint256 timeStamp
    );
    event Move(
        uint256 gameId,
        BoardMove[3][3] board,
        uint256 timeStamp,
        string moveType
    );
    event EndGame(
        uint256 gameId,
        TTTGame game,
        uint256 timeStamp,
        string endType
    );

    modifier checkUnoccupiedPresent(uint256 _gameId) {
        require(
            getUnoccupiedPresent(_gameId) == true,
            "There is no space on the board to play"
        );
        _;
    }

    modifier checkCorrectBet() {
        require(msg.value == 500000000000000000, "Invalid stake");
        _;
    }

    modifier checkIsGameOwner(uint256 _gameId) {
        require(gameUserMappings[msg.sender] == _gameId, "No right");
        _;
    }

    function purgeGameData(uint256 _gameId) private {
        delete gameUserMappings[games[_gameId].player1];
        delete gameUserMappings[games[_gameId].player2];
        delete games[_gameId];
    }

    function onlyUnenrolled() private view {
        require(
            gameUserMappings[msg.sender] == 0,
            "You already play with someone"
        );
    }

    /*function getBoard(uint256 _gameId)
        public
        view
        returns (BoardMove[3][3] memory)
    {
        BoardMove[3][3] memory bm = games[_gameId].board;
        return bm;
    }*/

    function getUnoccupiedPresent(uint256 _gameId) private view returns (bool) {
        bool foundNone = false;

        for (uint8 i; i < games[_gameId].board.length; i++) {
            for (uint8 j; j < games[_gameId].board.length; j++) {
                if (games[_gameId].board[i][j] == BoardMove.None) {
                    foundNone = true;
                    break;
                }
            }
            if (foundNone == true) {
                break;
            }
        }
        return foundNone;
    }

    function getCurrentPlayer(uint256 _gameId) private view returns (address) {
        if (games[_gameId].gameState == GameState.XPlaying) {
            return games[_gameId].player1;
        } else if (games[_gameId].gameState == GameState.OPlaying) {
            return games[_gameId].player2;
        } else {
            revert("Unexpected");
        }
    }

    function newGame() public payable checkCorrectBet returns (uint256) {
        onlyUnenrolled();

        require(gamesCount <= 200, "Many games");
        gamesCount++;

        gameUserMappings[msg.sender] = gamesCount;
        games[gamesCount].player1 = msg.sender;
        games[gamesCount].player1Bet = msg.value;
        games[gamesCount].gameState = GameState.Start;
        emit Player1Created(gamesCount, msg.sender, block.timestamp);

        return gamesCount;
    }

    function joinGame(uint256 _gameId) public payable checkCorrectBet {
        onlyUnenrolled();

        require(games[_gameId].gameState == GameState.Start, "Players=2");

        gameUserMappings[msg.sender] = _gameId;
        games[_gameId].player2 = msg.sender;
        games[_gameId].player2Bet = msg.value;

        //initializing game fully
        games[_gameId].startTimeStamp = block.timestamp;

        games[_gameId].gameState = GameState.XPlaying;

        emit Player2Joined(
            _gameId,
            games[_gameId],
            msg.sender,
            block.timestamp
        );
    }

    function xPlay(
        uint256 _gameId,
        uint8 _i,
        uint8 _j
    ) public checkIsGameOwner(_gameId) {
        require(games[_gameId].gameState == GameState.XPlaying, "O turn");
        require(games[_gameId].board[_i][_j] == BoardMove.None, "Occupied");

        games[_gameId].board[_i][_j] = BoardMove.X;
        games[_gameId].gameState = GameState.OPlaying;
        games[_gameId].lastTimeStamp = block.timestamp;

        emit Move(_gameId, games[_gameId].board, block.timestamp, "X played");

        checkWinner(_gameId);
    }

    function oPlay(
        uint256 _gameId,
        uint8 _i,
        uint8 _j
    ) public checkIsGameOwner(_gameId) {
        require(games[_gameId].gameState == GameState.OPlaying, "X turn");
        require(games[_gameId].board[_i][_j] == BoardMove.None, "Occupied");
        games[_gameId].board[_i][_j] = BoardMove.O;
        games[_gameId].gameState = GameState.XPlaying;
        games[_gameId].lastTimeStamp = block.timestamp;

        emit Move(_gameId, games[_gameId].board, block.timestamp, "O played");

        checkWinner(_gameId);
    }

    function checkRows(uint256 _gameId)
        private
        view
        returns (BoardMove moveType)
    {
        BoardMove[3][3] memory board = games[_gameId].board;
        //1
        if (
            board[0][0] != BoardMove.None &&
            board[0][0] == board[0][1] &&
            board[0][0] == board[0][2]
        ) {
            return board[0][0];
        }
        //2
        if (
            board[1][0] != BoardMove.None &&
            board[1][0] == board[1][1] &&
            board[1][0] == board[1][2]
        ) {
            return board[1][0];
        }
        //3
        if (
            board[2][0] != BoardMove.None &&
            board[2][0] == board[2][1] &&
            board[2][0] == board[2][2]
        ) {
            return board[2][0];
        }

        //Checking columns

        //1
        if (
            board[0][0] != BoardMove.None &&
            board[0][0] == board[1][0] &&
            board[0][0] == board[2][0]
        ) {
            return board[0][0];
        }
        //2
        if (
            board[0][1] != BoardMove.None &&
            board[0][1] == board[1][1] &&
            board[0][1] == board[2][1]
        ) {
            return board[0][1];
        }
        //3
        if (
            board[0][2] != BoardMove.None &&
            board[0][2] == board[1][2] &&
            board[0][2] == board[2][2]
        ) {
            return board[0][2];
        }

        //Checking diagonals

        //1
        if (
            board[0][0] != BoardMove.None &&
            board[0][0] == board[1][1] &&
            board[0][0] == board[2][2]
        ) {
            return board[0][0];
        }
        //2
        if (
            board[0][2] != BoardMove.None &&
            board[0][2] == board[1][1] &&
            board[0][2] == board[2][0]
        ) {
            return board[0][2];
        }

        return BoardMove.None;
    }

    function checkWinner(uint256 _gameId) private {
        // checking dimensions,
        // if all the dimensions are full and the rows, diagonals or columns
        // are not filled, draw.

        BoardMove winBoardType = checkRows(_gameId);

        //nobody found to win, checking for draw
        if (winBoardType == BoardMove.None && !getUnoccupiedPresent(_gameId)) {
            setDrawGame(_gameId);
        } else if (winBoardType != BoardMove.None) {
            setWinGame(_gameId, winBoardType);
        }
    }

    function setDrawGame(uint256 _gameId) private {
        games[_gameId].gameState = GameState.Draw;
        payable(games[_gameId].player1).transfer(games[_gameId].player1Bet);
        payable(games[_gameId].player2).transfer(games[_gameId].player2Bet);

        emit EndGame(_gameId, games[_gameId], block.timestamp, "Draw");
        purgeGameData(_gameId);
    }

    function claimWinGameByTimeout(uint256 _gameId)
        public
        checkIsGameOwner(_gameId)
    {
        //current player loses
	//10 left for test purposes
        require(
            (block.timestamp - games[_gameId].lastTimeStamp) >= 10,
            "Playing"
        );

        uint256 totalBet = games[_gameId].player1Bet +
            games[_gameId].player2Bet;
        address currentPlayer = getCurrentPlayer(_gameId);
        if (games[_gameId].player1 == currentPlayer) {
            games[_gameId].gameState = GameState.OVictory;
            payable(games[_gameId].player2).transfer(totalBet);
        } else {
            games[_gameId].gameState = GameState.XVictory;
            payable(games[_gameId].player1).transfer(totalBet);
        }
        emit EndGame(_gameId, games[_gameId], block.timestamp, "TimeOut");
        purgeGameData(_gameId);
    }

    function setWinGame(uint256 _gameId, BoardMove _bm) private {
        if (_bm == BoardMove.X) {
            games[_gameId].gameState = GameState.XVictory;
        } else if (_bm == BoardMove.O) {
            games[_gameId].gameState = GameState.OVictory;
        } else {
            revert("Unexpected");
        }

        uint256 totalBet = games[_gameId].player1Bet +
            games[_gameId].player2Bet;

        if (games[_gameId].gameState == GameState.XVictory) {
            // Player 1 is only X, so rewarding him.
            payable(games[_gameId].player1).transfer(totalBet);
        } else if (games[_gameId].gameState == GameState.OVictory) {
            // Player 2 is only O, so rewarding him.
            payable(games[_gameId].player2).transfer(totalBet);
        }
        emit EndGame(_gameId, games[_gameId], block.timestamp, "Win");
        purgeGameData(_gameId);
    }
}
