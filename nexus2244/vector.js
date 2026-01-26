from sentence_transformers import SentenceTransformer
import sqlite3, hashlib, sys

model = SentenceTransformer('all-MiniLM-L6-v2')
conn = sqlite3.connect("memory/vectors.db")
c = conn.cursor()
c.execute("CREATE TABLE IF NOT EXISTS memory (md5 TEXT, sha TEXT, vector BLOB, text TEXT)")

text = sys.stdin.read()
vec = model.encode(text).tobytes()
md5 = hashlib.md5(text.encode()).hexdigest()
sha = hashlib.sha256(text.encode()).hexdigest()

c.execute("INSERT INTO memory VALUES (?,?,?,?)", (md5, sha, vec, text))
conn.commit()