// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/Vault.sol";

contract VaultTest is Test {
    Vault vault;
    address owner = makeAddr("owner");
    address alice = makeAddr("alice");
    address bob   = makeAddr("bob");

    function setUp() public {
        vm.deal(owner, 100 ether);
        vm.deal(alice, 100 ether);
        vm.deal(bob,   100 ether);
        vault = new Vault(owner);
    }

    
    function test_DepositAndWithdraw() public {
        uint256 preAlice = alice.balance;

        vm.prank(alice);
        vault.deposit{value: 2 ether}();
        assertEq(vault.balanceOf(alice), 2 ether);
        assertEq(address(vault).balance, 2 ether);
        assertEq(alice.balance, preAlice - 2 ether);

        vm.prank(alice);
        vault.withdraw(1.5 ether);
        assertEq(vault.balanceOf(alice), 0.5 ether);
        assertEq(address(vault).balance, 0.5 ether);
        assertEq(alice.balance, preAlice - 0.5 ether);
    }

    
    function testOnlyOwnerCanPause() public {
        vm.prank(alice);
        vm.expectRevert(Vault.NotOwner.selector);
        vault.pause();

        vm.prank(owner);
        vault.pause();
        assertTrue(vault.paused());

        vm.prank(owner);
        vault.unpause();
        assertFalse(vault.paused());
    }

    // paused state blocks deposits/withdraws 
    function test_PausedBlocksOperations() public {
        vm.prank(owner);
        vault.pause();

        vm.prank(alice);
        vm.expectRevert(Vault.Paused.selector);
        vault.deposit{value: 1 ether}();

        vm.prank(owner);
        vault.unpause();

        vm.prank(alice);
        vault.deposit{value: 1 ether}();

        vm.prank(owner);
        vault.pause();

        vm.prank(alice);
        vm.expectRevert(Vault.Paused.selector);
        vault.withdraw(0.5 ether);
    }

    //  reentrancy attempt should fail to drain 
    function test_ReentrancyBlocked() public {
        ReenterAttack attacker = new ReenterAttack(vault);
        vm.deal(address(attacker), 10 ether);

        vm.prank(alice);
        vault.deposit{value: 5 ether}();

        uint256 attackerBefore = address(attacker).balance;

        vm.prank(bob); // bob supplies 1 ETH to attack()
        attacker.attack{value: 1 ether}();

        // Attacker did NOT profit from the vault beyond what it sent in
        assertEq(address(attacker).balance, attackerBefore + 1 ether);
        assertEq(vault.balanceOf(address(attacker)), 0);
        assertEq(address(vault).balance, 5 ether);
    }
}


contract ReenterAttack {
    Vault public vault;
    uint256 private _amt;

    constructor(Vault _vault) { vault = _vault; }

    function attack() external payable {
        _amt = msg.value;
        vault.deposit{value: msg.value}();
        vault.withdraw(msg.value); // reenter attempt will be blocked by nonReentrant
    }

    receive() external payable {
        if (address(vault).balance >= _amt) {
            try vault.withdraw(_amt) {} catch {}
        }
    }
}
