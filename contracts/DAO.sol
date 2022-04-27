// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DAONeofacto {
 using SafeMath for uint;

    struct Proposal {
        uint id;
        string name;
        uint amount;
        address payable recipient;
        uint votes;
        uint end;
        bool executed;
    }

    mapping(address => bool) public investors ;
    mapping(address => uint) public shares;
    mapping(address => mapping(uint => bool)) public votes;
    mapping(uint => Proposal ) public proposals;

    uint public totalSahres;
    uint public availableFunds;
    uint public contributionEnd;
    uint public nextProposalId;
    uint public voteTime;
    uint public quorum;
    address public admin;


    constructor(uint contributionTime,uint _voteTime,uint _quorum){
        require(_quorum>0 && quorum<100,'quorum must be between 0 and 100');
        contributionEnd = contributionTime + block.timestamp;
        voteTime= _voteTime;
        quorum=_quorum;
    }

    function contribute() payable external {
        require(block.timestamp<contributionEnd , 'cannot contribute after contribution end');
        investors[msg.sender] = true;
        shares[msg.sender]= shares[msg.sender].add(msg.value);
        totalSahres=   totalSahres.add(msg.value);
        availableFunds= availableFunds.add(msg.value);
    }

    function redeemShare( uint amount) external {
        require(shares[msg.sender]>=amount,'not enough shares');
        require(availableFunds >=amount , 'not enough available shares');
        shares[msg.sender] = shares[msg.sender].sub(amount);
        availableFunds= availableFunds.sub(amount);
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }



    function transferSare(uint amount, address to )external{
        require(shares[msg.sender]>=amount,'not enough shares');
         shares[msg.sender] = shares[msg.sender].sub(amount);
         shares[to] = shares[to].add(amount);
         investors[to]=true;
    }

    function createProposal( string memory name,
        uint amount,
        address payable recipient)
        public
        onlyInvestors
    {
        require(availableFunds>=amount, 'amount too big');
        proposals[nextProposalId]=Proposal(
            nextProposalId,
            name,
            amount,
            recipient,
            0,
            block.timestamp+voteTime,
            false
        );
       availableFunds =  availableFunds.sub(amount);
       nextProposalId++;
       
    }

    function vote(uint proposalId) external  onlyInvestors {
        Proposal storage proposal = proposals[proposalId];
        require(votes[msg.sender][proposalId] == false , 'investor can only vote once per proposal');
        require(block.timestamp< proposal.end , 'only vote before proposal end');
        votes[msg.sender][proposalId] = true;
        proposal.votes = proposal.votes.add(shares[msg.sender]);

    }

    function executeProposal(uint proposalId) external onlyAdmin{
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp>= proposal.end , 'proposal not yet ended');
        require((proposal.votes.div(totalSahres)).mul(100)>=quorum , 'votes should be bigger then quorum');
        require(proposal.executed == false , 'proposal execution only once');
        SendEther(proposal.amount,proposal.recipient);
        

    }

    function withdrawEther(uint amount, address to) external onlyAdmin{
          (bool sent, ) = payable(to).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function SendEther(uint amount , address to)internal{
        require(amount<=availableFunds,'not enough availableFunds');
        availableFunds= availableFunds.sub(amount);
         (bool sent, ) = payable(to).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() payable external {
        availableFunds=availableFunds.add(msg.value);
    }

     modifier onlyInvestors(){
         require(investors[msg.sender] == true, 'only investor');
         _;
     }

    modifier onlyAdmin(){
        require(msg.sender== admin,'only admin');
        _;
    }

}