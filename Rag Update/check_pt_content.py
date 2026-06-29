
import chromadb
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

client = chromadb.PersistentClient(path="chroma_db")
collection = client.get_collection("university_regulations")

res = collection.get(
    where={"program": "physical therapy"},
    include=["documents", "metadatas"]
)

docs = res["documents"]
metas = res["metadatas"]

keywords = ["تخرج", "لائحة", "بكالوريوس", "شروط", "متطلبات", "معدل", "تراكمي"]

print(f"Total PT chunks: {len(docs)}")

matches = []
for i, d in enumerate(docs):
    found = [kw for kw in keywords if kw in d]
    if found:
        matches.append((i, found, d, metas[i]))

print(f"Chunks with keywords: {len(matches)}")
for i, found, text, meta in matches[:5]:
    print("\n---")
    print(f"Page: {meta.get('page')} Keywords: {found}")
    print(f"Preview: {text[:300].replace(chr(10), ' ')}")
