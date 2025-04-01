'use client'

import { ConnectButton } from "./ConnectButton"
import Link from "next/link"
import { usePathname } from "next/navigation"

export const Header = () => {
  const pathname = usePathname()
  
  const navItems = [
    { name: 'Home', path: '/' },
    { name: 'Bridge', path: 'https://intents-framework-ui.vercel.app' }
  ]

  return (
    <header className="w-full py-4 px-6 flex justify-between items-center border-b border-gray-200 bg-white dark:bg-gray-900 dark:border-gray-800">
      <div className="flex items-center space-x-2">
        <h1 className="text-xl font-bold">Solver Vault</h1>
        <nav className="ml-8">
          <ul className="flex space-x-6">
            {navItems.map((item) => (
              <li key={item.path}>
                <Link 
                  href={item.path}
                  target={item.path.includes('https') ? '_blank' : undefined}
                  className={`hover:text-blue-600 transition-colors ${
                    pathname === item.path ? 'text-blue-600 font-medium' : 'text-gray-600 dark:text-gray-300'
                  }`}
                >
                  {item.name}
                </Link>
              </li>
            ))}
          </ul>
        </nav>
      </div>
      <ConnectButton />
    </header>
  )
}
