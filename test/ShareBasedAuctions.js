const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("ShareBasedAuctions", function () {
  let owner, bidder1, bidder2, bidder3, auction, token;

  beforeEach(async function () {
    [owner, bidder1, bidder2, bidder3] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("ERC20Mock");
    token = await Token.deploy("Test Token", "TT");

    const Auction = await ethers.getContractFactory("ShareBasedAuctions");
    auction = await upgrades.deployProxy(Auction, [token.target], { kind: 'uups' });

    await token.mint(owner.address, 3000);
    await token.approve(auction.target, 3000);
  });

  it("Should not allow auction start if already ended", async function () {
    await auction.startAuction(1000, 3600);
    await ethers.provider.send("evm_increaseTime", [3601]);
    await auction.endAuction();

    await expect(auction.startAuction(1000, 3600))
      .to.be.revertedWith("Auction already ended");
  });

  it("Should not allow auction start if already started", async function () {
    await auction.startAuction(1000, 3600);

    await expect(auction.startAuction(1000, 3600))
      .to.be.revertedWith("Auction already started");
  });

  it("Should not allow auction start with zero quantity", async function () {
    await expect(auction.startAuction(0, 3600))
      .to.be.revertedWith("Quantity must be > 0");
  });

  it("Should not allow auction start with zero duration", async function () {
    await expect(auction.startAuction(1000, 0))
      .to.be.revertedWith("Duration must be > 0");
  });

  it("Should allow bids and distribute tokens based on total contribution", async function () {
    await auction.startAuction(1000, 3600);

    await auction.connect(bidder1).placeBid(500, 10);
    await auction.connect(bidder2).placeBid(400, 25);
    await auction.connect(bidder3).placeBid(200, 5);

    await ethers.provider.send("evm_increaseTime", [3601]);
    await auction.endAuction();

    await auction.connect(bidder1).withdrawWinnings();
    await auction.connect(bidder2).withdrawWinnings();
    await auction.connect(bidder3).withdrawWinnings();

    expect(await token.balanceOf(bidder1.address)).to.equal(312); // 5000 / 16000 * 1000
    expect(await token.balanceOf(bidder2.address)).to.equal(625); // 10000 / 16000 * 1000
    expect(await token.balanceOf(bidder3.address)).to.equal(62); // 1000 / 16000 * 1000
  });

  it("Should handle the case when there are no bids", async function () {
    await auction.startAuction(1000, 3600);

    await ethers.provider.send("evm_increaseTime", [3601]);
    await auction.endAuction();

    await expect(auction.connect(bidder1).withdrawWinnings())
      .to.be.revertedWith("No tokens to claim");
  });

  it("Should not allow owner place bids", async function () {
    await auction.startAuction(1000, 3600);
    await expect(auction.connect(owner).placeBid(500, 10))
      .to.be.revertedWith("Owner cannot bid");
  });

  it("Should not allow new bids after auction end", async function () {
    await auction.startAuction(1000, 3600);
    await ethers.provider.send("evm_increaseTime", [3601]);
    await auction.endAuction();

    await expect(auction.connect(bidder1).placeBid(500, 10))
      .to.be.revertedWith("Auction ended");
  });

  it("Should not allow withdrawals before auction end", async function () {
    await auction.startAuction(1000, 3600);
    await auction.connect(bidder1).placeBid(500, 10);

    await expect(auction.connect(bidder1).withdrawWinnings())
      .to.be.revertedWith("Auction not ended");
  });

  it("Should not allow zero quantity or price bids", async function () {
    await auction.startAuction(1000, 3600);

    await expect(auction.connect(bidder1).placeBid(0, 10))
      .to.be.revertedWith("Quantity must be > 0");

    await expect(auction.connect(bidder1).placeBid(500, 0))
      .to.be.revertedWith("Price must be > 0");
  });
});
