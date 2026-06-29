import sys
from pathlib import Path
from routes.chat import _get_bm25_index

sys.stdout.reconfigure(encoding="utf-8")

bm25_idx = _get_bm25_index()
if bm25_idx is None or not bm25_idx.is_built:
    print("BM25 index not loaded/built.")
    sys.exit(1)

print("BM25 index total documents:", bm25_idx.doc_count)

doc_id = 'fec6342a-0050-dea7ae33'

if doc_id in bm25_idx.corpus_ids:
    idx = bm25_idx.corpus_ids.index(doc_id)
    doc_tokens = bm25_idx._tokenized_corpus[idx]
    print(f"\nDocument {doc_id} tokens in BM25 corpus:")
    print(doc_tokens[:100])
else:
    print(f"\nDocument {doc_id} NOT found in BM25 index corpus_ids!")
    matches = [d for d in bm25_idx.corpus_ids if d.startswith('fec6342a')]
    print(f"Any matches starting with 'fec6342a': {len(matches)} matches")
    if matches:
        print("First few match IDs:", matches[:5])

# Let's query BM25 with "الصيفي"
print("\nQuerying BM25 with 'الصيفي':")
res = bm25_idx.query("الصيفي", top_k=10)
for r in res:
    print(f"ID: {r['id']}, Score: {r['score']:.4f}")

# Let's query BM25 with "التدريب"
print("\nQuerying BM25 with 'التدريب':")
res = bm25_idx.query("التدريب", top_k=10)
for r in res:
    print(f"ID: {r['id']}, Score: {r['score']:.4f}")
