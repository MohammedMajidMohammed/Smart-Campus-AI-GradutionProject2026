import sys
sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0, '.')
from chat_cli import RAGSession

session = RAGSession()

# Call hybrid_search directly to see what chunks come back
from routes.retrieval.hybrid_search import hybrid_search

output = hybrid_search(
    query="من هو رئيس الجامعة",
    collection=session.collection,
    embeddings=session.embeddings,
    bm25_index=session.bm25,
    llm=session.llm,
    top_k=8,
    dense_candidates=80,
    sparse_candidates=80,
)

results = output.get('results', [])
print(f"\nTop {len(results)} results:")
for i, r in enumerate(results, 1):
    meta = r.get('metadata', {})
    text = r.get('text', '')
    score = r.get('boosted_score', r.get('rrf_score', 0))
    president_hit = "القاصد" in text or "رييس جامعة" in text or "رئيس جامعة" in text
    marker = " *** PRESIDENT FOUND ***" if president_hit else ""
    print(f"\n[{i}]{marker} {meta.get('fileName','?')} (page {meta.get('page','?')}) | program={meta.get('program','?')} | score={score:.4f}")
    print(f"    {text[:200].replace(chr(10),' ')}")

