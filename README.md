
# SavingsVault Smart Contract Documentation

## Overview

The `savingsVault` contract allows users to deposit Ether, set savings goals, and withdraw funds. If a user withdraws before reaching their savings goal, a penalty fee is applied.

---

## Features

- **Deposit Ether:** Users can deposit ETH into their vault balance.
- **Set Savings Goal:** Users can set a target savings goal (denominated in ETH).
- **Withdraw Funds:** Users can withdraw ETH. If their balance is below their savings goal, a penalty is applied.
- **Check Balance:** Users can check their current vault balance.

---

## Contract Details

### State Variables

- `address public owner`: The contract deployer (administrator).
- `mapping(address => uint256) private balances`: Tracks each user's deposited balance.
- `mapping(address => uint256) private savingGoals`: Tracks each user's saving goal in wei.
- `uint256 constant PENALTY_FEE = 500`: Penalty fee in basis points (500 = 5%).

### Events

- `deposit(address indexed owner, uint256 amount, uint256 balances)`  
  Emitted when a user deposits ETH.

- `goals(address indexed owner, uint256 amount)`  
  Emitted when a user sets a new savings goal.

- `withdrawalMade(address indexed owner, uint256 amount, uint256 balances)`  
  Emitted when a user withdraws ETH.

---

## Functions

### `constructor()`
Sets the deployer as the contract owner.

### `function depositEth(uint256) public payable`
Deposits Ether into the contract.  
- **Requirements:** `msg.value > 0`.  
- **Effects:** Updates user balance and emits `deposit` event.

### `function setGoal(uint256 amount) public`
Sets the savings goal for the caller.  
- **Requirements:** `amount > 0`.  
- **Effects:** Stores goal in wei (`amount * 1 ether`) and emits `goals` event.

### `function checkBalance() public view returns(uint256)`
Returns the caller's current balance.

### `function withdraw(uint256 _amount) public`
Withdraws ETH from the contract.  
- **Inputs:** `_amount` (denominated in ETH).  
- **Logic:**  
  - Converts `_amount` to wei.  
  - If balance < goal → penalty fee applied (5%).  
  - Ensures sufficient balance.  
  - Updates balance, transfers ETH, and emits `withdrawalMade` event.  

---

## Penalty Fee Calculation

- Penalty = `(amount * PENALTY_FEE) / 10000`  
- Example: Withdrawing 1 ETH before meeting goal → penalty = `0.05 ETH`.  

---

## Example Workflow

1. **Deposit ETH**  
   ```solidity
   vault.depositEth{value: 2 ether}(2);
   ```

2. **Set Goal**  
   ```solidity
   vault.setGoal(5); // 5 ETH goal
   ```

3. **Withdraw**  
   ```solidity
   vault.withdraw(1); // withdraw 1 ETH (penalty applies if balance < goal)
   ```

4. **Check Balance**  
   ```solidity
   vault.checkBalance();
   ```

---

## Security Notes

- Uses `require` for input validation and balance checks.  
- Transfers ETH with `call`, preventing reentrancy issues.  
- Balances and goals are private to enforce controlled access.  

---

## License
MIT
