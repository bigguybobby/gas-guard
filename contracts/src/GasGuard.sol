// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title GasGuard — On-Chain Gas Price Oracle & Transaction Cost Registry
/// @notice Public good: any dApp can query gas costs, set gas budgets, and get refund estimates
/// @dev Designed as open-source infrastructure for EVM chains
contract GasGuard {
    // ─── Types ───────────────────────────────────────────────────────────

    struct GasReport {
        uint256 timestamp;
        uint256 baseFee;          // base fee in wei
        uint256 gasPrice;         // tx.gasprice in wei
        uint256 blockNumber;
        address reporter;
    }

    struct GasBudget {
        address owner;
        uint256 maxGasPrice;      // max gas price willing to pay (wei)
        uint256 maxTotalGas;      // max total gas budget (wei)
        uint256 spent;            // total gas spent so far
        bool active;
    }

    struct ContractGasProfile {
        string name;
        address contractAddr;
        uint256 avgGasUsed;       // rolling average gas per call
        uint256 callCount;
        uint256 totalGasUsed;
        uint256 lastUpdated;
    }

    // ─── State ───────────────────────────────────────────────────────────

    GasReport[] public gasHistory;
    mapping(bytes32 => GasBudget) public budgets;          // budgetId => budget
    mapping(address => ContractGasProfile) public profiles; // contract => gas profile
    mapping(address => bool) public reporters;              // authorized reporters
    
    address public owner;
    uint256 public reportCount;
    uint256 public latestBaseFee;
    uint256 public latestGasPrice;

    // ─── Events ──────────────────────────────────────────────────────────

    event GasReported(uint256 indexed index, uint256 baseFee, uint256 gasPrice, uint256 blockNumber);
    event BudgetCreated(bytes32 indexed budgetId, address indexed owner, uint256 maxGasPrice, uint256 maxTotalGas);
    event BudgetSpent(bytes32 indexed budgetId, uint256 amount, uint256 totalSpent);
    event BudgetClosed(bytes32 indexed budgetId);
    event ProfileUpdated(address indexed contractAddr, uint256 gasUsed, uint256 avgGas);
    event ReporterAdded(address indexed reporter);
    event ReporterRemoved(address indexed reporter);

    // ─── Modifiers ───────────────────────────────────────────────────────

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier onlyReporter() {
        require(reporters[msg.sender] || msg.sender == owner, "not reporter");
        _;
    }

    // ─── Constructor ─────────────────────────────────────────────────────

    constructor() {
        owner = msg.sender;
        reporters[msg.sender] = true;
    }

    // ─── Reporter Management ─────────────────────────────────────────────

    function addReporter(address reporter) external onlyOwner {
        reporters[reporter] = true;
        emit ReporterAdded(reporter);
    }

    function removeReporter(address reporter) external onlyOwner {
        reporters[reporter] = false;
        emit ReporterRemoved(reporter);
    }

    // ─── Gas Reporting ───────────────────────────────────────────────────

    /// @notice Report current gas conditions (callable by authorized reporters or bots)
    function reportGas() external onlyReporter {
        uint256 baseFee = block.basefee;
        uint256 gasPrice_ = tx.gasprice;

        gasHistory.push(GasReport({
            timestamp: block.timestamp,
            baseFee: baseFee,
            gasPrice: gasPrice_,
            blockNumber: block.number,
            reporter: msg.sender
        }));

        latestBaseFee = baseFee;
        latestGasPrice = gasPrice_;
        reportCount++;

        emit GasReported(reportCount - 1, baseFee, gasPrice_, block.number);
    }

    // ─── Gas Budgets ─────────────────────────────────────────────────────

    /// @notice Create a gas budget to track spending
    function createBudget(
        bytes32 budgetId,
        uint256 maxGasPrice,
        uint256 maxTotalGas
    ) external {
        require(budgets[budgetId].owner == address(0), "budget exists");
        require(maxGasPrice > 0, "zero max gas price");
        require(maxTotalGas > 0, "zero max total gas");

        budgets[budgetId] = GasBudget({
            owner: msg.sender,
            maxGasPrice: maxGasPrice,
            maxTotalGas: maxTotalGas,
            spent: 0,
            active: true
        });

        emit BudgetCreated(budgetId, msg.sender, maxGasPrice, maxTotalGas);
    }

    /// @notice Record gas spending against a budget
    function recordSpending(bytes32 budgetId, uint256 gasUsed) external {
        GasBudget storage b = budgets[budgetId];
        require(b.active, "budget not active");
        require(b.owner == msg.sender, "not budget owner");

        uint256 cost = gasUsed * tx.gasprice;
        b.spent += cost;

        emit BudgetSpent(budgetId, cost, b.spent);
    }

    /// @notice Close a budget
    function closeBudget(bytes32 budgetId) external {
        require(budgets[budgetId].owner == msg.sender, "not budget owner");
        budgets[budgetId].active = false;
        emit BudgetClosed(budgetId);
    }

    // ─── Contract Gas Profiling ──────────────────────────────────────────

    /// @notice Update gas profile for a contract (called by monitoring bots)
    function updateProfile(
        address contractAddr,
        string calldata name,
        uint256 gasUsed
    ) external onlyReporter {
        ContractGasProfile storage p = profiles[contractAddr];
        
        if (p.callCount == 0) {
            p.name = name;
            p.contractAddr = contractAddr;
        }

        p.totalGasUsed += gasUsed;
        p.callCount++;
        p.avgGasUsed = p.totalGasUsed / p.callCount;
        p.lastUpdated = block.timestamp;

        emit ProfileUpdated(contractAddr, gasUsed, p.avgGasUsed);
    }

    // ─── View Functions ──────────────────────────────────────────────────

    /// @notice Check if current gas price is within budget
    function isWithinBudget(bytes32 budgetId) external view returns (bool withinPrice, bool withinTotal) {
        GasBudget storage b = budgets[budgetId];
        withinPrice = tx.gasprice <= b.maxGasPrice;
        withinTotal = b.spent < b.maxTotalGas;
    }

    /// @notice Get the latest N gas reports
    function getRecentReports(uint256 count) external view returns (GasReport[] memory) {
        uint256 len = gasHistory.length;
        if (count > len) count = len;
        
        GasReport[] memory reports = new GasReport[](count);
        for (uint256 i; i < count; i++) {
            reports[i] = gasHistory[len - count + i];
        }
        return reports;
    }

    /// @notice Calculate average gas price over last N reports
    function getAverageGasPrice(uint256 count) external view returns (uint256 avgBaseFee, uint256 avgGasPrice) {
        uint256 len = gasHistory.length;
        require(len > 0, "no reports");
        if (count > len) count = len;

        uint256 totalBase;
        uint256 totalGas;
        for (uint256 i; i < count; i++) {
            GasReport storage r = gasHistory[len - count + i];
            totalBase += r.baseFee;
            totalGas += r.gasPrice;
        }
        avgBaseFee = totalBase / count;
        avgGasPrice = totalGas / count;
    }

    /// @notice Estimate cost in wei for a given gas amount at current rates
    function estimateCost(uint256 gasAmount) external view returns (uint256) {
        return gasAmount * latestGasPrice;
    }

    /// @notice Get remaining budget
    function getRemainingBudget(bytes32 budgetId) external view returns (uint256) {
        GasBudget storage b = budgets[budgetId];
        if (b.spent >= b.maxTotalGas) return 0;
        return b.maxTotalGas - b.spent;
    }

    /// @notice Get gas profile for a contract
    function getProfile(address contractAddr) external view returns (
        string memory name,
        uint256 avgGasUsed,
        uint256 callCount,
        uint256 totalGasUsed,
        uint256 lastUpdated
    ) {
        ContractGasProfile storage p = profiles[contractAddr];
        return (p.name, p.avgGasUsed, p.callCount, p.totalGasUsed, p.lastUpdated);
    }

    /// @notice Get total number of gas reports
    function getHistoryLength() external view returns (uint256) {
        return gasHistory.length;
    }
}
