pragma solidity 0.8.14;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Admin.sol";
contract Stake {
    struct UserInfo {  
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingDebt;
    }
     struct PoolInfo {
        IERC20 heToken;           // Address of HE token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. HE to distribute per block.
        uint256 lastRewardBlock;  // Last block number that HE distribution occurs.
        uint256 accHePerShare; // Accumulated HE per share, times 1e18. See below.
        uint256 balancePool;
    }
    PoolInfo[] public poolInfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

}
contract GovernanceV2 is Admin{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    IERC20 public governanceToken;
    Stake public stake;
    address public burn;
    constructor(address _governanceToken, address _stake, address _burn) Admin(10000000000000000000000,50000000000000000000000,1209600,604800,100,334,500) public{
        governanceToken = IERC20(_governanceToken);
        stake = Stake(_stake);
        burn = _burn;
    }
    function editStakeAddress(address _stake) external onlyAdmin(){
        stake = Stake(_stake);
    }
    struct Proposal {
        address proposer;
        string title;
        string description;
        uint256 deposit;
        uint256 status; 
        uint256 votesPassed;
        uint256 votesFail;
        uint256 votesVeto;
        uint256 totalStake;
        uint256 start;
        uint256 endDeposit;
        uint256 endVote;
        uint256 blockTime;
    }
    mapping(address => mapping(uint256 => uint256)) public mapDeposits;
    mapping(address => mapping(uint256 => uint256)) public mapVotes;
    uint256 proposalNumber = 0;
    bool boolCreate;
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public statusVotes;
    mapping(address => mapping(uint256 => bool)) public withdrawID;
    mapping(uint256 => Proposal) public proposal;
    event newProposal(
        uint256 proposalID,
        address proposer,
        string title,
        string description,
        uint256 amount,
        uint256 blockTime
    );
    event newDeposit(
        address owner,
        uint256 proposalID,
        uint256 amount,
        uint256 blockTime
    );
    event newWithdraw(
        uint256 proposalID,
        address owner,
        uint256 amount,
        uint256 blockTime
    );
    event ActiveProposal(
        uint256 proposalID,
        uint256 status
    );
    event newVote(
        uint256 proposalID,
        address owner,
        uint256 amount,
        uint256 status,
        uint256 blockTime
    );
    event EmergencyWithdraw(
        uint256 amount,
        uint256 blockTime
    );
    function UpdateProposalNumber(uint256 _proposalNumber) external onlyOwner() {
        proposalNumber = _proposalNumber;
    }
    function CloseCreateProposal() external onlyOwner(){
        boolCreate = !boolCreate;
    }
    function createProposal(string memory _title, string memory _description) external{
        require(!boolCreate, "Feature not available");
        proposalNumber += 1; 
        proposal[proposalNumber] = Proposal({
                                    proposer: msg.sender,
                                    title: _title,
                                    description: _description,
                                    deposit: initialProposal,
                                    status: 1,
                                    votesPassed: 0,
                                    votesFail: 0,
                                    votesVeto: 0,
                                    totalStake: 0,
                                    start: 0,
                                    endDeposit: 0,
                                    endVote: 0,
                                    blockTime: block.timestamp
                                });
        mapDeposits[msg.sender][proposalNumber] += initialProposal;
        governanceToken.safeTransferFrom(
            msg.sender,
            address(this),
            initialProposal
        );
        emit newDeposit(msg.sender, proposalNumber, initialProposal, block.timestamp);
        emit newProposal(proposalNumber,msg.sender,_title,_description,initialProposal, block.timestamp);
    }
    function executeProposal(uint256 _proposalID) external onlyValidator() returns (uint256){
        Proposal storage proposalexecute = proposal[_proposalID];
        require(proposalexecute.status == 3 || proposalexecute.status == 5, "Cant execute proposal");
        uint256 status = proposalexecute.status;
        if(status == 3){
            require(proposalexecute.endDeposit < block.timestamp || proposalexecute.deposit >= minDeposit, "Cant active vote");
            uint256 amountDeposit = proposalexecute.deposit;
            if(amountDeposit < minDeposit){
                safeGovernanceTransfer(burn, amountDeposit);
                proposalexecute.status = 4;
            }
            if(amountDeposit >= minDeposit){
                proposalexecute.status = 5;
                proposalexecute.endDeposit = block.timestamp;
                proposalexecute.endVote = durationVote.add(block.timestamp);
            }
        }
        if(status == 5){
           require(proposalexecute.endVote < block.timestamp, "Cant active status");
           // Quorum, veto, pass
           (,,,,uint256 balancePool) = stake.poolInfo(0);
           uint256 totalVotes = proposalexecute.votesFail + proposalexecute.votesPassed + proposalexecute.votesVeto;
           uint256 quorumID = totalVotes.mul(1000).div(balancePool);
           uint256 vetoID = (totalVotes == 0) ? 100 : proposalexecute.votesVeto.mul(1000).div(totalVotes);
           if(quorumID >= quorum && vetoID < thresholdVeto){
               uint256 passedID = proposalexecute.votesPassed.mul(1000).div(totalVotes);
               if(passedID >= thresholdPassed){
                   proposalexecute.status = 6;
               }else{
                   proposalexecute.status = 7;
               }
           }else{
                proposalexecute.status = 8;
                safeGovernanceTransfer(burn, proposalexecute.deposit);
           }
           proposalexecute.totalStake = balancePool;
            /// vote to status : passed , fail, veto
        }
        emit ActiveProposal(_proposalID, proposalexecute.status);
        return proposalexecute.status;
    }
    
    function activeDeposit(uint256 _proposalID, uint256 _status) external onlyAdmin(){
        Proposal storage proposalActive = proposal[_proposalID];
        require(proposalActive.status == 1, "can't update");
        require(_status == 2 || _status == 3 || _status == 9);
        proposalActive.status = _status;
        if(_status == 2){
            safeGovernanceTransfer(proposalActive.proposer, proposalActive.deposit);     
        }
        if(_status == 9){
            safeGovernanceTransfer(burn, proposalActive.deposit);  
        }
        if(_status == 3){
            proposalActive.start = block.timestamp;
            proposalActive.endDeposit = durationDeposit.add(block.timestamp);
            // proposalActive.endVote = durationVote.add(block.timestamp).add(durationDeposit);
        }
        emit ActiveProposal(_proposalID, _status); 
    }

    function deposit(uint256 _proposalID, uint256 _amount) external {
        Proposal storage proposalDeposit = proposal[_proposalID];
        require(proposalDeposit.status == 3, "Cant deposit");
        require(proposalDeposit.start < block.timestamp && proposalDeposit.endDeposit > block.timestamp, "The deadline has passed for this Proposal");
        proposalDeposit.deposit += _amount;
        mapDeposits[msg.sender][_proposalID] += _amount;
        governanceToken.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        emit newDeposit(
            msg.sender,
            _proposalID,
            _amount,
            block.timestamp
        );
    }
    function vote(uint256 _proposalID, uint256 _amount, uint256 _vote) external {
        Proposal storage proposalVote = proposal[_proposalID];
        require(proposalVote.status == 5, "Cant Vote");
        require(proposalVote.start < block.timestamp && proposalVote.endVote > block.timestamp, "The deadline has passed for this Proposal");
        require(_vote == 6 || _vote == 7 || _vote == 8, "Vote not found");
        (uint256 amount, ,) = stake.userInfo(0,msg.sender);
        require(amount >= mapVotes[msg.sender][_proposalID].add(_amount), "You have to stake more to be able to vote");
        mapVotes[msg.sender][_proposalID] += _amount;
        statusVotes[msg.sender][_proposalID][_vote] += _amount;
        if(_vote == 6){
            proposalVote.votesPassed += _amount;
        }
        if(_vote == 7){
            proposalVote.votesFail += _amount;
        }
        if(_vote == 8){
            proposalVote.votesVeto += _amount;
        }
        emit newVote(
            _proposalID,
            msg.sender,
            _amount,
            _vote,
            block.timestamp
        );
    }
    function withdrawal(uint256 _proposalID) external {
        Proposal storage proposalWithdraw = proposal[_proposalID];
        require(proposalWithdraw.status == 6 || proposalWithdraw.status == 7, "Cant withdraw for this Proposal");
        require(!withdrawID[msg.sender][_proposalID], "You have withdrawn for this Proposal");
        uint256 amount = mapDeposits[msg.sender][_proposalID];
        require(amount > 0,"Not found deposit for this Proposal");
        withdrawID[msg.sender][_proposalID] = true;
        safeGovernanceTransfer(msg.sender, amount);
        emit newWithdraw(_proposalID, msg.sender, amount, block.timestamp);
    }
    function safeGovernanceTransfer(address member, uint256 amount) internal {
        uint256 GovernanceBalance = governanceToken.balanceOf(address(this));
        if (amount > GovernanceBalance) {
            governanceToken.safeTransfer(member, GovernanceBalance);
        } else {
            governanceToken.safeTransfer(member, amount);
        }
    }
    
    function emergencyWithdraw(uint256 _amount) external onlyOwner(){
        safeGovernanceTransfer(address(msg.sender), _amount);
        emit EmergencyWithdraw(
            _amount,
            block.timestamp
        );
    }
}