// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract savingsVault {
    address public owner;

    event deposit(address indexed owner, uint256 amount, uint256 balances);

    event goals(address indexed owner, uint256 amount);
    event withdrawalMade(address indexed owner, uint256 amount, uint256 balances);

    mapping(address => uint256) public balances;

    mapping(address => uint256) public savingGoals;

    uint256 constant PENALTY_FEE = 500;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        owner == msg.sender;
        _;
    }

    function depositEth() public payable {
        require(savingGoals[msg.sender] >= 1 ether, "you have not set your savings goal"); // made sure a user set a Goal before they can make a deposit
        require(msg.value >= 1 ether, "value has to be positive");
        balances[msg.sender] += msg.value;
        emit deposit(msg.sender, msg.value, balances[msg.sender]);
    }

    function setGoal(uint256 amount) public {
        require(amount >= 1 ether, "your set goal must be atleast 1 Eth");
        savingGoals[msg.sender] = amount;

        emit goals(msg.sender, amount);
    }

    function checkBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function withdraw(uint256 _amount) public onlyOwner {
        if (balances[msg.sender] >= savingGoals[msg.sender] && balances[msg.sender] > _amount) {
            balances[msg.sender] -= _amount;
        } else if (balances[msg.sender] < savingGoals[msg.sender] && balances[msg.sender] > _amount) {
            balances[msg.sender] -= (_amount * PENALTY_FEE) / 10000;
        } else {
            revert("you dont qualify");
        }

        emit withdrawalMade(msg.sender, _amount, balances[msg.sender]);
    }
}
