import chromadb
from chromadb.config import Settings
import os
import sys
import io

# Fix terminal encoding for Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

chroma = chromadb.PersistentClient(
    path="./chroma_db",
    settings=Settings(anonymized_telemetry=False),
)
col = chroma.get_collection("university_regulations")
data = col.get(include=["metadatas"])

final = {}
for m in data["metadatas"]:
    fn = m.get("fileName", "?")
    prog = m.get("program") or "None"
    if fn not in final:
        final[fn] = {}
    final[fn][prog] = final[fn].get(prog, 0) + 1

print(f"{'Chunks':<8} {'Program':<20} {'FileName'}")
print("-" * 70)
for fn, progs in sorted(final.items()):
    for prog, cnt in progs.items():
        print(f"{cnt:<8} {prog:<20} {fn}")
