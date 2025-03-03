import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous tests remain unchanged...]

Clarinet.test({
  name: "Ensure withdrawal process works correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "zenith-node",
        "register-node",
        [types.uint(10000)],
        wallet_1.address
      ),
      Tx.contractCall(
        "zenith-node",
        "initiate-withdrawal",
        [],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[1].result, "(ok true)");
    
    // Mine blocks to pass cooldown
    chain.mineEmptyBlockUntil(chain.blockHeight + 100);
    
    block = chain.mineBlock([
      Tx.contractCall(
        "zenith-node",
        "complete-withdrawal",
        [],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, "(ok true)");
  },
});
