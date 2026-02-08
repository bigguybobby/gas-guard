export const GASGUARD_ADDRESS = "0x09C79695c58b9de0fdFb7c074274aB6bc9781765" as const;

export const GASGUARD_ABI = [
  { type: "function", name: "reportCount", inputs: [], outputs: [{ type: "uint256" }], stateMutability: "view" },
  { type: "function", name: "latestBaseFee", inputs: [], outputs: [{ type: "uint256" }], stateMutability: "view" },
  { type: "function", name: "latestGasPrice", inputs: [], outputs: [{ type: "uint256" }], stateMutability: "view" },
  { type: "function", name: "getHistoryLength", inputs: [], outputs: [{ type: "uint256" }], stateMutability: "view" },
  { type: "function", name: "estimateCost", inputs: [{ name: "gasAmount", type: "uint256" }], outputs: [{ type: "uint256" }], stateMutability: "view" },
  { type: "function", name: "getAverageGasPrice", inputs: [{ name: "count", type: "uint256" }], outputs: [{ name: "avgBaseFee", type: "uint256" }, { name: "avgGasPrice", type: "uint256" }], stateMutability: "view" },
  { type: "function", name: "getRemainingBudget", inputs: [{ name: "budgetId", type: "bytes32" }], outputs: [{ type: "uint256" }], stateMutability: "view" },
  { type: "function", name: "isWithinBudget", inputs: [{ name: "budgetId", type: "bytes32" }], outputs: [{ name: "withinPrice", type: "bool" }, { name: "withinTotal", type: "bool" }], stateMutability: "view" },
  { type: "function", name: "getProfile", inputs: [{ name: "contractAddr", type: "address" }], outputs: [{ name: "name", type: "string" }, { name: "avgGasUsed", type: "uint256" }, { name: "callCount", type: "uint256" }, { name: "totalGasUsed", type: "uint256" }, { name: "lastUpdated", type: "uint256" }], stateMutability: "view" },
  { type: "function", name: "reportGas", inputs: [], outputs: [], stateMutability: "nonpayable" },
  { type: "function", name: "createBudget", inputs: [{ name: "budgetId", type: "bytes32" }, { name: "maxGasPrice", type: "uint256" }, { name: "maxTotalGas", type: "uint256" }], outputs: [], stateMutability: "nonpayable" },
  { type: "function", name: "closeBudget", inputs: [{ name: "budgetId", type: "bytes32" }], outputs: [], stateMutability: "nonpayable" },
  { type: "function", name: "recordSpending", inputs: [{ name: "budgetId", type: "bytes32" }, { name: "gasUsed", type: "uint256" }], outputs: [], stateMutability: "nonpayable" },
  { type: "function", name: "updateProfile", inputs: [{ name: "contractAddr", type: "address" }, { name: "name", type: "string" }, { name: "gasUsed", type: "uint256" }], outputs: [], stateMutability: "nonpayable" },
  { type: "function", name: "addReporter", inputs: [{ name: "reporter", type: "address" }], outputs: [], stateMutability: "nonpayable" },
  { type: "function", name: "owner", inputs: [], outputs: [{ type: "address" }], stateMutability: "view" },
] as const;
