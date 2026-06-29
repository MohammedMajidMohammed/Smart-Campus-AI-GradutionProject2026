import sys
import os
from pathlib import Path
from dotenv import load_dotenv

sys.path.append(str(Path(__file__).parent))
load_dotenv()

from chat_cli import RAGSession

session = RAGSession(top_k=5) 
query = "مقررات دراسة اللغه الانجليزيه والترجمه"

print(f"Running query: {query}")
result = session.get_rag_response(query)

print(f"\nAnswer Preview: {result['answer'][:500]}...")

print(f"\nRetrieved Chunks: {len(result['reranked'])}")
for i, r in enumerate(result['reranked']):
    meta = r.get('metadata', {})
    print(f"  [{i+1}] {meta.get('fileName')} - Page {meta.get('page')} - Score: {r.get('rerank_score', 0):.4f}")
    if int(meta.get('page', 0)) in [15, 16, 17, 19]:
        print(f"    >> FOUND TARGET PAGE!")
