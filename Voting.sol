// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Voting {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    struct Voter {
        bool isRegistered;
        bool isVoted;
    }

    struct Candidate {
        uint256 votesCount;
        string candidateName;
    }

    struct Election {
        mapping(address => Voter) voters;
        Candidate[] candidates;
        bool isOpen;
    }

    event Vote(uint256 indexed electionId, uint256 indexed candidateIndex, string msg);
    event NewElection(string msg);

    mapping(uint256 => Election) public elections;

    modifier isVoterRegisteredAndNotVoted(uint256 electionId) {
        require(elections[electionId].isOpen, "Election is not open");
        require(
            elections[electionId].voters[msg.sender].isRegistered,
            "You are not registered, Please register first"
        );
        require(
            !elections[electionId].voters[msg.sender].isVoted,
            "You are already voted"
        );
        _;
    }

    modifier isAdmin() {
        require(msg.sender == owner, "You don't have permission to perform this operation");
        _;
    }

    function register(uint256 electionId) public {
        require(!elections[electionId].voters[msg.sender].isRegistered, "You are already registered");
        Voter memory newVoter = Voter(true, false);

        elections[electionId].voters[msg.sender] = newVoter;
    }

    function vote(
        uint256 electionId,
        uint256 candidateIndex
    ) public isVoterRegisteredAndNotVoted(electionId) {
        elections[electionId].candidates[candidateIndex].votesCount++;
        elections[electionId].voters[msg.sender].isVoted = true;

        emit Vote(electionId, candidateIndex, "You vote has been recorded");
    }

    function declareElectionResult(uint256 electionId) public view isAdmin returns (Candidate[] memory) {
        Election storage election = elections[electionId];
        return election.candidates;
    }

    function createElection(string[] memory candidatesName) public isAdmin {    
        uint256 candidatesLength = candidatesName.length;
        Candidate[] memory candidates = new Candidate[](candidatesLength);

        for (uint i = 0; i < candidatesLength; i++) {
            Candidate memory newCandidate = Candidate(0, candidatesName[i]);
            candidates[i] = newCandidate;
        }
    
        uint256 electionId = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        Election storage newElection = elections[electionId];
        newElection.isOpen = true;
        newElection.candidates = candidates;


        emit NewElection("New election candidates are listed");
    }

}
