
import sys
import io
import time
from pathlib import Path

# Add current dir to sys.path
sys.path.append(str(Path(__file__).parent))

# Fix terminal encoding for Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

from chat_cli import RAGSession

def test_queries():
    session = RAGSession(
        top_k=5,
        rerank_method="cosine",
        max_context_chars=4000,
        show_debug=False
    )
    
    queries = [
        "ما هي مواد السنة الأولى في كلية الهندسة؟",
        "ما شروط التخرج في طب الأسنان؟",
        "ما هي لائحة كلية الطب؟"
    ]
    
    for i, q in enumerate(queries):
        if i > 0:
            print("Waiting 10 seconds to avoid API rate limits...")
            time.sleep(10)
        print(f"\n{'='*50}")
        print(f"QUERY: {q}")
        print(f"{'='*50}")
        
        result = session.get_rag_response(q)
        print(f"\nANSWER:\n{result['answer']}")
        
        sources = result.get('reranked', [])
        if sources:
            print(f"\nSOURCES ({len(sources)}):")
            for j, r in enumerate(sources[:3]):
                meta = r.get('metadata', {})
                print(f"  {j+1}. {meta.get('fileName')} (page {meta.get('page')}) - Program: {meta.get('program')}")
        print("\n")

if __name__ == "__main__":
    test_queries()
