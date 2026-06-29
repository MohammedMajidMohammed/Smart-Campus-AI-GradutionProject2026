import chromadb
import sys
import os
import time
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

sys.stdout.reconfigure(encoding="utf-8")

from routes.chat import _LocalHuggingFaceEmbeddings, _get_bm25_index
from routes.retrieval.query_understanding import understand_query
from routes.retrieval.hybrid_search import hybrid_search, normalize_query
from routes.retrieval.reranker import rerank_results
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

print(f"User Question: {question}")
intent = understand_query(question, llm=llm)
print(f"Intent program: {intent.program}, year: {intent.year}, clean_query: {intent.clean_query}")

print("\n--- Running Hybrid Search ---")
t0 = time.perf_counter()
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
t1 = time.perf_counter()
print(f"Search completed in {t1 - t0:.2f} seconds.")

candidates = output["results"]
print(f"\nFound {len(candidates)} candidates.")

# Print top 15 candidates before reranking
print("\n--- Top Candidates before Reranking ---")
for i, c in enumerate(candidates[:15]):
    meta = c.get("metadata", {})
    print(f"{i+1}. Score: {c.get('rrf_score') or c.get('score'):.4f} | Page: {meta.get('page')} | File: {meta.get('fileName')}")
    print(f"   Section: {meta.get('sectionTitle')}")
    print(f"   Snippet: {c.get('text')[:200]}")
    print("-" * 40)

# Run reranking
print("\n--- Running Reranking ---")
reranked = rerank_results(
    query=intent.clean_query,
    candidates=candidates,
    embeddings=embeddings,
    top_n=5,
    original_query=question,
)

print(f"\nTop {len(reranked)} Reranked Results:")
for i, r in enumerate(reranked):
    meta = r.get("metadata", {})
    print(f"{i+1}. Rerank Score: {r.get('rerank_score'):.4f} | Page: {meta.get('page')} | File: {meta.get('fileName')}")
    print(f"   Section: {meta.get('sectionTitle')}")
    print(f"   Snippet: {r.get('text')[:300]}")
    print("-" * 40)
