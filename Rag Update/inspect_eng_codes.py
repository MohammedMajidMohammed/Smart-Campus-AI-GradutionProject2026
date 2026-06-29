
import sys, io, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

sys.path.insert(0, '.')
from chat_cli import RAGSession

session = RAGSession()

print("Searching for chunks containing BAS or COM in engineering program...")
result = session.collection.get(
    where={"program": "engineering"},
    include=["documents", "metadatas"]
)

docs = result["documents"]
metas = result["metadatas"]

count = 0
for i, (doc, meta) in enumerate(zip(docs, metas)):
    if "BAS" in doc or "COM" in doc or "CVE" in doc:
        count += 1
        print(f"\n--- Clean/English Chunk {count} | {meta.get('fileName')} Page {meta.get('page')} ---")
        print(doc[:400])
        if count >= 10:
            break
