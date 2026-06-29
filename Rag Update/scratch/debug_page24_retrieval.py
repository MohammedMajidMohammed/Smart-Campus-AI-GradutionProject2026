import os
import sys
from dotenv import load_dotenv

sys.path.append(r"d:/Last_Version_Final_Gradution_Project_2026/Rag Update")
sys.stdout.reconfigure(encoding="utf-8")
load_dotenv()

from routes.chat import collection, embeddings, _get_bm25_index
from routes.retrieval.hybrid_search import hybrid_search, dense_retrieve
from routes.retrieval.query_understanding import QueryIntent

query = "شروط التخرج ف طب اسنان"
query_intent = QueryIntent(
    raw_query=query,
    normalized_query=query,
    clean_query="dentistry graduation requirements degree academic program شروط تخرج ف طب اسنان",
    program="dentistry",
    intent="graduation",
    confidence=0.65
)

search_query = "متطلبات التخرج لبرنامج درجة طب الأسنان."

# Let's perform dense and sparse search manually to see why Page 24 is low
bm25_index = _get_bm25_index()
# 1. Sparse search
sparse_results = bm25_index.query(search_query, top_k=100)
# 2. Dense search
dense_results = dense_retrieve(search_query, collection, embeddings, top_k=100)

print("--- SPARSE SEARCH MATCHES FOR PAGE 24 ---")
for r in sparse_results:
    meta = r.get("metadata", {})
    if meta.get("fileName") == "لائحه الفم والاسنان جامعة المنوفية الأهليه A-1.pdf" and meta.get("page") == 24:
        print(f"Page 24 Chunk: {r.get('text')[:120].strip()}")
        print(f"  Sparse Score: {r.get('score')}")

print("\n--- DENSE SEARCH MATCHES FOR PAGE 24 ---")
for r in dense_results:
    meta = r.get("metadata", {})
    if meta.get("fileName") == "لائحه الفم والاسنان جامعة المنوفية الأهليه A-1.pdf" and meta.get("page") == 24:
        print(f"Page 24 Chunk: {r.get('text')[:120].strip()}")
        print(f"  Distance: {r.get('distance')}, Score: {r.get('score')}")
