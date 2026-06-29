import chromadb

client = chromadb.PersistentClient("chroma_db")

for c in client.list_collections():
    print(c.name)