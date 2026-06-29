
import sys, io, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

sys.path.insert(0, '.')
from chat_cli import RAGSession

session = RAGSession(show_debug=True)

query = "ما هي مواد السنة الأولى في كلية الهندسة؟"
print(f"\nRunning query: {query}")
res = session.get_rag_response(query)
print("\n--- RESPONSE ---")
print(res["answer"])
