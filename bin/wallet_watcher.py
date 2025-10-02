#!/usr/bin/env python3
import asyncio, json
from web3 import Web3
from pathlib import Path

BASE = Path.home() / ".local_ai"
BASE.mkdir(parents=True, exist_ok=True)
LOGFILE = BASE / "wallet_events.log"

# ⚡ Replace with your wallet + RPC provider
WALLET = "0xYourWalletAddressHere".lower()
RPC = "wss://mainnet.infura.io/ws/v3/YOUR_INFURA_KEY"

web3 = Web3(Web3.WebsocketProvider(RPC))

async def watch_tx():
    print("🔌 Watching mempool for", WALLET)
    while True:
        try:
            sub = web3.eth.filter("pending")
            while True:
                for tx_hash in sub.get_new_entries():
                    try:
                        tx = web3.eth.get_transaction(tx_hash)
                        if tx and (tx["from"].lower() == WALLET or tx["to"] and tx["to"].lower() == WALLET):
                            event = {
                                "hash": tx["hash"].hex(),
                                "from": tx["from"],
                                "to": tx["to"],
                                "value": web3.from_wei(tx["value"], "ether")
                            }
                            LOGFILE.write_text(json.dumps(event) + "\n")
                            print("💸 Wallet TX:", event)
                    except Exception:
                        continue
                await asyncio.sleep(2)
        except Exception as e:
            print("Watcher error:", e)
            await asyncio.sleep(5)

async def main():
    await watch_tx()

if __name__ == "__main__":
    asyncio.run(main())
