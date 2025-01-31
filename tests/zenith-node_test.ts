import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can register new node with sufficient stake",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "zenith-node",
        "register-node",
        [types.uint(10000)],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, "(ok true)");
  },
});

Clarinet.test({
  name: "Ensure cannot register with insufficient stake",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "zenith-node",
        "register-node",
        [types.uint(5000)],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, "(err u103)");
  },
});

Clarinet.test({
  name: "Can update node status after registration",
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
        "update-status",
        [types.ascii("inactive")],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[1].result, "(ok true)");
  },
});
