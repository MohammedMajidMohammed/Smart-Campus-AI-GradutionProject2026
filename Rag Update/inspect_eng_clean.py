
import sys, io, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

sys.path.insert(0, '.')
from chat_cli import RAGSession

session = RAGSession()

print("Fetching chunks from هندسه.pdf...")
result = session.collection.get(
    where={"fileName": "هندسه.pdf"},
    limit=15,
    include=["documents", "metadatas"]
)

docs = result["documents"]
metas = result["metadatas"]
print(f"Retrieved {len(docs)} chunks.")

for i, (doc, meta) in enumerate(zip(docs, metas)):
    print(f"\n--- Chunk {i+1} | {meta.get('fileName')} Page {meta.get('page')} ---")
    print(doc[:300])
