import http.server
import socketserver
import json
import sqlite3
import os
from bip_utils import Bip39SeedGenerator, Bip44, Bip44Coins

# --- Configuration ---
PORT = 8000
AI_HOME = os.path.expanduser("~/.sysop-ai")
DB_PATH = os.path.join(AI_HOME, ".db", ".ai_data.db")
WALLET_DB_PATH = os.path.join(AI_HOME, ".db", ".wallet.db")

# --- Wallet & Seed Management ---
def setup_wallet_db():
    conn = sqlite3.connect(WALLET_DB_PATH)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS seeds
                 (id INTEGER PRIMARY KEY, mnemonic TEXT)''')
    c.execute('''CREATE TABLE IF NOT EXISTS wallets
                 (id INTEGER PRIMARY KEY, name TEXT, coin_type TEXT, address TEXT, private_key TEXT)''')
    conn.commit()
    conn.close()

def generate_seed():
    mnemonic = Bip39SeedGenerator.FromWordsNumber(12).Generate()
    return mnemonic

def create_wallet_from_seed(mnemonic, coin_type="BITCOIN"):
    seed_bytes = Bip39SeedGenerator(mnemonic).Generate()
    bip44_mst = Bip44.FromSeed(seed_bytes, Bip44Coins.BITCOIN)
    bip44_acc = bip44_mst.Purpose().Coin().Account(0)
    bip44_addr = bip44_acc.Change(0).AddressIndex(0)
    return {
        "address": bip44_addr.PublicKey().ToAddress(),
        "private_key": bip44_addr.PrivateKey().ToWif()
    }

# --- API Handler ---
class APIHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/api/memories':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            conn = sqlite3.connect(DB_PATH)
            c = conn.cursor()
            c.execute("SELECT id, task_id, prompt, response, timestamp FROM memories ORDER BY timestamp DESC")
            rows = c.fetchall()
            conn.close()
            self.wfile.write(json.dumps([dict(zip([c[0] for c in c.description], r)) for r in rows]).encode())
        else:
            super().do_GET()

    def do_POST(self):
        if self.path == '/api/wallet/seed':
            mnemonic = generate_seed()
            conn = sqlite3.connect(WALLET_DB_PATH)
            c = conn.cursor()
            c.execute("INSERT INTO seeds (mnemonic) VALUES (?)", (mnemonic,))
            conn.commit()
            conn.close()
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"mnemonic": mnemonic}).encode())
        else:
            self.send_response(404)
            self.end_headers()

# --- Main Execution ---
if __name__ == "__main__":
    setup_wallet_db()
    with socketserver.TCPServer(("", PORT), APIHandler) as httpd:
        print(f"Serving at port {PORT}")
        httpd.serve_forever()