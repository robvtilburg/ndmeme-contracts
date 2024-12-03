require("dotenv").config();
const { ethers } = require("ethers");

// ABI should include getTopicDetails function
const contractABI = [
  "function topicCount() view returns (uint256)",
  "function getTopicDetails(uint256 topicId) view returns (string, uint256, string[])",
];
const contractAddress = "0x2aBFb8a9551562dD6b9e41568F6898BBe79D1F54";

async function getTopics() {
  const provider = new ethers.providers.JsonRpcProvider(process.env.INFURA_API_URL);
  const contract = new ethers.Contract(contractAddress, contractABI, provider);

  try {
    const topicCount = await contract.topicCount();
    console.log(`Total Topics: ${topicCount.toString()}`);

    for (let i = 0; i < topicCount; i++) {
      const [description, endTime, options] = await contract.getTopicDetails(i);

      console.log(`\nTopic ${i}:`);
      console.log(`  Description: ${description}`);
      console.log(`  End Time: ${new Date(endTime * 1000).toLocaleString()}`);
      console.log(`  Options:`);
      options.forEach((option, index) => {
        console.log(`    ${index + 1}: ${option}`);
      });
    }
  } catch (error) {
    console.error("Error fetching topics:", error);
  }
}

getTopics();
