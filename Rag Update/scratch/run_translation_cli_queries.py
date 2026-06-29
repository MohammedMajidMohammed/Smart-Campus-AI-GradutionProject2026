import sys
import io
import os

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

sys.path.append(os.getcwd())
from chat_cli import RAGSession

session = RAGSession()

queries = [
    "ما هي شروط الالتحاق وقواعد القبول في برنامج اللغة الإنجليزية والترجمة التخصصية؟",
    "كم عدد الساعات المعتمدة المطلوبة للتخرج في برنامج اللغة الإنجليزية والترجمة التخصصية؟"
]

for q in queries:
    print("=" * 60)
    print("Query:", q)
    result = session.get_rag_response(q)
    print("Answer:")
    print(result.get("answer"))
    print("Sources:")
    for r in result.get("reranked", [])[:3]:
        print(f"  - {r.get('fileName')} (Page {r.get('page')}) (Score: {r.get('rerank_score', 0.0):.4f})")
