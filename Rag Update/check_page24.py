import chromadb
import sys

sys.stdout.reconfigure(encoding="utf-8")

client = chromadb.PersistentClient(path="chroma_db")
try:
    collection = client.get_collection("university_regulations")
    print(f"Collection count: {collection.count()}")
    results = collection.get(where={"page": 24})
    docs = results.get("documents", [])
    metas = results.get("metadatas", [])
    print(f"Found {len(docs)} chunks for page 24:")
    for i in range(len(docs)):
        print(f"--- Chunk {i+1} ---")
        print(f"Metadata: {metas[i]}")
        print(f"Document snippet: {docs[i][:600]}...")
except Exception as e:
    print(f"Error: {e}")
