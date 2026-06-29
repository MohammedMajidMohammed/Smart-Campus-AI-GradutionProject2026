
import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Path setup
_HERE = Path(r"c:\Users\Right Click\Downloads\Telegram Desktop\Rag Update\Rag Update")
sys.path.insert(0, str(_HERE))
load_dotenv(_HERE / ".env")

import chromadb
from chromadb.config import Settings
from routes.retrieval.hybrid_search import hybrid_search
from routes.retrieval.bm25_index import get_or_build_index
from routes.upload import embeddings

# Setup Chroma
CHROMA_PATH = str(_HERE / "chroma_db")
COLLECTION_NAME = "university_regulations"
client = chromadb.PersistentClient(path=CHROMA_PATH, settings=Settings(anonymized_telemetry=False))
collection = client.get_collection(COLLECTION_NAME)

# Setup BM25
bm25 = get_or_build_index(collection_name=COLLECTION_NAME, collection=collection)

# Test query
query = "اي هي أقسام كلية اسنان"
results = hybrid_search(
    query=query,
    collection=collection,
    embeddings=embeddings,
    bm25_index=bm25,
    top_k=8
)

with open("scratch/hybrid_test_output.txt", "w", encoding="utf-8") as f:
    f.write(f"Retrieved {len(results['results'])} chunks\n")
    for i, r in enumerate(results["results"]):
        meta = r['metadata']
        f.write(f"[{i+1}] Page: {meta.get('page')}, File: {meta.get('fileName')}\n")
        f.write(f"    Score: {r.get('boosted_score', r.get('rrf_score'))}\n")
        f.write(f"    Snippet: {r['text'][:200]}\n")
        f.write("-" * 50 + "\n")
