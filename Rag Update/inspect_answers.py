
import sys
import io
from chat_cli import RAGSession

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

session = RAGSession(
    top_k=5,
    rerank_method="cosine",
    max_context_chars=12000,
    show_debug=False
)

for faculty, query in [
    ("Pharmacy", "ما هي لائحة كلية الصيدلة؟"),
    ("Medicine", "ما هي لائحة كلية الطب البشري؟"),
    ("Physical Therapy", "ما هي لائحة كلية العلاج الطبيعي؟")
]:
    res = session.get_rag_response(query)
    print(f"\n==========================================")
    print(f"FACULTY: {faculty}")
    print(f"QUERY: {query}")
    print(f"ANSWER:\n{res.get('answer')}")
