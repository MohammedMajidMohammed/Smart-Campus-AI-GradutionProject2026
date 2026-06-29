import sys
sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0, '.')
from chat_cli import RAGSession

session = RAGSession()

print("=== TEST: Clarify + Faculty Reply ===\n")

# Step 1: General question without faculty
r1 = session.get_rag_response("ما هو نظام الغياب")
print(f"Step 1 Route : {r1['route']}")
print(f"Step 1 Answer: {r1['answer'][:300]}")
print()

# Step 2: Student replies with just faculty name
r2 = session.get_rag_response("الحاسبات")
print(f"Step 2 Route      : {r2['route']}")
print(f"Step 2 Memory used: {r2.get('memory_used', False)}")
print(f"Step 2 Answer     :\n{r2['answer'][:500]}")
