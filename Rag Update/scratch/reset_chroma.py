import chromadb
from chromadb.config import Settings

def reset_chroma():
    client = chromadb.PersistentClient(path="./chroma_db")
    print("Deleting 'university_regulations' collection...")
    try:
        client.delete_collection("university_regulations")
        print("SUCCESS: Collection deleted.")
    except Exception as e:
        print(f"Note: {e}")
    
    print("Recreating collection...")
    client.create_collection(
        name="university_regulations",
        metadata={"description": "University regulations (Local Embeddings)"}
    )
    print("✅ ChromaDB reset for local embeddings.")

if __name__ == "__main__":
    reset_chroma()
