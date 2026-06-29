
import sys, io, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

sys.path.insert(0, '.')
from chat_cli import RAGSession

session = RAGSession()

print("Searching for engineering first year courses in DB...")
result = session.collection.get(
    where={"program": "engineering"},
    include=["documents", "metadatas"]
)

docs = result["documents"]
metas = result["metadatas"]
print(f"Total engineering chunks: {len(docs)}")

# Let's search for chunks containing "المستوى الأول" or "السنة الأولى" or "الفصل الدراسي"
import re
for i, (doc, meta) in enumerate(zip(docs, metas)):
    if any(kw in doc for kw in ["المستوى الأول", "السنة الأولى", "الفرقة الأولى"]):
        print(f"\n--- Chunk {i} | {meta.get('fileName')} Page {meta.get('page')} ---")
        print(doc[:500])
