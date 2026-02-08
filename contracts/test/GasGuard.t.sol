// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GasGuard.sol";

contract GasGuardTest is Test {
    GasGuard guard;
    address owner = makeAddr("owner");
    address reporter = makeAddr("reporter");
    address user = makeAddr("user");

    function setUp() public {
        vm.prank(owner);
        guard = new GasGuard();
    }

    // ─── Reporter Management ─────────────────────────────────────────

    function test_ownerIsReporter() public view {
        assertTrue(guard.reporters(owner));
    }

    function test_addReporter() public {
        vm.prank(owner);
        guard.addReporter(reporter);
        assertTrue(guard.reporters(reporter));
    }

    function test_removeReporter() public {
        vm.startPrank(owner);
        guard.addReporter(reporter);
        guard.removeReporter(reporter);
        vm.stopPrank();
        assertFalse(guard.reporters(reporter));
    }

    function test_onlyOwnerAddReporter() public {
        vm.prank(user);
        vm.expectRevert("not owner");
        guard.addReporter(reporter);
    }

    function test_onlyOwnerRemoveReporter() public {
        vm.prank(user);
        vm.expectRevert("not owner");
        guard.removeReporter(reporter);
    }

    // ─── Gas Reporting ───────────────────────────────────────────────

    function test_reportGas() public {
        vm.fee(20 gwei);
        vm.txGasPrice(25 gwei);
        vm.prank(owner);
        guard.reportGas();

        assertEq(guard.reportCount(), 1);
        assertEq(guard.latestBaseFee(), 20 gwei);
        assertEq(guard.latestGasPrice(), 25 gwei);
    }

    function test_reportGas_onlyReporter() public {
        vm.prank(user);
        vm.expectRevert("not reporter");
        guard.reportGas();
    }

    function test_reportGas_authorizedReporter() public {
        vm.prank(owner);
        guard.addReporter(reporter);

        vm.fee(10 gwei);
        vm.txGasPrice(15 gwei);
        vm.prank(reporter);
        guard.reportGas();

        assertEq(guard.reportCount(), 1);
    }

    function test_multipleReports() public {
        vm.startPrank(owner);
        
        vm.fee(10 gwei);
        vm.txGasPrice(12 gwei);
        guard.reportGas();

        vm.fee(20 gwei);
        vm.txGasPrice(25 gwei);
        guard.reportGas();

        vm.fee(30 gwei);
        vm.txGasPrice(35 gwei);
        guard.reportGas();

        vm.stopPrank();

        assertEq(guard.reportCount(), 3);
        assertEq(guard.latestBaseFee(), 30 gwei);
        assertEq(guard.getHistoryLength(), 3);
    }

    // ─── Gas Budgets ─────────────────────────────────────────────────

    function test_createBudget() public {
        bytes32 id = keccak256("my-budget");
        vm.prank(user);
        guard.createBudget(id, 50 gwei, 1 ether);

        (address bOwner, uint256 maxGP, uint256 maxTotal, uint256 spent, bool active) = guard.budgets(id);
        assertEq(bOwner, user);
        assertEq(maxGP, 50 gwei);
        assertEq(maxTotal, 1 ether);
        assertEq(spent, 0);
        assertTrue(active);
    }

    function test_createBudget_exists() public {
        bytes32 id = keccak256("b");
        vm.startPrank(user);
        guard.createBudget(id, 50 gwei, 1 ether);
        vm.expectRevert("budget exists");
        guard.createBudget(id, 50 gwei, 1 ether);
        vm.stopPrank();
    }

    function test_createBudget_zeroMaxGasPrice() public {
        vm.prank(user);
        vm.expectRevert("zero max gas price");
        guard.createBudget(keccak256("b"), 0, 1 ether);
    }

    function test_createBudget_zeroMaxTotal() public {
        vm.prank(user);
        vm.expectRevert("zero max total gas");
        guard.createBudget(keccak256("b"), 50 gwei, 0);
    }

    function test_recordSpending() public {
        bytes32 id = keccak256("b");
        vm.prank(user);
        guard.createBudget(id, 50 gwei, 1 ether);

        vm.txGasPrice(20 gwei);
        vm.prank(user);
        guard.recordSpending(id, 100_000);

        (,,,uint256 spent,) = guard.budgets(id);
        assertEq(spent, 100_000 * 20 gwei);
    }

    function test_recordSpending_notActive() public {
        bytes32 id = keccak256("b");
        vm.startPrank(user);
        guard.createBudget(id, 50 gwei, 1 ether);
        guard.closeBudget(id);
        vm.expectRevert("budget not active");
        guard.recordSpending(id, 100_000);
        vm.stopPrank();
    }

    function test_recordSpending_notOwner() public {
        bytes32 id = keccak256("b");
        vm.prank(user);
        guard.createBudget(id, 50 gwei, 1 ether);

        vm.prank(owner);
        vm.expectRevert("not budget owner");
        guard.recordSpending(id, 100_000);
    }

    function test_closeBudget() public {
        bytes32 id = keccak256("b");
        vm.startPrank(user);
        guard.createBudget(id, 50 gwei, 1 ether);
        guard.closeBudget(id);
        vm.stopPrank();

        (,,,,bool active) = guard.budgets(id);
        assertFalse(active);
    }

    function test_closeBudget_notOwner() public {
        bytes32 id = keccak256("b");
        vm.prank(user);
        guard.createBudget(id, 50 gwei, 1 ether);

        vm.prank(owner);
        vm.expectRevert("not budget owner");
        guard.closeBudget(id);
    }

    // ─── Contract Gas Profiling ──────────────────────────────────────

    function test_updateProfile() public {
        address target = makeAddr("target-contract");
        vm.prank(owner);
        guard.updateProfile(target, "Uniswap Router", 150_000);

        (string memory name, uint256 avg, uint256 count, uint256 total, uint256 updated) = guard.getProfile(target);
        assertEq(name, "Uniswap Router");
        assertEq(avg, 150_000);
        assertEq(count, 1);
        assertEq(total, 150_000);
        assertGt(updated, 0);
    }

    function test_updateProfile_rollingAverage() public {
        address target = makeAddr("target");
        vm.startPrank(owner);
        guard.updateProfile(target, "Router", 100_000);
        guard.updateProfile(target, "Router", 200_000);
        guard.updateProfile(target, "Router", 300_000);
        vm.stopPrank();

        (, uint256 avg, uint256 count, uint256 total,) = guard.getProfile(target);
        assertEq(count, 3);
        assertEq(total, 600_000);
        assertEq(avg, 200_000);
    }

    function test_updateProfile_onlyReporter() public {
        vm.prank(user);
        vm.expectRevert("not reporter");
        guard.updateProfile(makeAddr("x"), "test", 100);
    }

    // ─── View Functions ──────────────────────────────────────────────

    function test_isWithinBudget() public {
        bytes32 id = keccak256("b");
        vm.prank(user);
        guard.createBudget(id, 50 gwei, 1 ether);

        vm.txGasPrice(30 gwei);
        (bool withinPrice, bool withinTotal) = guard.isWithinBudget(id);
        assertTrue(withinPrice);
        assertTrue(withinTotal);
    }

    function test_isWithinBudget_overPrice() public {
        bytes32 id = keccak256("b");
        vm.prank(user);
        guard.createBudget(id, 50 gwei, 1 ether);

        vm.txGasPrice(100 gwei);
        (bool withinPrice,) = guard.isWithinBudget(id);
        assertFalse(withinPrice);
    }

    function test_getRecentReports() public {
        vm.startPrank(owner);
        for (uint i; i < 5; i++) {
            vm.fee((i + 1) * 10 gwei);
            vm.txGasPrice((i + 1) * 12 gwei);
            guard.reportGas();
        }
        vm.stopPrank();

        GasGuard.GasReport[] memory reports = guard.getRecentReports(3);
        assertEq(reports.length, 3);
        assertEq(reports[0].baseFee, 30 gwei); // 3rd report
        assertEq(reports[2].baseFee, 50 gwei); // 5th report
    }

    function test_getRecentReports_moreThanAvailable() public {
        vm.fee(10 gwei);
        vm.txGasPrice(12 gwei);
        vm.prank(owner);
        guard.reportGas();

        GasGuard.GasReport[] memory reports = guard.getRecentReports(100);
        assertEq(reports.length, 1);
    }

    function test_getAverageGasPrice() public {
        vm.startPrank(owner);
        
        vm.fee(10 gwei);
        vm.txGasPrice(15 gwei);
        guard.reportGas();

        vm.fee(20 gwei);
        vm.txGasPrice(25 gwei);
        guard.reportGas();

        vm.stopPrank();

        (uint256 avgBase, uint256 avgGas) = guard.getAverageGasPrice(2);
        assertEq(avgBase, 15 gwei);
        assertEq(avgGas, 20 gwei);
    }

    function test_getAverageGasPrice_noReports() public {
        vm.expectRevert("no reports");
        guard.getAverageGasPrice(1);
    }

    function test_getAverageGasPrice_moreThanAvailable() public {
        vm.fee(10 gwei);
        vm.txGasPrice(15 gwei);
        vm.prank(owner);
        guard.reportGas();

        (uint256 avgBase,) = guard.getAverageGasPrice(100);
        assertEq(avgBase, 10 gwei);
    }

    function test_estimateCost() public {
        vm.fee(20 gwei);
        vm.txGasPrice(25 gwei);
        vm.prank(owner);
        guard.reportGas();

        uint256 cost = guard.estimateCost(100_000);
        assertEq(cost, 100_000 * 25 gwei);
    }

    function test_getRemainingBudget() public {
        bytes32 id = keccak256("b");
        vm.prank(user);
        guard.createBudget(id, 50 gwei, 1 ether);

        uint256 remaining = guard.getRemainingBudget(id);
        assertEq(remaining, 1 ether);

        vm.txGasPrice(10 gwei);
        vm.prank(user);
        guard.recordSpending(id, 50_000_000); // 0.5 ETH at 10 gwei

        remaining = guard.getRemainingBudget(id);
        assertEq(remaining, 1 ether - (50_000_000 * 10 gwei));
    }

    function test_getRemainingBudget_exhausted() public {
        bytes32 id = keccak256("b");
        vm.prank(user);
        guard.createBudget(id, 50 gwei, 1000);

        vm.txGasPrice(10 gwei);
        vm.prank(user);
        guard.recordSpending(id, 1000); // way over budget

        uint256 remaining = guard.getRemainingBudget(id);
        assertEq(remaining, 0);
    }

    function test_getHistoryLength() public view {
        assertEq(guard.getHistoryLength(), 0);
    }
}
