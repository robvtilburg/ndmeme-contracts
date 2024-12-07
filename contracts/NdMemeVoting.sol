// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract NdMemeVoting {
    struct Topic {
        string description;
        uint256 endTime;
        mapping(address => bool) hasVoted;
        mapping(bytes32 => uint256) votes; // optionHash => voteWeight
        bytes32[] optionHashes;
        string[] optionStrings; // Store original string options
        IERC20 token; // Token used for weight calculation
        bool finalized;
    }

    mapping(uint256 => Topic) public topics;
    uint256 public topicCount;

    address public owner; // Contract owner address

    event TopicCreated(uint256 topicId, string description, uint256 endTime);
    event Voted(uint256 topicId, address voter, string option, uint256 weight);
    event VotesFinalized(uint256 topicId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyBeforeEnd(uint256 topicId) {
        require(block.timestamp <= topics[topicId].endTime, "Voting has ended");
        _;
    }

    modifier onlyAfterEnd(uint256 topicId) {
        require(block.timestamp > topics[topicId].endTime, "Voting is ongoing");
        _;
    }

    modifier topicExists(uint256 topicId) {
        require(topicId < topicCount, "Topic does not exist");
        _;
    }

    modifier onlyOncePerVote(uint256 topicId) {
        Topic storage topic = topics[topicId];
        require(!topic.hasVoted[msg.sender], "You have already voted");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Function to create a new topic
    function createTopic(
        string memory _description,
        uint256 _endTime,
        string[] memory _options,
        address _tokenAddress
    ) external {
        require(_endTime > block.timestamp, "End time must be in the future");
        require(_options.length > 0, "At least one option is required");

        Topic storage topic = topics[topicCount];
        topic.description = _description;
        topic.endTime = _endTime;
        topic.token = IERC20(_tokenAddress);

        for (uint256 i = 0; i < _options.length; i++) {
            bytes32 optionHash = keccak256(abi.encodePacked(_options[i]));
            topic.optionHashes.push(optionHash);
            topic.optionStrings.push(_options[i]);
        }

        emit TopicCreated(topicCount, _description, _endTime);
        topicCount++;
    }

    // Voting function
    function vote(uint256 topicId, string memory option)
        external
        topicExists(topicId)
        onlyBeforeEnd(topicId)
        onlyOncePerVote(topicId)
    {
        Topic storage topic = topics[topicId];
        bytes32 optionHash = keccak256(abi.encodePacked(option));
        bool validOption = false;

        // Check if the option is valid
        for (uint256 i = 0; i < topic.optionHashes.length; i++) {
            if (topic.optionHashes[i] == optionHash) {
                validOption = true;
                break;
            }
        }

        require(validOption, "Invalid voting option");

        // Record the vote and prevent further voting
        topic.hasVoted[msg.sender] = true;

        // Log the vote with a placeholder weight (can be updated after finalization)
        emit Voted(topicId, msg.sender, option, 0); // Placeholder weight for now
    }

    // Function to finalize votes after the voting period has ended
    function finalizeVotes(uint256 topicId)
        external
        onlyAfterEnd(topicId)
        topicExists(topicId)
        onlyOwner
    {
        Topic storage topic = topics[topicId];
        require(!topic.finalized, "Votes already finalized");

        // Finalize the votes by calculating the weight for each option
        for (uint256 i = 0; i < topic.optionHashes.length; i++) {
            bytes32 optionHash = topic.optionHashes[i];
            uint256 voteWeight = topic.token.balanceOf(msg.sender); // Voting weight based on token balance
            topic.votes[optionHash] += voteWeight;
        }

        // Mark topic as finalized
        topic.finalized = true;
        emit VotesFinalized(topicId);
    }

    // Function to retrieve the number of votes for a specific option
    function getVotes(uint256 topicId, string memory option) external view returns (uint256) {
        Topic storage topic = topics[topicId];
        bytes32 optionHash = keccak256(abi.encodePacked(option));
        return topic.votes[optionHash];
    }

    // Function to retrieve the topic details
    function getTopicDetails(uint256 topicId)
        external
        view
        topicExists(topicId)
        returns (
            string memory description,
            uint256 endTime,
            string[] memory optionDescriptions
        )
    {
        Topic storage topic = topics[topicId];
        description = topic.description;
        endTime = topic.endTime;
        optionDescriptions = topic.optionStrings;
    }

    // Function to retrieve the number of topics
    function getTopicCount() external view returns (uint256) {
        return topicCount;
    }
}