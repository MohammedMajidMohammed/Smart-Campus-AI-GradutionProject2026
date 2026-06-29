import sys
import io
import time
from chat_cli import RAGSession

# Fix terminal encoding for Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def test_failed():
    session = RAGSession(
        top_k=5,
        rerank_method="cosine",
        max_context_chars=12000,
        show_debug=False
    )
    
    test_cases = [
        {
            "faculty": "الهندسة (Engineering)",
            "query": "ما هي مواد السنة الأولى في كلية الهندسة؟",
            "expected_program": "engineering",
        },
        {
            "faculty": "الصيدلة (Pharmacy)",
            "query": "ما هي لائحة كلية الصيدلة؟",
            "expected_program": "pharmacy",
        },
        {
            "faculty": "الطب البشري (Medicine)",
            "query": "ما هي لائحة كلية الطب البشري؟",
            "expected_program": "medicine",
        },
        {
            "faculty": "الطب البيطري (Veterinary)",
            "query": "ما هي لائحة كلية الطب البيطري؟",
            "expected_program": "veterinary",
        }
    ]
    
    for i, tc in enumerate(test_cases):
        print(f"\n==================================================")
        print(f"TESTING FACULTY: {tc['faculty']}")
        print(f"QUERY: {tc['query']}")
        print(f"==================================================")
        
        try:
            res = session.get_rag_response(tc['query'])
            answer = res.get("answer", "").strip()
            print(f"ANSWER:\n{answer}")
            sources = res.get("reranked", [])
            source_names = [r.get("metadata", {}).get("fileName", "") for r in sources]
            print(f"SOURCES: {source_names}")
        except Exception as e:
            print(f"EXCEPTION: {e}")
            
if __name__ == "__main__":
    test_failed()
