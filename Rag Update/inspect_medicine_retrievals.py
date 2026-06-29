
import sys
import io
import chromadb
from routes.retrieval.hybrid_search import hybrid_search
from chat_cli import RAGSession

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

session = RAGSession(
    top_k=5,
    rerank_method="cosine",
    max_context_chars=12000,
    show_debug=False
)

res = session.get_rag_response("ما هي لائحة كلية الطب البشري؟")
print("=== MEDICINE RESPONSE ===")
print("Answer:", res.get("answer"))
print("\n=== RETRIEVED CHUNKS ===")
for i, r in enumerate(res.get("reranked", [])[:5]):
    print(f"\nChunk {i+1}:")
    print(f"  File: {r.get('metadata', {}).get('fileName')}")
    print(f"  Page: {r.get('metadata', {}).get('page')}")
    print(f"  Program: {r.get('metadata', {}).get('program')}")
    print(f"  Text preview: {r.get('text', '')[:300].replace('\n', ' ')}")
