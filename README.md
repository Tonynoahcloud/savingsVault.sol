# SavingsVault Smart Contract Documentation

## Overview

The `savingsVault` contract is an Ethereum-based savings vault that enables users to set savings goals, deposit ETH, and withdraw funds.  
The contract enforces financial discipline by requiring users to set a savings goal before making deposits, and by applying a penalty if funds are withdrawn before the goal is reached.

---

## Key Features

- Users must **set a savings goal** before depositing funds.
- Minimum deposit and goal requirement: **1 ETH**.
- Users can **deposit ETH** to increase their savings balance.
- Users can **check their balance** anytime.
- Withdrawals:
  - **If the savings goal is reached:** full withdrawal is allowed.
  - **If the savings goal is not reached:** withdrawal incurs a **5% penalty**.
- **Events** are emitted on deposits, goal setting, and withdrawals.

---

## Contract Details

### State Variables

- `address public owner;`  
  The address of the contract deployer.

- `mapping(address => uint256) public balances;`  
  Tracks ETH balances of users.

- `mapping(address => uint256) public savingGoals;`  
  Tracks user-defined savings goals.

- `uint256 constant PENALTY_FEE = 500;`  
  Represents a **5% penalty fee** (500 basis points).

---

### Events

- `event deposit(address indexed owner, uint256 amount, uint256 balances);`  
  Emitted when a deposit is made.

- `event goals(address indexed owner, uint256 amount);`  
  Emitted when a user sets a savings goal.

- `event withdrawalMade(address indexed owner, uint256 amount, uint256 balances);`  
  Emitted when a withdrawal occurs.

---

### Functions

#### `constructor()`  
Initializes the contract.  
  
`owner = msg.sender;`

---

#### `function depositEth() public payable`  
- Requires the user to set a savings goal (≥ 1 ETH).  
- Requires a minimum deposit of **1 ETH**.  
- Updates the user’s balance.  
- Emits a `deposit` event.

---

#### `function setGoal(uint256 amount) public`  
- Requires the goal to be **≥ 1 ETH**.  
- Stores the user’s savings goal.  
- Emits a `goals` event.

---

#### `function checkBalance() public view returns (uint256)`  
- Returns the balance of the caller.

---

#### `function withdraw(uint256 _amount) public`  
Handles user withdrawals with or without penalty:  

1. **If goal is reached and balance is sufficient:**  
   - Full withdrawal is allowed (`payout = _amount`).  
   - Balance is reduced by `_amount`.  

2. **If goal is not reached but balance is sufficient:**  
   - A **5% penalty** is applied.  
   - `payout = _amount - ((_amount * PENALTY_FEE) / 10000)`.  
   - Balance reduced by `_amount`.  

3. **Otherwise:**  
   - Transaction reverts with `"you dont have enough funds to perform this transaction"`.  

Funds are transferred using **`.transfer`** (safe with limited gas forwarding).  
Emits a `withdrawalMade` event.

---

## Example Workflow

1. **User sets a goal:** `setGoal(5 ether)`  
2. **User deposits:** `depositEth()` with `msg.value = 2 ether`  
3. **User checks balance:** `checkBalance()` → `2 ether`  
4. **User withdraws before reaching goal:** receives 95% of withdrawal request (5% penalty applied).  
5. **User withdraws after reaching goal:** receives 100% of withdrawal request.

---


## License

This project is licensed under the **MIT License**.
