const { expect } = require("chai");

describe("Dream11", function () {
  let dream11;
  let owner;
  let player1;
  let player2;

  beforeEach(async function () {
    const Dream11 = await ethers.getContractFactory("Dream11");
    [owner, player1, player2] = await ethers.getSigners();
    dream11 = await Dream11.deploy();
    await dream11.deployed();
  });

  it("should create a new match", async function () {
    await dream11.createMatch("Match 1", 1620014400, 1620100800, 2, ethers.utils.parseEther("0.1"));
    const match = await dream11.matches(0);
    expect(match.name).to.equal("Match 1");
    expect(match.startTime).to.equal(1620014400);
    expect(match.endTime).to.equal(1620100800);
    expect(match.totalPlayers).to.equal(2);
    expect(match.winningAmount).to.equal(ethers.utils.parseEther("0.1"));
  });

  it("should allow players to join a match", async function () {
    await dream11.createMatch("Match 1", 1620014400, 1620100800, 2, ethers.utils.parseEther("0.1"));
    await expect(dream11.connect(player1).joinMatch(0, "Player 1", 50, { value: ethers.utils.parseEther("0.1") })).to.emit(dream11, "PlayerJoined").withArgs(0, player1.address, "Player 1", 50, true);
    await expect(dream11.connect(player2).joinMatch(0, "Player 2", 75, { value: ethers.utils.parseEther("0.1") })).to.emit(dream11, "PlayerJoined").withArgs(0, player2.address, "Player 2", 75, true);
    const [playerNames, playerScores, isPlaying] = await dream11.getPlayerDetails(0, player1.address);
    expect(playerNames[0]).to.equal("Player 1");
    expect(playerScores[0]).to.equal(50);
    expect(isPlaying[0]).to.equal(true);
    const [playerNames2, playerScores2, isPlaying2] = await dream11.getPlayerDetails(0, player2.address);
    expect(playerNames2[0]).to.equal("Player 2");
    expect(playerScores2[0]).to.equal(75);
    expect(isPlaying2[0]).to.equal(true);
  });

  it("should not allow players to join a full match", async function () {
    await dream11.createMatch("Match 1", 1620014400, 1620100800, 1, ethers.utils.parseEther("0.1"));
    await expect(dream11.connect(player1).joinMatch(0, "Player 1", 50, { value: ethers.utils.parseEther("0.1") })).to.emit(dream11, "PlayerJoined").withArgs(0, player1.address, "Player 1", 50, true);
    await expect(dream11.connect(player2).joinMatch(0, "Player 2", 75, { value: ethers.utils.parseEther("0.1") })).to.be.revertedWith("Match is full");
  });

  it("should not allow players to join an invalid match", async function () {
    await expect(dream11.connect(player1).joinMatch(0, "Player 1", 50, { value: ethers.utils.parseEther("0.1") })).to.be.revertedWith("Invalid match ID");
   });
   it("should not allow players to join after the match has started", async function () {
    await dream11.createMatch("Match 1", Math.floor(Date.now() / 1000) + 10, Math.floor(Date.now() / 1000) + 20, 2, ethers.utils.parseEther("0.1"));
    await expect(dream11.connect(player1).joinMatch(0, "Player 1", 50, { value: ethers.utils.parseEther("0.1") })).to.emit(dream11, "PlayerJoined").withArgs(0, player1.address, "Player 1", 50, true);
    await expect(dream11.connect(player2).joinMatch(0, "Player 2", 75, { value: ethers.utils.parseEther("0.1") })).to.be.revertedWith("Match has already started");
    const [playerNames, playerScores, isPlaying] = await dream11.getPlayerDetails(0, player2.address);
    expect(playerNames[0]).to.equal("");
    expect(playerScores[0]).to.equal(0);
    expect(isPlaying[0]).to.equal(false);
  });
})

