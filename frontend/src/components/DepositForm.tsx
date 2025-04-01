'use client'

import { useState, useEffect } from 'react'
import { useAccount, useWriteContract, useWaitForTransactionReceipt, useChainId, useSwitchChain } from 'wagmi'
import { parseEther } from 'viem'
import { AVAILABLE_CHAINS, AVAILABLE_TOKENS, ETH_SOLVER_VAULT_ADDRESS } from '@/config'

// ABI for ETHSolverVault
const vaultAbi = [
  {
    "inputs": [
      { "internalType": "uint256", "name": "assets", "type": "uint256" },
      { "internalType": "address", "name": "receiver", "type": "address" }
    ],
    "name": "depositNative",
    "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }],
    "stateMutability": "payable",
    "type": "function"
  }
] as const

export const DepositForm = () => {
  const { address, isConnected } = useAccount()
  const { switchChain } = useSwitchChain()
  
  const chainId = useChainId()
  
  const [selectedChain, setSelectedChain] = useState<number>(84532) // Default to Base Sepolia
  const [selectedToken, setSelectedToken] = useState<string>(AVAILABLE_TOKENS[0].address)
  const [amount, setAmount] = useState<string>('')
  const [isNative, setIsNative] = useState<boolean>(true)
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle')
  const [errorMessage, setErrorMessage] = useState<string>('')

  // Set up contract write
  const { data: hash, isPending, writeContract } = useWriteContract()

  // Wait for transaction receipt
  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  })

  // Update status based on transaction states
  useEffect(() => {
    if (isPending || isConfirming) {
      setStatus('loading')
    } else if (isConfirmed) {
      setStatus('success')
      setAmount('')
    }
  }, [isPending, isConfirming, isConfirmed])

  // Update isNative when token selection changes
  useEffect(() => {
    const selectedTokenObj = AVAILABLE_TOKENS.find(token => token.address === selectedToken)
    if (selectedTokenObj) {
      setIsNative(selectedTokenObj.isNative)
    }
  }, [selectedToken])

  // Handle chain change
  const handleChainChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setSelectedChain(Number(e.target.value))
    switchChain({ chainId: Number(e.target.value) })
  }
  // Handle token change
  const handleTokenChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setSelectedToken(e.target.value)
  }

  // Handle amount change
  const handleAmountChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    // Only allow numbers and decimals
    const value = e.target.value
    if (value === '' || /^\d*\.?\d*$/.test(value)) {
      setAmount(value)
    }
  }

  // Handle deposit
  const handleDeposit = async () => {
    if (!isConnected || !address) {
      setStatus('error')
      setErrorMessage('Please connect your wallet')
      return
    }

    if (chainId !== selectedChain) {
      setStatus('error')
      setErrorMessage(`Please switch to ${AVAILABLE_CHAINS.find(chain => chain.id === selectedChain)?.name}`)
      return
    }

    if (!amount || parseFloat(amount) <= 0) {
      setStatus('error')
      setErrorMessage('Please enter a valid amount')
      return
    }

    try {
      setStatus('loading')
      setErrorMessage('')

      // For native ETH deposits
      if (isNative) {
        writeContract({
          address: ETH_SOLVER_VAULT_ADDRESS as `0x${string}`,
          abi: vaultAbi,
          functionName: 'depositNative',
          args: [parseEther(amount), address],
          value: parseEther(amount)
        })
      } else {
        // For ERC20 tokens (not implemented in this example)
        setStatus('error')
        setErrorMessage('ERC20 token deposits not implemented yet')
      }
    } catch (error) {
      console.error('Deposit error:', error)
      setStatus('error')
      setErrorMessage('Transaction failed. Please try again.')
    }
  }

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6 w-full max-w-md">
      <h2 className="text-xl font-semibold mb-4">Deposit to Vault</h2>
      
      <div className="space-y-4">
        {/* Chain Selection */}
        <div>
          <label htmlFor="chain" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            Select Chain
          </label>
          <select
            id="chain"
            value={selectedChain}
            onChange={handleChainChange}
            className="w-full px-3 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-gray-700"
          >
            {AVAILABLE_CHAINS.map((chain) => (
              <option key={chain.id} value={chain.id}>
                {chain.name}
              </option>
            ))}
          </select>
        </div>

        {/* Token Selection */}
        <div>
          <label htmlFor="token" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            Select Token
          </label>
          <select
            id="token"
            value={selectedToken}
            onChange={handleTokenChange}
            className="w-full px-3 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-gray-700"
          >
            {AVAILABLE_TOKENS.map((token) => (
              <option key={token.address} value={token.address}>
                {token.symbol}
              </option>
            ))}
          </select>
        </div>

        {/* Amount Input */}
        <div>
          <label htmlFor="amount" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            Amount
          </label>
          <div className="relative">
            <input
              id="amount"
              type="text"
              value={amount}
              onChange={handleAmountChange}
              placeholder="0.0"
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-gray-700"
            />
            <div className="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
              <span className="text-gray-500">
                {AVAILABLE_TOKENS.find(token => token.address === selectedToken)?.symbol}
              </span>
            </div>
          </div>
        </div>

        {/* Error Message */}
        {status === 'error' && (
          <div className="text-red-500 text-sm">{errorMessage}</div>
        )}

        {/* Success Message */}
        {status === 'success' && (
          <div className="text-green-500 text-sm">Deposit successful!</div>
        )}

        {/* Deposit Button */}
        <button
          onClick={handleDeposit}
          disabled={status === 'loading' || !isConnected}
          className={`w-full py-2 px-4 rounded-md font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 ${
            status === 'loading'
              ? 'bg-gray-400 cursor-not-allowed'
              : isConnected
              ? 'bg-blue-600 hover:bg-blue-700 text-white focus:ring-blue-500'
              : 'bg-gray-400 cursor-not-allowed text-white'
          }`}
        >
          {status === 'loading' ? 'Processing...' : 'Deposit'}
        </button>
      </div>

      {!isConnected && (
        <div className="mt-4 text-sm text-gray-500 dark:text-gray-400">
          Connect your wallet to deposit
        </div>
      )}
    </div>
  )
}
