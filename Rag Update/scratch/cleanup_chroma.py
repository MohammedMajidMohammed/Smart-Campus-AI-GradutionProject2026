import os
import sys
import io
import chromadb
from chromadb.config import Settings

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def cleanup_old_data():
    chroma_path = "./chroma_db"
    client = chromadb.PersistentClient(path=chroma_path)
    collection = client.get_collection("university_regulations")
    
    # Delete all chunks from the original engineering file
    print("Deleting old engineering chunks...")
    collection.delete(where={"fileName": "هندسه.pdf"})
    print("SUCCESS: Deleted old chunks.")

if __name__ == "__main__":
    cleanup_old_data()
