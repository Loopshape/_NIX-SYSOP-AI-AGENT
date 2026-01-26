import sqlite3, hashlib
try:
    from sentence_transformers import SentenceTransformer
    model = SentenceTransformer("all-MiniLM-L6-v2")
except ImportError:
    print("Warning: sentence_transformers not found. Vector storage will be disabled.")
    model = None

db = sqlite3.connect("/home/loop/_/nexus/db/nexus.db")

def store(token):
    if model is None: return
    sha = hashlib.sha256(token.encode()).hexdigest()
    emb = model.encode(token).tobytes()
    db.execute("INSERT INTO vectors VALUES (NULL,?,?)",(sha,emb))
    db.commit()
