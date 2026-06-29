import chromadb

client = chromadb.PersistentClient("chroma_db")
collection = client.get_collection("university_regulations")

results = collection.get(
    where={"page": 17}
)

print("chunks =", len(results["documents"]))

for i, meta in enumerate(results["metadatas"]):
    print("\nMETA", i + 1)
    print(meta)