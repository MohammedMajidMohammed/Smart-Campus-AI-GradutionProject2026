import sys
import os
from pathlib import Path
from dotenv import load_dotenv

sys.path.append(str(Path(__file__).parent.parent))
load_dotenv()

from chat_cli import RAGSession
from routes.retrieval.hybrid_search import hybrid_search, normalize_query, _build_chroma_where
from routes.retrieval.query_understanding import understand_query

session = RAGSession(top_k=20)
query = "مقررات دراسة اللغه الانجليزيه والترجمه"

print("="*60)
print(f"Query: {query}")
print("="*60)

# 1. Test Query Understanding
intent = understand_query(query)
print("Query Understanding Result:")
print(f"  Intent: {intent.intent}")
print(f"  Program: {intent.program}")
print(f"  Year: {intent.year}")
print(f"  Semester: {intent.semester}")
print(f"  Confidence: {intent.confidence}")
print(f"  Clean Query: {intent.clean_query}")
print(f"  Normalized Query: {intent.normalized_query}")
print(f"  Query Variants: {intent.query_variants}")

# 2. Test Where Clause Builder
where_clause = _build_chroma_where(intent, None)
print(f"\nWhere Clause Built: {where_clause}")

# 3. Search ChromaDB directly
print("\nDirect ChromaDB Retrieval with Where Clause:")
try:
    results = session.collection.get(where=where_clause)
    print(f"  Total matches in ChromaDB: {len(results.get('ids', []))}")
    if len(results.get('ids', [])) > 0:
        print("  Files matched:")
        files = set(meta.get('fileName') for meta in results.get('metadatas', []))
        for f in files:
            print(f"    - {f}")
except Exception as e:
    print(f"  Error: {e}")

# 4. Search using Embeddings directly
print("\nDirect Dense Search on ChromaDB (query embeddings):")
try:
    query_emb = session.embeddings.embed_query(intent.clean_query)
    print(f"  Embedding dimensions: {len(query_emb)}")
    dense_res = session.collection.query(
        query_embeddings=[query_emb],
        n_results=20,
        where=where_clause
    )
    ids = dense_res.get('ids', [[]])[0]
    distances = dense_res.get('distances', [[]])[0]
    metas = dense_res.get('metadatas', [[]])[0]
    print(f"  Dense matches found: {len(ids)}")
    for i, (id_, dist, meta) in enumerate(zip(ids, distances, metas)):
        print(f"    [{i+1}] {id_} - Dist: {dist:.4f} - Page: {meta.get('page')} - File: {meta.get('fileName')}")
except Exception as e:
    print(f"  Error: {e}")

# 5. Full hybrid search call
print("\nCalling hybrid_search:")
try:
    res = hybrid_search(
        query=query,
        collection=session.collection,
        embeddings=session.embeddings,
        bm25_index=session.bm25,
        top_k=20,
        query_intent=intent
    )
    results_list = res.get('results', [])
    print(f"  Hybrid Search returned {len(results_list)} results:")
    for i, r in enumerate(results_list):
        meta = r.get('metadata', {})
        print(f"    [{i+1}] {r.get('id')} - Score: {r.get('boosted_score', r.get('rrf_score', 0.0)):.4f} - Page: {meta.get('page')} - File: {meta.get('fileName')}")
except Exception as e:
    print(f"  Error: {e}")
