import { Header } from "@/components/Header";
import { DepositForm } from "@/components/DepositForm";
import { VaultBalance } from "@/components/VaultBalance";

export default function Home() {
  return (
    <>
      <Header />
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-2xl font-bold mb-6">Solver Vault Dashboard</h1>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          <div>
            <DepositForm />
          </div>
          <div>
            <VaultBalance />
          </div>
        </div>
      </div>
    </>
  );
}
