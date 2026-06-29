import sys
import io
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

from chat_cli import RAGSession

session = RAGSession(top_k=8)
import time
res = session.get_rag_response('متى أُنشئت جامعة المنوفية الأهلية؟ وما هو رقم القرار الجمهوري؟')
print("Response:", res.get("answer"))
print("\nSources:")
for doc in res.get("reranked", []):
    print(f"File: {doc.get('metadata', {}).get('fileName')}, Page: {doc.get('metadata', {}).get('page')}")
    print(f"Content: {doc.get('page_content')}")
    print("-" * 50)
