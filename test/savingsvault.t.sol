// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {savingsVault} from "../src/savingsvault.sol";


contract savingsVaultTest is Test {
    savingsVault public savingsvault;

    function setUp() public  {
        savingsvault = new savingsVault();

    }


    function testdepositEthNoGoalSet() public {
        savingsvault.setGoal (1 ether);
        savingsvault.depositEth{value:  1 ether}();
        assertGt(savingsvault.savingGoals(address(this)), 0.5 ether);
    }

}