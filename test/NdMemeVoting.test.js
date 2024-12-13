const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NdMemeVoting Contract", function () {
  let NdMemeVoting, ndMemeVoting, Token, token;
  let owner, addr1, addr2;

  beforeEach(async function () {
    // Deploy ERC20Mock contract
    const Token = await ethers.getContractFactory("ERC20Mock");
    token = await Token.deploy("MockToken", "MTK", ethers.utils.parseEther("1000"));
    await token.deployed();

    // Deploy NdMemeVoting contract
    const NdMemeVoting = await ethers.getContractFactory("NdMemeVoting");
    [owner, addr1, addr2] = await ethers.getSigners();
    ndMemeVoting = await NdMemeVoting.deploy();
    await ndMemeVoting.deployed();
  });


  it("should create a new topic", async function () {
    const description = "Best Meme of 2024";
    const endTime = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
    const options = ["Option1", "Option2"];

    await expect(ndMemeVoting.createTopic(description, endTime, options, token.address))
      .to.emit(ndMemeVoting, "TopicCreated")
      .withArgs(0, description, endTime);

    const topicCount = await ndMemeVoting.getTopicCount();
    expect(topicCount).to.equal(1);

    const topicDetails = await ndMemeVoting.getTopicDetails(0);
    expect(topicDetails.description).to.equal(description);
    expect(topicDetails.endTime).to.equal(endTime);
    expect(topicDetails.optionDescriptions).to.deep.equal(options);
  });

  it("should allow voting on a topic", async function () {
    const description = "Best Meme of 2024";
    const endTime = Math.floor(Date.now() / 1000) + 3600;
    const options = ["Option1", "Option2"];

    await ndMemeVoting.createTopic(description, endTime, options, token.address);

    // Addr1 votes for Option1
    await ndMemeVoting.connect(addr1).vote(0, "Option1");

    // Verify voter added to topic
    const topicDetails = await ndMemeVoting.getTopicDetails(0);
    expect(topicDetails.optionDescriptions).to.include("Option1");
    // Ensure finalizeVotes is required for weight-based counting
    const votes = await ndMemeVoting.getVotes(0, "Option1");
    expect(votes).to.equal(0); // Before finalization
  });

  it("should prevent double voting", async function () {
    const description = "Best Meme of 2024";
    const endTime = Math.floor(Date.now() / 1000) + 3600;
    const options = ["Option1", "Option2"];

    await ndMemeVoting.createTopic(description, endTime, options, token.address);

    await ndMemeVoting.connect(addr1).vote(0, "Option1");

    await expect(ndMemeVoting.connect(addr1).vote(0, "Option1")).to.be.revertedWith(
      "You have already voted on this topic"
    );
  });

  it("should prevent voting after end time", async function () {
    const description = "Best Meme of 2024";
    const endTime = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
    const options = ["Option1", "Option2"];

    // Create the topic
    await ndMemeVoting.createTopic(description, endTime, options, token.address);

    // Simulate time passing by setting the block timestamp to after the voting period
    const newTimestamp = endTime + 1; // 1 second after endTime
    await hre.network.provider.send("evm_setNextBlockTimestamp", [newTimestamp]);
    await hre.network.provider.send("evm_mine"); // Mine the next block to apply the new timestamp

    // Attempting to vote after end time should revert
    await expect(ndMemeVoting.connect(addr1).vote(0, "Option1")).to.be.revertedWith(
      "Voting has ended"
    );
  });
});
