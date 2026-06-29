import os
import sys
from dotenv import load_dotenv

sys.path.append(r"d:/Last_Version_Final_Gradution_Project_2026/Rag Update")
sys.stdout.reconfigure(encoding="utf-8")
load_dotenv()

from routes.chat import collection, embeddings, _get_bm25_index
from routes.retrieval.hybrid_search import hybrid_search
from routes.retrieval.query_understanding import QueryIntent

qi = QueryIntent(
    raw_query="شروط التخرج ف طب اسنان",
    normalized_query="شروط التخرج ف طب اسنان",
    clean_query="dentistry graduation requirements degree academic program شروط تخرج ف طب اسنان",
    program="dentistry",
    intent="graduation",
    confidence=0.65
)

ret = hybrid_search(
    query="متطلبات التخرج لبرنامج درجة طب الأسنان.",
    collection=collection,
    embeddings=embeddings,
    bm25_index=_get_bm25_index(),
    top_k=20,
    dense_candidates=100,
    sparse_candidates=100,
    use_rrf=True,
    use_query_understanding=True,
    query_intent=qi
)

print("--- DETAILED BOOST BREAKDOWN ---")
for i, r in enumerate(ret["results"]):
    meta = r["metadata"]
    if meta.get("page") in (10, 5, 24):
        print(f"Rank {i+1}: File={meta.get('fileName')}, Page={meta.get('page')}")
        print(f"  rrf_score:               {r.get('rrf_score')}")
        print(f"  boost_applied (section): {r.get('boost_applied')}")
        print(f"  program_score:           {r.get('program_score')}")
        print(f"  program_boosted:         {r.get('program_boosted')}")
        print(f"  table_boosted:           {r.get('table_boosted')}")
        print(f"  keyword_anchor_boosted:  {r.get('keyword_anchor_boosted')}")
        print(f"  cross_score:             {r.get('cross_score')}")
        print(f"  boosted_score (final):   {r.get('boosted_score')}")
        print(f"  Text: {r.get('text')[:120].strip()}")
        print("-" * 50)
