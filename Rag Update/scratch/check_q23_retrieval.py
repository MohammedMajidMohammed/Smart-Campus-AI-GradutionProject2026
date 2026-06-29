import sys
from chat_cli import RAGSession

session = RAGSession()
query = "What are the passing requirements for a course?"
result = session.get_rag_response(query)
print("ANSWER:")
print(result.get("answer"))
print("\n" + "="*50 + "\nSOURCES:")
for idx, r in enumerate(result.get("reranked", [])):
    meta = r.get("metadata", {})
    print(f"Source {idx+1}: File: {meta.get('fileName')}, Page: {meta.get('page')}, Section: {meta.get('sectionTitle')}, Program: {meta.get('program')}")
    print(r.get("text"))
    print("-" * 50)
