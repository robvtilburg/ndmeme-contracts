require('dotenv').config();
const { ethers } = require('ethers');

// Contract ABI
const contractABI = [
  "function createTopic(string memory _description, uint256 _endTime, string[] memory _options, address _tokenAddress) external",
  "event TopicCreated(uint256 topicId, string description, uint256 endTime)"
];

// Update with your deployed contract address
const contractAddress = "0x1896e024F4df09bC6B260558aDB70b6487803219";

console.log(process.env.INFURA_API_URL)

// Define your provider and wallet
const provider = new ethers.providers.JsonRpcProvider(process.env.INFURA_API_URL);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);


async function createVotingTopic() {
  try {
    
    // Connect to the contract
    const contract = new ethers.Contract(contractAddress, contractABI, wallet);
  // Fetch gas fee data
  const feeData = await contract.provider.getFeeData();

    // Define topic parameters
    const description = "What is the best memecoin ever?";
    const endTime = Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60; // 7 days from now
    const options = ["NDMEME!", "NDMEME", "$NDMEME"];
    const tokenAddress = "0x1ce16390fd09040486221e912b87551e4e44ab17"; // using wrapped gas for testing purposes.

    const estimatedGas = await contract.estimateGas.createTopic(description, endTime, options, tokenAddress);
console.log("Estimated Gas:", estimatedGas.toString());

    // Send transaction to create the topic
    const tx = await contract.createTopic(description, endTime, options, tokenAddress, {
        gasLimit: 5000000, // Adjust the gas limit as needed
        maxPriorityFeePerGas: ethers.utils.parseUnits("20", "gwei"), // Minimum miner tip
        maxFeePerGas: ethers.utils.parseUnits("150", "gwei"), // Maximum gas fee
      });
    console.log("Transaction sent. Waiting for confirmation...");
    const receipt = await tx.wait();

    // Extract event from receipt
    const event = receipt.events.find(e => e.event === "TopicCreated");
    const { topicId, description: eventDescription, endTime: eventEndTime } = event.args;

    console.log(`Topic created successfully!`);
    console.log(`Topic ID: ${topicId}`);
    console.log(`Description: ${eventDescription}`);
    console.log(`End Time: ${new Date(eventEndTime * 1000).toLocaleString()}`);
  } catch (error) {
    console.error("Error creating topic:", error);
  }
}

createVotingTopic();
