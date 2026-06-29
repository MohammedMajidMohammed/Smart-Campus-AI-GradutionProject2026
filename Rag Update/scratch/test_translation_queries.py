import sys
import os
import io

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

from chat_cli import RAGSession

session = RAGSession(top_k=8, rerank_method="cosine", show_debug=False, citation_mode="footer")

queries = [
    "كم عدد الساعات المعتمدة اللازمة للتخرج في برنامج اللغة الإنجليزية والترجمة التخصصية؟",
    "ما هي شروط الالتحاق وقواعد القبول في برنامج اللغة الإنجليزية والترجمة التخصصية؟",
    "ما هي مستويات الدراسة الأربعة في برنامج اللغة الإنجليزية والترجمة التخصصية وما هي الساعات المحددة لكل مستوى؟"
]

for q in queries:
    print("=" * 80)
    print("Query:", q)
    res = session.get_rag_response(q)
    print("Answer:")
    print(res.get("answer"))
    print("Sources:")
    for doc in res.get("reranked", []):
        meta = doc.get("metadata", {})
        print(f"  - {meta.get('fileName')} (Page {meta.get('page')})")
