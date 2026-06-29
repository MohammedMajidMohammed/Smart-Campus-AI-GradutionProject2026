import chromadb
import sys
import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

sys.stdout.reconfigure(encoding="utf-8")

from routes.chat import _LocalHuggingFaceEmbeddings, _get_bm25_index, _translate_query_to_arabic, detect_language
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

question = "ما هو شروط التدريب الصيفي في كلية الحاسبات والذكاء الاصطناعي قسم برنامج إنترنت الأشياء وتحليل البيانات الضخمة"
intent = understand_query(question, llm=llm)

query_normalized = intent.clean_query
query_language = detect_language(query_normalized)

print(f"Original question: {question}")
print(f"Clean query: {query_normalized}")
print(f"Detected language of clean query: {query_language}")

# Translate to Arabic
translated = _translate_query_to_arabic(query_normalized, query_language=query_language)
print(f"Translated query: {translated}")

# Now let's calculate similarity of chunk 50 to the translated query!
target_id = 'fec6342a-0050-dea7ae33'
res = collection.get(
    ids=[target_id],
    include=["embeddings", "documents", "metadatas"]
)
if not res.get("documents"):
    print("Target chunk 50 not found in DB!")
    sys.exit(1)

chunk_emb = res["embeddings"][0]
import numpy as np
t_emb = embeddings.embed_query(translated)
dist = np.sum((np.array(t_emb) - np.array(chunk_emb)) ** 2)
cos_sim = 1.0 - 0.5 * dist
print(f"\nSimilarity to translated query:")
print(f"  L2 Distance: {dist:.4f}")
print(f"  Cosine Similarity: {cos_sim:.4f}")

# What if we run the hybrid search with the translated query?
print("\n--- Running Hybrid Search with Translated Query ---")
output = hybrid_search(
    query=translated,
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
    print(f"Target found! Rank: {idx+1}/{len(results)}, Score: {results[idx].get('boosted_score'):.4f}")
else:
    print("Target NOT found in final results.")
    for i, r in enumerate(results[:10]):
        print(f"Rank {i+1}: {r['id']} (Page {r['metadata'].get('page')}, Score {r.get('boosted_score'):.4f})")
