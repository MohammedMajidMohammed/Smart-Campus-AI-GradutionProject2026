import chromadb
import sys
import os
import numpy as np
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

sys.stdout.reconfigure(encoding="utf-8")

from routes.chat import _LocalHuggingFaceEmbeddings, _get_bm25_index, _translate_query_to_arabic
from routes.retrieval.query_understanding import understand_query
from routes.retrieval.hybrid_search import hybrid_search, dense_retrieve, _dual_bm25_retrieve, reciprocal_rank_fusion
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

translated = "ما هي شروط التدريب الصيفي في كلية الحاسبات والذكاء الاصطناعي قسم برنامج إنترنت الأشياء وتحليل البيانات الضخمة؟"

print(f"Query: {translated}")

# 1. Dense retrieval
print("\n--- 1. Dense Retrieval ---")
dense_res = dense_retrieve(
    query=translated,
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
    # Print what was returned
    for i, r in enumerate(dense_res[:10]):
        print(f"Rank {i+1}: {r['id']} (Page {r['metadata'].get('page')}, Dist {r['distance']:.4f})")

# 2. BM25 retrieval
print("\n--- 2. BM25 Retrieval ---")
sparse_res = _dual_bm25_retrieve(
    clean_query=translated,
    normalized_query=translated,
    bm25_index=bm25_idx,
    top_k=50
)
sparse_ids = [r["id"] for r in sparse_res]
if target_id in sparse_ids:
    idx = sparse_ids.index(target_id)
    print(f"Target found in Sparse! Rank: {idx+1}/{len(sparse_res)}, BM25 Score: {sparse_res[idx]['score']:.4f}")
else:
    print("Target NOT found in Sparse results.")
    for i, r in enumerate(sparse_res[:10]):
        print(f"Rank {i+1}: {r['id']} (Page {r['metadata'].get('page')}, BM25 Score {r['score']:.4f})")

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
