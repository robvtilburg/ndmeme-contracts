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
        bytes32[] options;
        IERC20 token; // Token used for weight calculation
    }

    mapping(uint256 => Topic) public topics;
    uint256 public topicCount;

    event TopicCreated(uint256 topicId, string description, uint256 endTime);

    event Voted(uint256 topicId, address voter, string option, uint256 weight);

    modifier onlyBeforeEnd(uint256 topicId) {
        require(block.timestamp <= topics[topicId].endTime, "Voting has ended");
        _;
    }

    modifier onlyAfterEnd(uint256 topicId) {
        require(block.timestamp > topics[topicId].endTime, "Voting is ongoing");
        _;
    }

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
            topic.options.push(optionHash);
        }
        emit TopicCreated(topicCount, _description, _endTime);
        topicCount++;
    }

   function vote(uint256 topicId, string memory option) external onlyBeforeEnd(topicId) {
        Topic storage topic = topics[topicId];
        require(!topic.hasVoted[msg.sender], "You have already voted");
        bytes32 optionHash = keccak256(abi.encodePacked(option));
        bool validOption = false;
        for (uint256 i = 0; i < topic.options.length; i++) {
            if (topic.options[i] == optionHash) {
                validOption = true;
                break;
            }
        }
        require(validOption, "Invalid voting option");
        topic.hasVoted[msg.sender] = true;
        emit Voted(topicId, msg.sender, option, 0); // Placeholder weight
    }
    
    function finalizeVotes(uint256 topicId) external onlyAfterEnd(topicId) {
        Topic storage topic = topics[topicId];
        for (uint256 i = 0; i < topic.options.length; i++) {
            bytes32 optionHash = topic.options[i];
            topic.votes[optionHash] += topic.token.balanceOf(msg.sender);
        }
    }
    
    function getVotes(uint256 topicId, string memory option) external view returns (uint256) {
        Topic storage topic = topics[topicId];
        bytes32 optionHash = keccak256(abi.encodePacked(option));
        return topic.votes[optionHash];
    }

    // New function to retrieve topic details and options
    function getTopicDetails(uint256 topicId) 
        external 
        view 
        returns (
            string memory description, 
            uint256 endTime, 
            string[] memory optionDescriptions
        ) 
    {
        Topic storage topic = topics[topicId];
        description = topic.description;
        endTime = topic.endTime;

        // Convert bytes32[] options to string[] for easier reading
        optionDescriptions = new string[](topic.options.length);
        for (uint256 i = 0; i < topic.options.length; i++) {
            optionDescriptions[i] = string(abi.decode(abi.encodePacked(topic.options[i]), (string)));
        }
    }
}