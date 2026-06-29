
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
from routes.retrieval.hybrid_search import hybrid_search, understand_query
from routes.retrieval.bm25_index import get_or_build_index
from routes.upload import embeddings

# Setup Chroma
CHROMA_PATH = str(_HERE / "chroma_db")
COLLECTION_NAME = "university_regulations"
client = chromadb.PersistentClient(path=CHROMA_PATH, settings=Settings(anonymized_telemetry=False))
collection = client.get_collection(COLLECTION_NAME)
bm25 = get_or_build_index(collection_name=COLLECTION_NAME, collection=collection)

query = "اي هي أقسام كلية اسنان"
intent = understand_query(query)
print(f"Detected Intent: {intent.intent}")

results = hybrid_search(
    query             = query,
    collection        = collection,
    embeddings        = embeddings,
    bm25_index        = bm25,
    top_k             = 20, # Get more results to see where Page 10 is
    query_intent      = intent
)

with open("scratch/diagnose_output.txt", "w", encoding="utf-8") as f:
    f.write(f"Query: {query}\n")
    f.write(f"Intent: {intent.intent}, Program: {intent.program}\n")
    f.write(f"Total results: {len(results['results'])}\n\n")
    for i, r in enumerate(results["results"]):
        meta = r['metadata']
        f.write(f"[{i+1}] Page: {meta.get('page')}, File: {meta.get('fileName')}\n")
        f.write(f"    Program: {meta.get('program')}, Lang: {meta.get('language')}\n")
        f.write(f"    RRF Score: {r.get('rrf_score', 0):.4f}, Boosted Score: {r.get('boosted_score', 0):.4f}\n")
        f.write(f"    Boost Applied: {r.get('boost_applied', 0):.4f}\n")
        f.write(f"    Snippet: {r['text'][:150]}...\n")
        f.write("-" * 50 + "\n")
