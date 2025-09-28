// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {savingsVault} from "../src/savingsvault.sol";


contract savingsVaultTest is Test {
    uint256 savingsGoals;

    function setUp() public view {
        savingsGoals >= 1;

    }

    function test_depositEth() public view {
        assertEq(savingsGoals, 0);
    }
}