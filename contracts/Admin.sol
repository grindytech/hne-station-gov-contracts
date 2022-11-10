pragma solidity 0.8.14;
import "@openzeppelin/contracts/access/Ownable.sol";
contract Admin is Ownable{
    constructor(uint256 _initialProposal, uint256 _minDeposit, uint256 _durationDeposit, uint256 _durationVote, uint256 _quorum, uint256 _thresholdVeto, uint256 _thresholdPassed) {
        initialProposal = _initialProposal;
        minDeposit = _minDeposit;
        durationDeposit = _durationDeposit;
        durationVote = _durationVote;
        quorum = _quorum;
        thresholdVeto = _thresholdVeto;
        thresholdPassed = _thresholdPassed;
    }
    //VARIABLE
    uint256 public initialProposal; //1000 HE
    uint256 public minDeposit; // 10,000 HE
    uint256 public durationDeposit; // 2 weeks
    uint256 public durationVote; // 1 week
    uint256 public quorum; // 100/1000
    uint256 public thresholdVeto; // 334/1000
    uint256 public thresholdPassed; //500/1000

    mapping(address => bool) public admin;
    mapping(address => bool) public validator;
    event newValidator(
        address validator,
        uint256 blockTime,
        bool status
    );
    event newAdmin(
        address admin,
        uint256 blockTime,
        bool status
    );
    event newInitialProposal(
        address admin,
        uint256 amount,
        uint256 blockTime 
    );
    event newMinDeposit(
        address admin,
        uint256 amount,
        uint256 blockTime
    );
    event newDurationDeposit(
        address admin,
        uint256 duration,
        uint256 blockTime
    );
    event newDurationVote(
        address admin,
        uint256 duration,
        uint256 blockTime
    );
    event newQuorum(
        address admin,
        uint256 quorum,
        uint256 blockTime
    );
    event newThresholdVeto(
        address admin,
        uint256 threshold,
        uint256 blockTime
    );
    event newThresholdPassed(
        address admin,
        uint256 threshold,
        uint256 blockTime
    );
    function editInitialProposal(uint256 _initialProposal) external onlyAdmin() {
        initialProposal = _initialProposal;
        emit newInitialProposal(msg.sender, _initialProposal, block.timestamp);
    }
    function editMinDeposit(uint256 _minDeposit) external onlyAdmin(){
        minDeposit = _minDeposit;
        emit newMinDeposit(msg.sender, _minDeposit, block.timestamp);
    }
    function editDurationDeposit(uint256 _durationDeposit) external onlyAdmin() {
        durationDeposit = _durationDeposit;
        emit newDurationDeposit(msg.sender, _durationDeposit, block.timestamp);
    }
    function editDurationVote(uint256 _durationVote) external onlyAdmin(){
        durationVote = _durationVote;
        emit newDurationVote(msg.sender, _durationVote, block.timestamp);
    }
    function editQuorum(uint256 _quorum) external onlyAdmin() {
        quorum = _quorum;
        emit newQuorum(msg.sender, _quorum, block.timestamp);
    }
    function editThresholdVeto(uint256 _veto) external onlyAdmin(){
        thresholdVeto = _veto;
        emit newThresholdVeto(msg.sender, _veto, block.timestamp);
    }
    function editThresholdPassed(uint256 _passed) external onlyAdmin(){
        thresholdPassed = _passed;
        emit newThresholdPassed(msg.sender, _passed, block.timestamp);
    }
    function powerValidator(address[] memory _validator) external onlyOwner() {
        for(uint256 i =0 ;i < _validator.length; i++){
            validator[address(_validator[i])] =  !validator[address(_validator[i])];
            emit newValidator(address(_validator[i]), block.timestamp, validator[address(_validator[i])]);
        }
    }
    function powerAdmin(address[] memory _admin) external onlyOwner(){
        for(uint256 i =0 ;i < _admin.length; i++){
            admin[address(_admin[i])] =  !admin[address(_admin[i])];
            emit newAdmin(address(_admin[i]), block.timestamp, validator[address(_admin[i])]);
        }
    }

    modifier onlyAdmin() {
        require(admin[msg.sender], "Only Admin");
        _;
    } 
    modifier onlyValidator() {
        require(validator[msg.sender], "Only Validator");
        _;
    }  
   
}