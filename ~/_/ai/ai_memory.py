import sqlite3, hashlib
from sentence_transformers import SentenceTransformer
model = SentenceTransformer("all-MiniLM-L6-v2")
db = sqlite3.connect("db/nexus.db")

def store(token):
    sha = hashlib.sha256(token.encode()).hexdigest()
    emb = model.encode(token).tobytes()
    db.execute("INSERT INTO vectors VALUES (NULL,?,?)",(sha,emb))
    db.commit()
