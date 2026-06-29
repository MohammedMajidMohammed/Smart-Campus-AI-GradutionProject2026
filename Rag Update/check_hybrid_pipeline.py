import chromadb
import sys
import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

sys.stdout.reconfigure(encoding="utf-8")

from routes.chat import _LocalHuggingFaceEmbeddings, _get_bm25_index
from routes.retrieval.query_understanding import understand_query
from routes.retrieval.hybrid_search import hybrid_search, dense_retrieve, _dual_bm25_retrieve, reciprocal_rank_fusion, _apply_program_isolation, _table_boost, _stderr
from langchain_openai import ChatOpenAI

client = chromadb.PersistentClient(path="chroma_db")
collection = client.get_collection("university_regulations")
embeddings = _LocalHuggingFaceEmbeddings()
bm25_idx = _get_bm25_index()

llm = ChatOpenAI(
    openai_api_key=os.getenv("OPENROUTER_API_KEY"),
    openai_api_base="https://openrouter.ai/api/v1",
    model_name=os.getenv("OPENROUTER_MODEL", "openai/gpt-oss-120b:free"),
    temperature=0.1,
)

target_id = 'fec6342a-0050-dea7ae33'
question = "ما هو شروط التدريب الصيفي في كلية الحاسبات والذكاء الاصطناعي قسم برنامج إنترنت الأشياء وتحليل البيانات الضخمة"
intent = understand_query(question, llm=llm)

print(f"Target ID: {target_id}")
print(f"Original query: {question}")
print(f"Intent program: {intent.program}, intent: {intent.intent}")

# 1. Dense retrieval
print("\n--- 1. Dense Retrieval ---")
dense_res = dense_retrieve(
    query=intent.clean_query,
    collection=collection,
    embeddings=embeddings,
    top_k=50,
    where_filter={"program": {"$in": ["computer science", "general"]}},
    max_distance=1.5
)
dense_ids = [r["id"] for r in dense_res]
if target_id in dense_ids:
    idx = dense_ids.index(target_id)
    print(f"Target found in Dense! Rank: {idx+1}/{len(dense_res)}, Distance: {dense_res[idx]['distance']:.4f}, Score: {dense_res[idx]['score']:.4f}")
else:
    print("Target NOT found in Dense results.")

# 2. BM25 retrieval
print("\n--- 2. BM25 Retrieval ---")
norm_query_expanded = intent.normalized_query
sparse_res = _dual_bm25_retrieve(
    clean_query=intent.clean_query,
    normalized_query=norm_query_expanded,
    bm25_index=bm25_idx,
    top_k=50
)
sparse_ids = [r["id"] for r in sparse_res]
if target_id in sparse_ids:
    idx = sparse_ids.index(target_id)
    print(f"Target found in Sparse! Rank: {idx+1}/{len(sparse_res)}, BM25 Score: {sparse_res[idx]['score']:.4f}")
else:
    print("Target NOT found in Sparse results.")

# 3. RRF Fusion
print("\n--- 3. RRF Fusion ---")
if dense_res and sparse_res:
    fused = reciprocal_rank_fusion([dense_res, sparse_res], k=35)
    fused_ids = [r["id"] for r in fused]
    if target_id in fused_ids:
        idx = fused_ids.index(target_id)
        print(f"Target found in RRF Fused! Rank: {idx+1}/{len(fused)}, RRF Score: {fused[idx]['rrf_score']:.6f}")
    else:
        print("Target NOT found in RRF Fused.")

# 4. Run full hybrid search
print("\n--- 4. Full Hybrid Search results ---")
output = hybrid_search(
    query=intent.clean_query,
    collection=collection,
    embeddings=embeddings,
    bm25_index=bm25_idx,
    top_k=20,
    dense_candidates=50,
    sparse_candidates=50,
    use_rrf=True,
    use_query_understanding=True,
    use_multi_query=True,
    use_section_boost=True,
    query_intent=intent,
    llm=llm,
)
results = output["results"]
res_ids = [r["id"] for r in results]
if target_id in res_ids:
    idx = res_ids.index(target_id)
    print(f"Target found in final hybrid results! Rank: {idx+1}/{len(results)}, Score: {results[idx].get('boosted_score'):.4f}")
else:
    print("Target NOT found in final hybrid results.")
    # Print what ranks were actually returned
    print("Final result IDs:")
    for i, r in enumerate(results[:10]):
        print(f"Rank {i+1}: {r['id']} (Page {r['metadata'].get('page')}, Score {r.get('boosted_score'):.4f})")
