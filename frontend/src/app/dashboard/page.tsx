"use client";
import { ConnectKitButton } from "connectkit";
import { useReadContract, useWriteContract, useAccount } from "wagmi";
import { GASGUARD_ADDRESS, GASGUARD_ABI } from "@/config/contract";
import { useState } from "react";
import { keccak256, toBytes, formatGwei, parseGwei } from "viem";

function Card({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="rounded-xl bg-white/5 border border-white/10 p-6">
      <h3 className="text-lg font-semibold mb-4 text-emerald-400">{title}</h3>
      {children}
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="text-center">
      <div className="text-2xl font-bold">{value}</div>
      <div className="text-xs text-gray-500 mt-1">{label}</div>
    </div>
  );
}

export default function Dashboard() {
  const { isConnected } = useAccount();
  const { writeContract } = useWriteContract();
  const [tab, setTab] = useState<"overview" | "budget" | "profile" | "report">("overview");
  const [budgetName, setBudgetName] = useState("");
  const [maxGasPrice, setMaxGasPrice] = useState("");
  const [maxTotal, setMaxTotal] = useState("");
  const [profileAddr, setProfileAddr] = useState("");

  const { data: reportCount } = useReadContract({
    address: GASGUARD_ADDRESS, abi: GASGUARD_ABI, functionName: "reportCount",
  });
  const { data: latestBase } = useReadContract({
    address: GASGUARD_ADDRESS, abi: GASGUARD_ABI, functionName: "latestBaseFee",
  });
  const { data: latestGas } = useReadContract({
    address: GASGUARD_ADDRESS, abi: GASGUARD_ABI, functionName: "latestGasPrice",
  });
  const { data: historyLen } = useReadContract({
    address: GASGUARD_ADDRESS, abi: GASGUARD_ABI, functionName: "getHistoryLength",
  });
  const { data: profile } = useReadContract({
    address: GASGUARD_ADDRESS, abi: GASGUARD_ABI, functionName: "getProfile",
    args: profileAddr ? [profileAddr as `0x${string}`] : undefined,
    query: { enabled: !!profileAddr && profileAddr.startsWith("0x") && profileAddr.length === 42 },
  });

  const tabs = [
    { id: "overview" as const, label: "📊 Overview" },
    { id: "report" as const, label: "📡 Report Gas" },
    { id: "budget" as const, label: "💰 Budgets" },
    { id: "profile" as const, label: "🔍 Profiles" },
  ];

  return (
    <main className="min-h-screen bg-gray-950">
      <nav className="flex items-center justify-between px-6 py-4 border-b border-white/10">
        <h1 className="text-xl font-bold">⛽ GasGuard Dashboard</h1>
        <ConnectKitButton />
      </nav>

      <div className="mx-auto max-w-5xl px-6 py-8">
        <div className="flex gap-2 mb-8 flex-wrap">
          {tabs.map((t) => (
            <button
              key={t.id}
              onClick={() => setTab(t.id)}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition ${
                tab === t.id ? "bg-emerald-600 text-white" : "bg-white/5 text-gray-400 hover:bg-white/10"
              }`}
            >
              {t.label}
            </button>
          ))}
        </div>

        {tab === "overview" && (
          <div className="space-y-6">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <Card title="Reports">
                <Stat label="Total Reports" value={reportCount?.toString() ?? "0"} />
              </Card>
              <Card title="Latest Base Fee">
                <Stat label="Gwei" value={latestBase ? formatGwei(latestBase) : "—"} />
              </Card>
              <Card title="Latest Gas Price">
                <Stat label="Gwei" value={latestGas ? formatGwei(latestGas) : "—"} />
              </Card>
              <Card title="History Length">
                <Stat label="Entries" value={historyLen?.toString() ?? "0"} />
              </Card>
            </div>
            <Card title="Contract Info">
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-400">Contract</span>
                  <code className="text-emerald-400 text-xs">{GASGUARD_ADDRESS}</code>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-400">Network</span>
                  <span>Celo Sepolia</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-400">Tests</span>
                  <span className="text-green-400">32/32 ✅</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-400">Coverage</span>
                  <span className="text-green-400">100%</span>
                </div>
              </div>
            </Card>
          </div>
        )}

        {tab === "report" && (
          <Card title="Report Current Gas Conditions">
            <p className="text-gray-400 text-sm mb-4">
              Submit the current block&apos;s base fee and gas price on-chain. Only authorized reporters can call this.
            </p>
            <button
              disabled={!isConnected}
              onClick={() => writeContract({
                address: GASGUARD_ADDRESS, abi: GASGUARD_ABI, functionName: "reportGas",
              })}
              className="w-full py-3 rounded-lg bg-emerald-600 font-semibold transition hover:bg-emerald-500 disabled:opacity-50"
            >
              {isConnected ? "📡 Report Gas Now" : "Connect Wallet First"}
            </button>
          </Card>
        )}

        {tab === "budget" && (
          <Card title="Create Gas Budget">
            <div className="space-y-4">
              <div>
                <label className="text-sm text-gray-400">Budget Name</label>
                <input
                  value={budgetName}
                  onChange={(e) => setBudgetName(e.target.value)}
                  placeholder="my-app-budget"
                  className="w-full mt-1 rounded-lg bg-white/5 border border-white/10 px-4 py-2 text-sm"
                />
              </div>
              <div>
                <label className="text-sm text-gray-400">Max Gas Price (Gwei)</label>
                <input
                  value={maxGasPrice}
                  onChange={(e) => setMaxGasPrice(e.target.value)}
                  placeholder="50"
                  type="number"
                  className="w-full mt-1 rounded-lg bg-white/5 border border-white/10 px-4 py-2 text-sm"
                />
              </div>
              <div>
                <label className="text-sm text-gray-400">Max Total Budget (ETH/CELO)</label>
                <input
                  value={maxTotal}
                  onChange={(e) => setMaxTotal(e.target.value)}
                  placeholder="1.0"
                  type="number"
                  className="w-full mt-1 rounded-lg bg-white/5 border border-white/10 px-4 py-2 text-sm"
                />
              </div>
              <button
                disabled={!isConnected || !budgetName || !maxGasPrice || !maxTotal}
                onClick={() => writeContract({
                  address: GASGUARD_ADDRESS, abi: GASGUARD_ABI, functionName: "createBudget",
                  args: [
                    keccak256(toBytes(budgetName)),
                    parseGwei(maxGasPrice),
                    BigInt(Math.floor(parseFloat(maxTotal) * 1e18)),
                  ],
                })}
                className="w-full py-3 rounded-lg bg-emerald-600 font-semibold transition hover:bg-emerald-500 disabled:opacity-50"
              >
                💰 Create Budget
              </button>
            </div>
          </Card>
        )}

        {tab === "profile" && (
          <Card title="Lookup Contract Gas Profile">
            <div className="space-y-4">
              <div>
                <label className="text-sm text-gray-400">Contract Address</label>
                <input
                  value={profileAddr}
                  onChange={(e) => setProfileAddr(e.target.value)}
                  placeholder="0x..."
                  className="w-full mt-1 rounded-lg bg-white/5 border border-white/10 px-4 py-2 text-sm font-mono"
                />
              </div>
              {profile && (
                <div className="rounded-lg bg-white/5 p-4 space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-400">Name</span>
                    <span>{(profile as [string, bigint, bigint, bigint, bigint])[0] || "—"}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">Avg Gas Used</span>
                    <span>{(profile as [string, bigint, bigint, bigint, bigint])[1]?.toString()}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">Call Count</span>
                    <span>{(profile as [string, bigint, bigint, bigint, bigint])[2]?.toString()}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">Total Gas Used</span>
                    <span>{(profile as [string, bigint, bigint, bigint, bigint])[3]?.toString()}</span>
                  </div>
                </div>
              )}
            </div>
          </Card>
        )}
      </div>
    </main>
  );
}
