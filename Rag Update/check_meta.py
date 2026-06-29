import chromadb

client = chromadb.PersistentClient("chroma_db")
collection = client.get_collection("university_regulations")

data = collection.get(limit=1)

print(data["metadatas"][0])