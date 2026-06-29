import os
import sys
from dotenv import load_dotenv

sys.path.append(r"d:/Last_Version_Final_Gradution_Project_2026/Rag Update")
sys.stdout.reconfigure(encoding="utf-8")
load_dotenv()

from routes.chat import collection, embeddings, _get_bm25_index
from routes.retrieval.hybrid_search import hybrid_search
from routes.retrieval.query_understanding import QueryIntent
from routes.retrieval.reranker import cosine_rerank

query = "شروط التخرج ف طب اسنان"
query_intent = QueryIntent(
    raw_query=query,
    normalized_query=query,
    clean_query="dentistry graduation requirements degree academic program شروط تخرج ف طب اسنان",
    program="dentistry",
    intent="graduation",
    confidence=0.65
)

retrieval_output = hybrid_search(
    query="متطلبات التخرج لبرنامج درجة طب الأسنان.",
    collection=collection,
    embeddings=embeddings,
    bm25_index=_get_bm25_index(),
    top_k=20,
    dense_candidates=100,
    sparse_candidates=100,
    use_rrf=True,
    use_query_understanding=True,
    query_intent=query_intent,
)
candidates = retrieval_output["results"]

# Run cosine_rerank and get the raw scored list before safety anchor if possible,
# or just look at scored list returned.
scored = cosine_rerank(
    query=query_intent.normalized_query,
    candidates=candidates,
    embeddings=embeddings,
    top_n=20,
    original_query=query,
)

print("--- CANDIDATES FROM COSINE RERANK ---")
for r in scored:
    meta = r.get("metadata", {})
    r_score = r.get("rerank_score")
    r_score_str = f"{r_score:.4f}" if r_score is not None else "None"
    print(f"File: {meta.get('fileName')} | Page: {meta.get('page')}")
    print(f"  Rerank Score: {r_score_str}")
    print(f"    _cos_sim:      {r.get('_cos_sim')}")
    print(f"    _kw_overlap:   {r.get('_kw_overlap')}")
    print(f"    _bm25_norm:    {r.get('_bm25_norm')}")
    print(f"    _table_signal: {r.get('_table_signal')}")
    print(f"  Text: {r.get('text')[:150].strip()}")
    print("-" * 50)
