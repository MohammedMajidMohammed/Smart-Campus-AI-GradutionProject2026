import chromadb
from chromadb.config import Settings
import sys
import io
from collections import Counter

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

chroma_client = chromadb.PersistentClient(
    path="./chroma_db",
    settings=Settings(anonymized_telemetry=False),
)

collection = chroma_client.get_collection(name="university_regulations")
print("Total chunks in DB:", collection.count())

# Get all metadata
results = collection.get(include=["metadatas"])
files = [m.get("fileName") for m in results.get("metadatas", []) if m]
counts = Counter(files)

print("Files in database and their chunk counts:")
for f, count in counts.items():
    print(f"  - {f}: {count}")
