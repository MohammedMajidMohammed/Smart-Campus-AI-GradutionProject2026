import sys
import chromadb
from chromadb.config import Settings

# Reconfigure stdout to use utf-8
sys.stdout.reconfigure(encoding='utf-8')

c = chromadb.PersistentClient(path='./chroma_db', settings=Settings(anonymized_telemetry=False))
col = c.get_collection('university_regulations')

results = col.query(
    query_texts=["رئيس جامعة المنوفية الأهلية"],
    n_results=10,
    include=["documents", "metadatas"]
)

for idx, (doc, meta) in enumerate(zip(results["documents"][0], results["metadatas"][0])):
    print(f"\n--- Result {idx+1} | File: {meta.get('fileName')} | Page: {meta.get('page')} ---")
    print(doc[:500])
