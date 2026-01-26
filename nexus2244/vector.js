from sentence_transformers import SentenceTransformer
import sqlite3, hashlib, sys, os

model = SentenceTransformer('all-MiniLM-L6-v2')
db_path = "memory/vectors.db"
os.makedirs(os.path.dirname(db_path), exist_ok=True)
conn = sqlite3.connect(db_path)
c = conn.cursor()
c.execute("CREATE TABLE IF NOT EXISTS memory (md5 TEXT, sha TEXT, vector BLOB, text TEXT)")

text = sys.stdin.read()
if text.strip():
    vec = model.encode(text).tobytes()
    md5 = hashlib.md5(text.encode()).hexdigest()
    sha = hashlib.sha256(text.encode()).hexdigest()

    c.execute("INSERT INTO memory VALUES (?,?,?,?)", (md5, sha, vec, text))
    conn.commit()
conn.close()
