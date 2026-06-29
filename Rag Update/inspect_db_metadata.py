
import chromadb
from chromadb.config import Settings
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

client = chromadb.PersistentClient(path="chroma_db")
print("Collections:", client.list_collections())
collection = client.get_collection("university_regulations")
print("Total Chunks:", collection.count())

# Let's count chunks by program metadata
results = collection.get(include=["metadatas"])
metadatas = results["metadatas"]
prog_counts = {}
for meta in metadatas:
    prog = meta.get("program", "None")
    prog_counts[prog] = prog_counts.get(prog, 0) + 1

print("\nChunk counts by program:")
for p, c in sorted(prog_counts.items()):
    print(f"  {p}: {c}")

# Let's count by filename
file_counts = {}
for meta in metadatas:
    fname = meta.get("fileName", "None")
    file_counts[fname] = file_counts.get(fname, 0) + 1

print("\nChunk counts by fileName:")
for f, c in sorted(file_counts.items()):
    print(f"  {f}: {c}")
