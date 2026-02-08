# ⛽ GasGuard — On-Chain Gas Price Oracle & Cost Registry

> Public good infrastructure for EVM chains — gas reporting, budgeting, and contract profiling

## What is GasGuard?

GasGuard is an on-chain gas price oracle and transaction cost management system. Any dApp can query gas conditions, set gas budgets, track spending, and profile contract gas usage — all on-chain.

## Features

- **Gas Reporting** — Authorized reporters submit gas conditions (base fee, gas price, block number)
- **Gas History** — Query recent gas reports, calculate averages over any window
- **Gas Budgets** — Create budgets with max gas price and total spending caps
- **Budget Tracking** — Record spending against budgets, check if within limits
- **Contract Profiling** — Track gas usage per contract with rolling averages
- **Cost Estimation** — Estimate transaction costs at current gas rates

## Quick Start

```solidity
// Check current gas conditions
uint256 cost = gasGuard.estimateCost(100_000); // cost for 100k gas

// Create a gas budget
gasGuard.createBudget(keccak256("my-app"), 50 gwei, 1 ether);

// Check if within budget
(bool priceOk, bool totalOk) = gasGuard.isWithinBudget(budgetId);

// Get average gas price over last 10 reports
(uint256 avgBase, uint256 avgGas) = gasGuard.getAverageGasPrice(10);
```

## Deployment

| Network | Address |
|---------|---------|
| Celo Sepolia | `0x09C79695c58b9de0fdFb7c074274aB6bc9781765` |

## Stats

- ✅ **32/32 tests passing**
- ✅ **100% line, statement, branch, and function coverage**
- ✅ Slither clean
- 📄 MIT License

## Tech Stack

- **Contract:** Solidity 0.8.20, Foundry
- **Testing:** Forge test with full coverage

## License

MIT
