import sys
import io
import os

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# Mock print or configure logger to show what is happening
sys.path.append(os.getcwd())
from chat_cli import RAGSession

session = RAGSession()

queries = [
    "ما هي شروط الالتحاق وقواعد القبول في برنامج اللغة الإنجليزية والترجمة التخصصية؟",
    "اسأله عن برنامج اللغة الإنجليزية والترجمة التخصصية",
    "ما هو نظام الدراسة في برنامج اللغة الإنجليزية والترجمة؟"
]

for q in queries:
    print("=" * 60)
    print("Query:", q)
    route, meta = session._route_query(q)
    print("Route:", route)
    print("Metadata:", meta)
