import { cookieStorage, createStorage } from 'wagmi'
import { WagmiAdapter } from '@reown/appkit-adapter-wagmi'
import { mainnet, arbitrum, baseSepolia, optimismSepolia } from '@reown/appkit/networks'
import type { AppKitNetwork } from '@reown/appkit/networks'

// Get projectId from https://cloud.reown.com
export const projectId = process.env.NEXT_PUBLIC_PROJECT_ID || "b56e18d47c72ab683b10814fe9495694" // this is a public projectId only to use on localhost

if (!projectId) {
  throw new Error('Project ID is not defined')
}

export const networks = [mainnet, arbitrum, baseSepolia, optimismSepolia] as [AppKitNetwork, ...AppKitNetwork[]]

// Contract addresses
export const ETH_SOLVER_VAULT_ADDRESS = "0x1F2EE6aB0188961465779909a2f51F286dA3cDf7"
export const WETH_ADDRESS = "0x4200000000000000000000000000000000000006" // Base Sepolia WETH

// Available tokens for deposit
export const AVAILABLE_TOKENS = [
  {
    symbol: "ETH",
    address: "0x0000000000000000000000000000000000000000", // Native ETH
    decimals: 18,
    isNative: true
  },
  {
    symbol: "WETH",
    address: WETH_ADDRESS,
    decimals: 18,
    isNative: false
  }
]

// Available chains
export const AVAILABLE_CHAINS = [
  {
    id: 84532, // Base Sepolia
    name: "Base Sepolia",
  },
  {
    id: 11155420, // OP Sepolia
    name: "OP Sepolia",
  }
]

//Set up the Wagmi Adapter (Config)
export const wagmiAdapter = new WagmiAdapter({
  storage: createStorage({
    storage: cookieStorage
  }),
  ssr: true,
  projectId,
  networks
})

export const config = wagmiAdapter.wagmiConfig
