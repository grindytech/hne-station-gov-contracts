# Heroes and Empires Governance

## What is H&E Governance?
The Solidity smartcontract for DApps governance
* Create proposal
* Executing proposal
* Voting for proposal
* Withdraw proposal

## Build

```shell
npm i

npx hardhat run --network testnet scripts/deploy_governance.js
```

## Methods

```js
function createProposal(string memory title, string memory description) public;

function executeProposal(uint256 proposalID) external onlyValidator() public returns (uint256);

function activeDeposit(uint256 proposalID, uint256 status) public onlyAdmin();

function deposit(uint256 proposalID, uint256 amount) public;

function vote(uint256 proposalID, uint256 amount, uint256 vote) public;

function withdrawal(uint256 _proposalID) public;

function emergencyWithdraw(uint256 _amount) public onlyOwner();

```

## Events

```js
event newDeposit(sender, proposalNumber, initialProposal, timestamp);

event newProposal(proposalNumber, sender, title, description, initialProposal, timestamp);

event ActiveProposal(proposalID, status);

event newDeposit(sender, proposalID, amount, timestamp);

event newVote(proposalID, sender, amount, vote, timestamp);

event newWithdraw(proposalID, sender, amount, timestamp);

event EmergencyWithdraw( amount, timestamp);

```




