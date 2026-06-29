import sys
import io
import chromadb
from collections import Counter

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def check_counts():
    client = chromadb.PersistentClient(path="./chroma_db")
    collection = client.get_collection("university_regulations")
    results = collection.get()
    
    metadatas = results.get("metadatas", [])
    files = [m.get("fileName") for m in metadatas]
    counts = Counter(files)
    
    print("\nChunk counts per file:")
    for f, c in counts.items():
        print(f" - File: {f} | Count: {c} chunks")

if __name__ == "__main__":
    check_counts()
