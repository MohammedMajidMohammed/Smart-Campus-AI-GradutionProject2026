import chromadb
import sys

sys.stdout.reconfigure(encoding="utf-8")

client = chromadb.PersistentClient(path="chroma_db")
collection = client.get_collection("university_regulations")

res = collection.get(
    where={
        "$and": [
            {"fileName": "دليل_برامج_كلية_الحاسوب_والذكاء_الاصطناعى_جامعة_المنوفية_الاهلية.pdf"},
            {"chunkIndex": 50}
        ]
    }
)

docs = res.get("documents", [])
metas = res.get("metadatas", [])
ids = res.get("ids", [])

print(f"Found {len(docs)} chunks with chunkIndex == 50:")
for i in range(len(docs)):
    print(f"\n--- Chunk {i+1} ---")
    print(f"ID: {ids[i]}")
    print(f"Metadata: {metas[i]}")
    print(f"Snippet: {docs[i][:400]}")
    print("-" * 50)
