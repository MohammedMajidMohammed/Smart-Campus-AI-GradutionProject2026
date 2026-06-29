import os
import sys
from dotenv import load_dotenv

sys.path.append(r"d:/Last_Version_Final_Gradution_Project_2026/Rag Update")
sys.stdout.reconfigure(encoding="utf-8")
load_dotenv()

from routes.chat import collection, embeddings, _get_bm25_index
from routes.retrieval.hybrid_search import hybrid_search
from routes.retrieval.query_understanding import QueryIntent

# Build the exact QueryIntent object as it would be created by understand_query
query = "شروط التخرج ف طب اسنان"
query_intent = QueryIntent(
    raw_query=query,
    normalized_query=query,
    clean_query="dentistry graduation requirements degree academic program شروط تخرج ف طب اسنان",
    program="dentistry",
    year=None,
    semester=None,
    intent="graduation",
    confidence=0.65,
    classifier_tier="rule_based"
)

# Run hybrid search
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
    use_multi_query=True,
    use_section_boost=True,
    query_intent=query_intent,
)

results = retrieval_output["results"]
print(f"Total results: {len(results)}")

for i, r in enumerate(results[:20]):
    print(f"Rank {i+1}: File={r.get('metadata', {}).get('fileName')}, Page={r.get('metadata', {}).get('page')}")
    print(f"  Score: {r.get('boosted_score', r.get('rrf_score', 0.0)):.4f} | RRF: {r.get('rrf_score', 0.0):.4f} | Program Score: {r.get('program_score', 0.0)}")
    print(f"  Snippet: {r.get('text', '')[:150].strip()}")
    print("-" * 50)
