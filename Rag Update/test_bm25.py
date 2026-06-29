import sys
import os
from pathlib import Path
from dotenv import load_dotenv

sys.path.append(str(Path(__file__).parent))
load_dotenv()

from routes.retrieval.bm25_index import get_or_build_index
from routes.upload import collection

idx = get_or_build_index('university_regulations', collection)
query = 'الترجمة'
print(f"BM25 Query: {query}")
res = idx.query(query, top_k=10)

for i, r in enumerate(res):
    meta = r.get('metadata', {})
    print(f"  [{i+1}] Page {meta.get('page')} - Filename: {meta.get('fileName')} - Score: {r.get('score', 0):.4f}")
    print(f"      Text: {r.get('text', '')[:100]}...")
