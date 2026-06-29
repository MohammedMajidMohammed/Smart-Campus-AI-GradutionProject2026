import sys
sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0, '.')
from chat_cli import RAGSession

session = RAGSession()

questions = [
    "مواد فرقة اولي حاسبات",
    "دواعي تخرج كلية اسنان",
    "شروط النجاح ف هندسه"
]

print("=== RUNNING USER SPECIFIC TESTS ===")
for q in questions:
    print(f"\nQuestion: {q}")
    r = session.get_rag_response(q)
    print(f"Route: {r['route']}")
    print(f"Answer:\n{r['answer']}")
    print("-" * 50)
