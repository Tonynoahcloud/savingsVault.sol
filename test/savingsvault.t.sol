// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {savingsVault} from "../src/savingsvault.sol";

contract savingsVaultTest is Test {
    savingsVault public savingsvault;

    function setUp() public {
        savingsvault = new savingsVault();
    }

    receive() external payable {}
    fallback() external payable {}

    function testdepositEth_GoalSet() public {
        savingsvault.setGoal(1 ether);
        savingsvault.depositEth{value: 1 ether}();
        assertGt(savingsvault.savingGoals(address(this)), 0.5 ether);
        assertGt(savingsvault.checkBalance(), 0.5 ether);
    }

    function testwithdrawFull() public {
        savingsvault.setGoal(10 ether);
        savingsvault.depositEth{value: 10 ether}();
        savingsvault.withdraw(3 ether); // Withdraw 3 ether
        assertEq(savingsvault.balances(address(this)), 7 ether);
    }
}
