
import sys
import io
import chromadb
from routes.retrieval.hybrid_search import hybrid_search
from routes.retrieval.query_understanding import understand_query
from chat_cli import RAGSession

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

session = RAGSession(
    top_k=5,
    rerank_method="cosine",
    max_context_chars=12000,
    show_debug=False
)

def test_query(q):
    print(f"\n--- QUERY: {q} ---")
    qi = understand_query(q)
    qi.program = "physical therapy"
    
    res = hybrid_search(
        query=q,
        collection=session.collection,
        embeddings=session.embeddings,
        bm25_index=session.bm25,
        top_k=5,
        dense_candidates=80,
        sparse_candidates=80,
        use_rrf=True,
        query_intent=qi
    )
    for i, c in enumerate(res["results"][:5]):
        print(f"Rank {i+1} | Page {c['metadata'].get('page')} | Score {c.get('boosted_score', c.get('rrf_score')):.3f}")
        print(c['text'][:150].replace('\n', ' '))

test_query("ما هي لائحة كلية العلاج الطبيعي؟")
test_query("شروط التخرج ومتطلبات درجة البكالوريوس في العلاج الطبيعي")
