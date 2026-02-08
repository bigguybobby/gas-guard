"use client";
import { ConnectKitButton } from "connectkit";
import Link from "next/link";

export default function Home() {
  return (
    <main className="min-h-screen bg-gradient-to-b from-gray-950 via-emerald-950/20 to-gray-950">
      <nav className="flex items-center justify-between px-6 py-4 border-b border-white/10">
        <h1 className="text-xl font-bold">⛽ GasGuard</h1>
        <ConnectKitButton />
      </nav>

      <div className="mx-auto max-w-4xl px-6 py-20 text-center">
        <div className="text-6xl mb-6">⛽</div>
        <h2 className="text-4xl font-bold mb-4 bg-gradient-to-r from-emerald-400 to-cyan-400 bg-clip-text text-transparent">
          GasGuard
        </h2>
        <p className="text-xl text-gray-400 mb-8">
          On-Chain Gas Price Oracle & Transaction Cost Registry
        </p>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
          {[
            { icon: "📊", title: "Gas Reporting", desc: "Real-time base fee & gas price tracking" },
            { icon: "💰", title: "Gas Budgets", desc: "Set spending caps and track gas costs" },
            { icon: "🔍", title: "Contract Profiling", desc: "Rolling average gas per contract call" },
          ].map((f) => (
            <div key={f.title} className="rounded-xl bg-white/5 border border-white/10 p-6">
              <div className="text-3xl mb-3">{f.icon}</div>
              <h3 className="font-semibold text-lg mb-2">{f.title}</h3>
              <p className="text-gray-400 text-sm">{f.desc}</p>
            </div>
          ))}
        </div>
        <Link
          href="/dashboard"
          className="inline-block rounded-lg bg-emerald-600 px-8 py-3 font-semibold transition hover:bg-emerald-500"
        >
          Open Dashboard →
        </Link>
      </div>

      <div className="mx-auto max-w-4xl px-6 pb-12 grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
        {[
          { label: "Tests", value: "32/32" },
          { label: "Coverage", value: "100%" },
          { label: "Slither", value: "Clean" },
          { label: "License", value: "MIT" },
        ].map((s) => (
          <div key={s.label} className="rounded-lg bg-white/5 border border-white/10 p-4">
            <div className="text-2xl font-bold text-emerald-400">{s.value}</div>
            <div className="text-xs text-gray-500 mt-1">{s.label}</div>
          </div>
        ))}
      </div>
    </main>
  );
}
