import sys
import os
from pathlib import Path
from dotenv import load_dotenv

sys.path.append(str(Path(__file__).parent.parent))
load_dotenv()

from chat_cli import RAGSession

session = RAGSession(top_k=20)
query = "مقررات دراسة اللغه الانجليزيه والترجمه"

print("="*60)
print(f"Running query: {query}")
print("="*60)

result = session.get_rag_response(query)

print("\n--- RAG Answer ---")
print(result.get("answer"))

print(f"\n--- Retrieved Chunks ({len(result.get('reranked', []))}) ---")
for i, r in enumerate(result.get('reranked', [])):
    meta = r.get('metadata', {})
    print(f"  [{i+1}] Page {meta.get('page')} - Score: {r.get('rerank_score', 0):.4f} - File: {meta.get('fileName')}")
