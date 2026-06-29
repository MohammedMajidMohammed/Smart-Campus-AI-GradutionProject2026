import sys, io, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

# Always use the project root, not the scratch dir
PROJECT_ROOT = r"C:\Users\Right Click\Downloads\Telegram Desktop\Rag Update\Rag Update"
os.chdir(PROJECT_ROOT)
sys.path.insert(0, PROJECT_ROOT)

import chromadb
from collections import defaultdict

CHROMA_PATH = os.path.join(PROJECT_ROOT, "chroma_db")
COLLECTION  = "university_regulations"

client = chromadb.PersistentClient(path=CHROMA_PATH)
col    = client.get_collection(COLLECTION)

print(f"Total collection size: {col.count()}")

# Get arts chunks
results = col.get(
    where={"program": "arts"},
    include=["metadatas", "documents"],
    limit=500
)

docs  = results["documents"]
metas = results["metadatas"]
print(f"Arts program chunks: {len(docs)}")
print()

# Group by file
files = defaultdict(list)
for d, m in zip(docs, metas):
    fname = m.get("fileName", "Unknown")
    page  = m.get("page", "?")
    files[fname].append((page, d))

for fname, pages in sorted(files.items()):
    pages.sort(key=lambda x: x[0] if isinstance(x[0], int) else 0)
    total_text = sum(len(p[1]) for p in pages)
    print(f"File: {fname}")
    print(f"  Pages: {len(pages)}, Total chars: {total_text}")
    if pages:
        sample = pages[0][1][:300].replace('\n', ' ')
        print(f"  Sample (p.{pages[0][0]}): {sample}")
    print()

# Check OCR quality - show chunks from the arts-specific laiha
print("=" * 60)
print("Detailed chunks from translation regulation:")
print("=" * 60)
for fname, pages in files.items():
    if "ترجمة" in fname or "انجليزية" in fname or "english" in fname.lower():
        for page, text in sorted(pages, key=lambda x: x[0] if isinstance(x[0], int) else 0)[:5]:
            print(f"\n--- Page {page} ---")
            print(text[:500])
            print()
