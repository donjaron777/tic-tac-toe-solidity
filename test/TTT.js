const { expect } = require("chai");
const { ethers } = require("hardhat");

//helper function
function logEvents(events) {
	for (let k in events) {
		//iterating events
		let e = events[k].event;
		let args = events[k].args;
		console.log(e)
		console.log(args);
	}
}

describe('TicTacToe game creation testing:', function () {
	let TTT, ttt, owner, addr1, addr2, addr3, addr4;

	beforeEach(async () => {
		TTT = await ethers.getContractFactory('TicTacToe');
		ttt = await TTT.deploy();

		[owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
		await ttt.deployed();
	});

	it('Creating the game with an illegal stake is reverted', async () => {
		const options = { value: ethers.utils.parseEther("0.4") }
		await expect(ttt.connect(addr1).newGame(options)).to.be.revertedWith('Invalid stake');
	});

	it('Joining the game with an illegal stake is reverted', async () => {
		const valid_options = { value: ethers.utils.parseEther("0.5") }
		const invalid_options = { value: ethers.utils.parseEther("0.4") }
		let tx = await ttt.connect(addr1).newGame(valid_options);
		let rc = await tx.wait();

		let gameId = 0;
		if (rc.events.length > 0) {
			gameId = rc.events[0].args.gameId;
		}

		await expect(ttt.connect(addr2).joinGame(gameId, invalid_options)).to.be.revertedWith('Invalid stake');
	});

	it('Initializing a game by an enrolled gamer(creator) is prohibited', async () => {
		const options = { value: ethers.utils.parseEther("0.5") }
		let tx = await ttt.connect(addr1).newGame(options);
		let rc = await tx.wait();

		await expect(ttt.connect(addr1).newGame(options)).to.be.reverted;
	});

	it('Initializing a game by an enrolled gamer(joinee) is prohibited', async () => {
		const options = { value: ethers.utils.parseEther("0.5") }
		let gameId = 0;

		let tx = await ttt.connect(addr1).newGame(options);
		let rc = await tx.wait();

		if (rc.events.length > 0) {
			gameId = rc.events[0].args.gameId;
		}

		let tx1 = await ttt.connect(addr2).joinGame(gameId, options);
		await tx1.wait();

		await expect(ttt.connect(addr2).newGame(options)).to.be.reverted;
	});

});

describe('TicTacToe game mechanics:', function () {
	let TTT, ttt, owner, addr1, addr2, gameId;
	const options = { value: ethers.utils.parseEther("0.5") };

	beforeEach(async () => {
		TTT = await ethers.getContractFactory('TicTacToe');
		ttt = await TTT.deploy();

		[owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
		await ttt.deployed();

		let tx = await ttt.connect(addr1).newGame(options);
		let rc = await tx.wait();

		if (rc.events.length > 0) {
			gameId = rc.events[0].args.gameId;
		}

		let tx1 = await ttt.connect(addr2).joinGame(gameId, options);
		await tx1.wait();
	});
	it('Joining the game when there are 2 players', async () => {
		await expect(ttt.connect(addr3).joinGame(gameId, options)).to.be.revertedWith('Players=2');
	});
	it('Accessing unauthorized game', async () => {
		//Creating second game

		let tx = await ttt.connect(addr3).newGame(options);
		let rc = await tx.wait();

		if (rc.events.length > 0) {
			gameId = rc.events[0].args.gameId;
		}

		await expect(ttt.connect(addr1).xPlay(gameId, 1, 1)).to.be.revertedWith('No right');
	});

	it('Moves in a row are prohibited', async () => {
		let tx = await ttt.connect(addr2).xPlay(gameId, 0, 1);
		let rc = await tx.wait();

		await expect(ttt.connect(addr2).xPlay(gameId, 1, 1)).to.be.reverted;
	});
	it('Moves in the same place are prohibited', async () => {
		let tx = await ttt.connect(addr1).xPlay(gameId, 0, 1);
		let rc = await tx.wait();

		await expect(ttt.connect(addr2).oPlay(gameId, 0, 1)).to.be.reverted;
	});
	it('Game finishes when a column is filled', async () => {
		let tx = await ttt.connect(addr1).xPlay(gameId, 0, 0);
		let rc = await tx.wait();
		// console.log("0");
		// logEvents(rc.events);

		let tx1 = await ttt.connect(addr2).oPlay(gameId, 0, 1);
		let rc1 = await tx1.wait();
		// console.log("1");
		// logEvents(rc1.events);

		let tx2 = await ttt.connect(addr1).xPlay(gameId, 1, 0);
		let rc2 = await tx2.wait();
		// console.log("2");
		// logEvents(rc2.events);

		let tx3 = await ttt.connect(addr2).oPlay(gameId, 1, 1);
		let rc3 = await tx3.wait();
		// console.log("3");
		// logEvents(rc3.events);

		let tx4 = await ttt.connect(addr1).xPlay(gameId, 2, 0);
		let rc4 = await tx4.wait();
		// console.log("4");
		// logEvents(rc4.events);

		//Game data is purged
		await expect(ttt.connect(addr2).oPlay(gameId, 2, 1)).to.be.revertedWith('No right');
	});
	it('Game finishes when a row is filled', async () => {
		let tx = await ttt.connect(addr1).xPlay(gameId, 0, 0);
		let rc = await tx.wait();
		// console.log("0");
		// logEvents(rc.events);

		let tx1 = await ttt.connect(addr2).oPlay(gameId, 1, 0);
		let rc1 = await tx1.wait();
		// console.log("1");
		// logEvents(rc1.events);

		let tx2 = await ttt.connect(addr1).xPlay(gameId, 0, 1);
		let rc2 = await tx2.wait();
		// console.log("2");
		// logEvents(rc2.events);

		let tx3 = await ttt.connect(addr2).oPlay(gameId, 1, 1);
		let rc3 = await tx3.wait();
		// console.log("3");
		// logEvents(rc3.events);

		let tx4 = await ttt.connect(addr1).xPlay(gameId, 0, 2);
		let rc4 = await tx4.wait();
		// console.log("4");
		// logEvents(rc4.events);

		//Game data is purged
		await expect(ttt.connect(addr2).oPlay(gameId, 1, 2)).to.be.revertedWith('No right');
	});
	it('Game finishes when a diagonal is filled', async () => {
		let tx = await ttt.connect(addr1).xPlay(gameId, 0, 0);
		let rc = await tx.wait();
		// console.log("0");
		// logEvents(rc.events);

		let tx1 = await ttt.connect(addr2).oPlay(gameId, 0, 1);
		let rc1 = await tx1.wait();
		// console.log("1");
		// logEvents(rc1.events);

		let tx2 = await ttt.connect(addr1).xPlay(gameId, 1, 1);
		let rc2 = await tx2.wait();
		// console.log("2");
		// logEvents(rc2.events);

		let tx3 = await ttt.connect(addr2).oPlay(gameId, 1, 2);
		let rc3 = await tx3.wait();
		// console.log("3");
		// logEvents(rc3.events);

		let tx4 = await ttt.connect(addr1).xPlay(gameId, 2, 2);
		let rc4 = await tx4.wait();
		// console.log("4");
		// logEvents(rc4.events);

		//Game data is purged
		await expect(ttt.connect(addr2).oPlay(gameId, 0, 2)).to.be.revertedWith('No right');
	});
	it('Game finishes when draw', async () => {
		let tx = await ttt.connect(addr1).xPlay(gameId, 0, 1);
		let rc = await tx.wait();

		let tx1 = await ttt.connect(addr2).oPlay(gameId, 0, 0);
		let rc1 = await tx1.wait();

		let tx2 = await ttt.connect(addr1).xPlay(gameId, 0, 2);
		let rc2 = await tx2.wait();

		let tx3 = await ttt.connect(addr2).oPlay(gameId, 1, 1);
		let rc3 = await tx3.wait();

		let tx4 = await ttt.connect(addr1).xPlay(gameId, 1, 0);
		let rc4 = await tx4.wait();

		let tx5 = await ttt.connect(addr2).oPlay(gameId, 1, 2);
		let rc5 = await tx5.wait();

		let tx6 = await ttt.connect(addr1).xPlay(gameId, 2, 1);
		let rc6 = await tx6.wait();

		let tx7 = await ttt.connect(addr2).oPlay(gameId, 2, 0);
		let rc7 = await tx7.wait();

		let tx8 = await ttt.connect(addr1).xPlay(gameId, 2, 2);
		let rc8 = await tx8.wait();

		// console.log("8");
		// logEvents(rc8.events);

		//Move + Win(Draw) events are fired
		expect(rc8.events[1].args.endType).to.equal('Draw');
	});
 	it('Claiming win before timeout', async () => {
                let tx = await ttt.connect(addr1).xPlay(gameId, 0, 1);
                let rc = await tx.wait();

                await expect(ttt.connect(addr2).claimWinGameByTimeout(gameId)).to.be.revertedWith('Playing');

        });
        it('Claiming win after timeout', async () => {
                let tx = await ttt.connect(addr1).xPlay(gameId, 0, 1);
                let rc = await tx.wait();
                await new Promise(resolve => setTimeout(resolve, 11000)); // 11 sec

                let tx1 = await ttt.connect(addr2).claimWinGameByTimeout(gameId)
                let rc1 = await tx1.wait();

                expect(rc1.events[0].args.endType).to.equal('TimeOut');
        });
});
