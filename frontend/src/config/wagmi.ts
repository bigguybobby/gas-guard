import { getDefaultConfig } from "connectkit";
import { createConfig, http } from "wagmi";
import { defineChain } from "viem";

export const celoSepolia = defineChain({
  id: 44787,
  name: "Celo Sepolia",
  nativeCurrency: { name: "CELO", symbol: "CELO", decimals: 18 },
  rpcUrls: { default: { http: ["https://celo-sepolia.drpc.org"] } },
  blockExplorers: { default: { name: "Celoscan", url: "https://celo-sepolia.celoscan.io" } },
  testnet: true,
});

export const config = createConfig(
  getDefaultConfig({
    chains: [celoSepolia],
    transports: { [celoSepolia.id]: http() },
    walletConnectProjectId: "demo",
    appName: "GasGuard",
  })
);
