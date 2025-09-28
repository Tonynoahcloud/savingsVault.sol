// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {savingsVault} from "../src/savingsvault.sol";


contract SavingsVaultTest is Test {
    savingsVault public vault;

    // --- Events must be redeclared here for the compiler to recognize them in 'emit' statements ---
    event deposit(
        address indexed owner,
        uint256 amount,
        uint256 balances
    );

    event goals(
        address indexed owner,
        uint256 amount
    );
    event withdrawalMade(
        address indexed owner,
        uint256 amount,
        uint256 balances
    );
    // ---------------------------------------------------------------------------------------------

    // Define fixed addresses for testing roles
    address internal constant OWNER = address(0xAA);
    address internal constant DEPOSITOR = address(0xBB);
    address internal constant RANDOM_USER = address(0xCC);
    
    // Define the contract's constant for reference
    uint256 internal constant PENALTY_FEE = 500; // Represents 5% (500/10000)

    function setUp() public {
        // 1. Deploy the contract using a known 'OWNER' address
        vm.startPrank(OWNER);
        vault = new savingsVault();
        vm.stopPrank();

        // 2. Fund the users with Ether using the 'deal' cheatcode
        vm.deal(DEPOSITOR, 10 ether);
        vm.deal(RANDOM_USER, 5 ether);
    }

    // --- Deployment and Owner Tests ---

    function testOwnerIsSetCorrectly() public view {
        assertEq(vault.owner(), OWNER, "Owner should be the address that deployed the contract.");
    }

    // --- DepositEth Tests ---

    function testDepositEth_Success() public {
        uint256 depositAmount = 2 ether;

        // Prank the depositor and execute the deposit function with value
        vm.startPrank(DEPOSITOR);
        
        // Expect the 'deposit' event to be emitted
        vm.expectEmit(true, true, false, true); 
        emit deposit(DEPOSITOR, depositAmount, depositAmount); // FIX: Removed 'vault.'
        
        // The function accepts a dummy uint256 parameter but uses msg.value
        vault.depositEth{value: depositAmount}(1); 
        
        vm.stopPrank();

        // 1. Verify contract balance increased
        assertEq(address(vault).balance, depositAmount, "Contract balance should equal the deposited amount.");

        // 2. Verify internal balance mapping updated
        vm.prank(DEPOSITOR);
        assertEq(vault.checkBalance(), depositAmount, "User's internal balance should be updated.");
    }

    function testDepositEth_RevertsIfValueIsZero() public {
        vm.prank(DEPOSITOR);
        // Expect a revert with the custom error message
        vm.expectRevert("value has to be positive");
        // Calling without 'value' sends 0 Ether
        vault.depositEth(1); 
    }

    // --- setGoal Tests ---

    function testSetGoal_Success() public {
        uint256 goalEthAmount = 5; // Corresponds to 5 ether after multiplication
        // uint256 expectedGoalWei = 5 ether; // This variable is unused

        vm.startPrank(DEPOSITOR);
        
        // Expect the 'goals' event to be emitted
        vm.expectEmit(true, false, false, true); 
        emit goals(DEPOSITOR, goalEthAmount); // FIX: Removed 'vault.'
        vault.setGoal(goalEthAmount);

        // Note: We cannot directly read the private 'savingGoals' mapping, 
        // so we confirm the goal setting via the emitted event and later via withdrawal logic.
        vm.stopPrank();
    }

    function testSetGoal_RevertsIfAmountIsZero() public {
        vm.prank(DEPOSITOR);
        vm.expectRevert("your set goal must be atleast 1 Eth");
        vault.setGoal(0);
    }
    
    // --- Withdrawal Tests: Goal MET (No Penalty) ---

    function testWithdraw_SuccessGoalMet() public {
        uint256 depositAmount = 5 ether;
        uint256 withdrawalAmount = 2 ether;
        
        // 1. Setup: Deposit Ether
        vm.prank(DEPOSITOR);
        vault.depositEth{value: depositAmount}(1);

        // 2. Setup: Set Goal LESS than deposit to avoid penalty path
        vm.prank(DEPOSITOR);
        vault.setGoal(1); // Goal set to 1 ether. Balance (5e18) > Goal (1e18)

        // Record initial state before withdrawal
        uint256 initialContractBalance = address(vault).balance;
        uint256 initialUserBalance = DEPOSITOR.balance;
        
        // 3. Withdraw
        vm.startPrank(DEPOSITOR);
        
        // Expect the 'withdrawalMade' event to be emitted (0 penalty)
        uint256 expectedRemainingBalance = depositAmount - withdrawalAmount;
        vm.expectEmit(true, false, false, true); 
        emit withdrawalMade(DEPOSITOR, withdrawalAmount, expectedRemainingBalance); // FIX: Removed 'vault.'
        
        vault.withdraw(2); // Withdraw 2 ether
        vm.stopPrank();

        // 4. Verify External Balances (User received withdrawalAmount, no penalty)
        assertEq(address(vault).balance, initialContractBalance - withdrawalAmount, "Contract balance should decrease by withdrawal amount.");
        // Use assertApproxEqAbs for EOA balance checks to account for gas costs
        assertApproxEqAbs(DEPOSITOR.balance, initialUserBalance + withdrawalAmount, 1e15, "User's external balance should increase by withdrawal amount (minus gas).");

        // 5. Verify Internal Balances
        assertEq(vault.checkBalance(), expectedRemainingBalance, "Internal balance should reflect withdrawal amount only.");
    }
    
    function testWithdraw_RevertsInsufficientFundsGoalMet() public {
        uint256 depositAmount = 5 ether;
        
        vm.prank(DEPOSITOR);
        vault.depositEth{value: depositAmount}(1);
        vault.setGoal(1); // Goal met

        // Try to withdraw more than deposited
        vm.prank(DEPOSITOR);
        vm.expectRevert("you do not have enough funds, try a lower value");
        vault.withdraw(6); // Withdraw 6 ether
    }
    
    // --- Withdrawal Tests: Goal NOT Met (With Penalty) ---

    function testWithdraw_SuccessGoalNotMet_WithPenalty() public {
        uint256 depositAmount = 3 ether;
        uint256 goalEthAmount = 5; // 5 ether
        uint256 withdrawalEthAmount = 1; // 1 ether
        
        // The contract's logic multiplies by 1 ether:
        uint256 withdrawalAmountWei = withdrawalEthAmount * 1 ether; // 1e18
        
        // 1. Setup: Deposit Ether
        vm.prank(DEPOSITOR);
        vault.depositEth{value: depositAmount}(1); // Balance is 3e18

        // 2. Setup: Set Goal (Goal is NOT met: 3e18 < 5e18)
        vm.prank(DEPOSITOR);
        vault.setGoal(goalEthAmount); 

        // Calculation: 5% penalty
        uint256 expectedPenalty = (withdrawalAmountWei * PENALTY_FEE) / 10000; // 0.05 ether
        uint256 totalDeduction = withdrawalAmountWei + expectedPenalty; // 1.05 ether

        // Record initial state before withdrawal
        uint256 initialContractBalance = address(vault).balance;
        uint256 initialUserBalance = DEPOSITOR.balance;
        
        // 3. Withdraw
        vm.startPrank(DEPOSITOR);
        
        // Expect the 'withdrawalMade' event to be emitted
        uint256 expectedRemainingBalance = depositAmount - totalDeduction; // 3e18 - 1.05e18 = 1.95e18
        vm.expectEmit(true, false, false, true); 
        emit withdrawalMade(DEPOSITOR, withdrawalAmountWei, expectedRemainingBalance); // FIX: Removed 'vault.'

        vault.withdraw(withdrawalEthAmount); // Withdraw 1 ether
        vm.stopPrank();

        // 4. Verify External Balances (User received withdrawalAmount, penalty stays in the vault)
        assertEq(address(vault).balance, initialContractBalance - withdrawalAmountWei, "Contract balance should decrease only by the withdrawal amount.");
        assertApproxEqAbs(DEPOSITOR.balance, initialUserBalance + withdrawalAmountWei, 1e15, "User's external balance should increase by withdrawal amount (minus gas).");

        // 5. Verify Internal Balances
        assertEq(vault.checkBalance(), expectedRemainingBalance, "Internal balance should reflect withdrawal PLUS penalty.");
    }
    
    function testWithdraw_RevertsInsufficientFundsForPenalty() public {
        uint256 depositAmount = 0.1 ether;
        
        // 1. Setup: Deposit small amount
        vm.prank(DEPOSITOR);
        vault.depositEth{value: depositAmount}(1); // Balance is 0.1e18

        // 2. Setup: Set Goal (Goal is NOT met: 0.1e18 < 5e18)
        vm.prank(DEPOSITOR);
        vault.setGoal(5); 

        // Try to withdraw 0.1 ether. Requires 0.1e18 (withdrawal) + 0.005e18 (penalty) = 0.105e18
        // User balance (0.1e18) is less than the required deduction (0.105e18).
        
        vm.prank(DEPOSITOR);
        vm.expectRevert("you do not have enough funds to cover withdrawal and penalty charges");
        vault.withdraw(0.1 ether); 
    }
}