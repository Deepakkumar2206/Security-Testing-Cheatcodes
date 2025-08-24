## Day 13 – Security Testing Cheatcodes (ETH Vault)

### A compact demo that builds a secure ETH Vault with owner-controlled pause/unpause, reentrancy protection, and a full Foundry test suite (including an attacker contract). This project demonstrates how to combine Solidity best practices with security testing using Foundry cheatcodes and external analyzers like Slither and Mythril.

### Key Takeaways
- Implemented an ETH Vault with:
    - Deposit, withdraw, and withdrawAll functions
    - Owner-only pause/unpause (emergency stop)
    - NonReentrant guard for safe ETH transfers

- Tested using Foundry cheatcodes:
    - vm.prank to spoof callers
    - vm.expectRevert for negative cases
    - Reentrancy attack simulation with a malicious contract

- Ran security analysis with Slither and Mythril to catch common bugs.
- Demonstrated professional workflow for real-world smart contract development.


### Prerequisites

```shell
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup


# recommended for security analysis:
# Install Slither & Mythril via pipx
sudo apt install pipx -y
pipx install slither-analyzer
pipx install mythril
```

### Contracts & Tests

#### Vault.sol
- deposit() – deposit ETH, updates balance mapping.
- withdraw(uint) – withdraw specified ETH amount, CEI pattern + nonReentrant.
- withdrawAll() – withdraw entire balance.
- pause() / unpause() – owner-only emergency controls.
- Uses events for Deposit/Withdraw/Paused.

#### Vault.t.sol
- test_DepositAndWithdraw() – checks balances and ETH flow.
- testOnlyOwnerCanPause() – enforces owner-only control.
- test_PausedBlocksOperations() – ensures paused vault rejects deposits/withdrawals.
- test_ReentrancyBlocked() – simulates attack via malicious contract; ensures vault funds remain safe.

### Commands to Run

```shell
# Format Solidity files
forge fmt

# Build contracts
forge build

# Run tests (with verbose traces)
forge test -vvv

# Gas usage report
forge test --gas-report

# Snapshot gas costs (for future diffs)
forge snapshot

# Slither static analysis
slither .

# Mythril symbolic execution (with timeout)
myth analyze src/Vault.sol --solv 0.8.26 --execution-timeout 60
```

### Sample Outputs

```shell
# Build
[⠊] Compiling...
[⠒] Compiling 23 files with Solc 0.8.26
[⠆] Solc 0.8.26 finished in 550ms
Compiler run successful!

# Tests
Ran 4 tests for test/Vault.t.sol:VaultTest
[PASS] test_DepositAndWithdraw()    (gas: ~61k)
[PASS] testOnlyOwnerCanPause()      (gas: ~24k)
[PASS] test_PausedBlocksOperations()(gas: ~66k)
[PASS] test_ReentrancyBlocked()     (gas: ~250k)
Suite result: ok. 4 passed; 0 failed

# Slither
Vault.constructor lacks zero-address check (low severity)
Vault.owner could be immutable (gas optimization)
Low-level calls flagged (expected; safe with require(ok))


$ myth analyze src/Vault.sol --solv 0.8.26 --execution-timeout 60
The analysis was completed successfully. No issues were detected.
```
### Slither Findings
#### Running slither . produced some informational findings:
- Missing zero-address check in constructor
    - Impact: If deployed with 0x0 as the owner, the Vault could not be paused/unpaused.
    - Fix: Add require(_owner != address(0), "owner cannot be zero"); in the constructor.

- Low-level calls used for ETH transfer
     - Impact: address.call{value: ...} is flagged because it’s a low-level call.
     - Why safe here: The call return value is checked with require(ok, "ETH transfer failed");.
     - Note: This is the recommended pattern over transfer/send since they break with gas stipends.

- Owner variable could be immutable
     - Impact: Minor gas optimization only.
    - Fix: Change address public owner; → address public immutable owner;.

None of these are critical, but they’re useful refinements for production-ready code.

## End of Project


