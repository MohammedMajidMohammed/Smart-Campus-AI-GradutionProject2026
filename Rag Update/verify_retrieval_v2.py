import sys
import os
from pathlib import Path
from dotenv import load_dotenv

sys.path.append(str(Path(__file__).parent))
load_dotenv()

from chat_cli import RAGSession

session = RAGSession(top_k=20) 
query = "مقررات دراسة اللغه الانجليزيه والترجمه"

# Use a safe way to print Arabic on Windows
print(f"Running query...".encode('utf-8', errors='replace').decode('utf-8'))
result = session.get_rag_response(query)

print(f"\nRetrieved Chunks: {len(result['reranked'])}")
for i, r in enumerate(result['reranked']):
    meta = r.get('metadata', {})
    print(f"  [{i+1}] Page {meta.get('page')} - Score: {r.get('rerank_score', 0):.4f} - Title: {meta.get('sectionTitle', 'N/A')}")
    if int(meta.get('page', 0)) in [15, 16, 17, 19]:
        print(f"    >> FOUND TARGET PAGE!")
        print(f"    Snippet: {r.get('text', '')[:150]}...")
