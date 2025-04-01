'use client'

import { useEffect, useState } from 'react'
import { formatEther } from 'viem'
import { useAccount, useReadContract } from 'wagmi'
import { ETH_SOLVER_VAULT_ADDRESS } from '@/config'

// ABI for ERC4626 vault
const vaultAbi = [
  {
    "inputs": [{ "internalType": "address", "name": "account", "type": "address" }],
    "name": "balanceOf",
    "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "totalAssets",
    "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }],
    "stateMutability": "view",
    "type": "function"
  }
] as const

export const VaultBalance = () => {
  const { address, isConnected } = useAccount()
  const [formattedBalance, setFormattedBalance] = useState<string>('0')
  const [formattedTotalAssets, setFormattedTotalAssets] = useState<string>('0')

  // Get user's vault token balance
  const { data: userBalance } = useReadContract({
    address: ETH_SOLVER_VAULT_ADDRESS as `0x${string}`,
    abi: vaultAbi,
    functionName: 'balanceOf',
    args: [address || '0x0000000000000000000000000000000000000000'],
    query: {
      enabled: isConnected && !!address,
    }
  })

  // Get total assets in vault
  const { data: totalAssets } = useReadContract({
    address: ETH_SOLVER_VAULT_ADDRESS as `0x${string}`,
    abi: vaultAbi,
    functionName: 'totalAssets',
    query: {
      enabled: isConnected,
    }
  })

  console.log(totalAssets)

  useEffect(() => {
    if (userBalance) {
      setFormattedBalance(parseFloat(formatEther(userBalance)).toFixed(4))
    }
    if (totalAssets) {
      setFormattedTotalAssets(parseFloat(formatEther(totalAssets)).toFixed(4))
    }
  }, [userBalance, totalAssets])

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6 w-full max-w-md">
      <h2 className="text-xl font-semibold mb-4">Vault Balance</h2>
      <div className="space-y-4">
        <div className="flex justify-between items-center">
          <span className="text-gray-600 dark:text-gray-300">Your Balance:</span>
          <span className="font-medium">{formattedBalance} mETH</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-gray-600 dark:text-gray-300">Total Assets in Vault:</span>
          <span className="font-medium">{formattedTotalAssets} ETH</span>
        </div>
      </div>
      {!isConnected && (
        <div className="mt-4 text-sm text-gray-500 dark:text-gray-400">
          Connect your wallet to view your balance
        </div>
      )}
    </div>
  )
}
