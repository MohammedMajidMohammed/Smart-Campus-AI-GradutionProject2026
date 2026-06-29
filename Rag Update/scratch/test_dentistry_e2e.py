import os
import sys
from dotenv import load_dotenv

sys.path.append(r"d:/Last_Version_Final_Gradution_Project_2026/Rag Update")
sys.stdout.reconfigure(encoding="utf-8")
load_dotenv()

from routes.chat import collection, embeddings, _get_bm25_index, llm, verify_answer, _build_context
from routes.retrieval.hybrid_search import hybrid_search
from routes.retrieval.query_understanding import QueryIntent
from routes.retrieval.reranker import rerank_results

# Define query
query = "شروط التخرج ف طب اسنان"

# 1. Query Understanding
query_intent = QueryIntent(
    raw_query=query,
    normalized_query=query,
    clean_query="dentistry graduation requirements degree academic program شروط تخرج ف طب اسنان",
    program="dentistry",
    intent="graduation",
    confidence=0.65
)

# 2. Hybrid Search (retrieving candidates)
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

print("--- CANDIDATES FROM HYBRID SEARCH ---")
for i, c in enumerate(candidates):
    print(f"Rank {i+1}: Page {c['metadata']['page']} of {c['metadata']['fileName']} | Score {c.get('boosted_score', 0):.4f}")

# 3. Rerank (default: cosine)
reranked = rerank_results(
    query=query_intent.normalized_query,
    candidates=candidates,
    embeddings=embeddings,
    top_n=5,
    original_query=query,
)

print("\n--- AFTER RERANK (cosine, top 5) ---")
for i, c in enumerate(reranked):
    print(f"Rank {i+1}: Page {c['metadata']['page']} of {c['metadata']['fileName']} | Rerank Score {c.get('rerank_score', 0):.4f}")

# 4. Context building
context = _build_context(reranked)
print("\n--- CONTEXT SENT TO LLM ---")
print(context)
