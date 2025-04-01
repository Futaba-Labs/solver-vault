import type { Metadata } from "next";
import { headers } from 'next/headers'
import { Geist, Geist_Mono } from "next/font/google";
import ContextProvider from '@/context'
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Solver Vault",
  description: "Deposit ETH to Solver Vault",
};

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const headersData = await headers();
  const cookies = headersData.get('cookie');

  return (
    <html lang="en" className={`${geistSans.variable} ${geistMono.variable}`}>
      <body className="min-h-screen bg-gray-50 dark:bg-gray-900">
        <ContextProvider cookies={cookies}>
          <main className="flex flex-col min-h-screen">
            {children}
          </main>
        </ContextProvider>
      </body>
    </html>
  );
}
