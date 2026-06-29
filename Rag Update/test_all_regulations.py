
import os
os.environ["HF_HUB_OFFLINE"] = "1"
os.environ["TRANSFORMERS_OFFLINE"] = "1"

import sys
import io
import time
import json
from chat_cli import RAGSession
from routes.retrieval.query_understanding import understand_query

# Fix terminal encoding for Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def test_all():
    session = RAGSession(
        top_k=5,
        rerank_method="cosine",
        max_context_chars=12000,
        show_debug=False
    )
    
    # Test cases mapping Arabic queries to expected programs and filenames
    test_cases = [
        {
            "faculty": "الهندسة (Engineering)",
            "query": "ما هي مواد السنة الأولى في كلية الهندسة؟",
            "expected_program": "engineering",
            "expected_file_part": "هندسه"
        },
        {
            "faculty": "الصيدلة (Pharmacy)",
            "query": "ما هي لائحة كلية الصيدلة؟",
            "expected_program": "pharmacy",
            "expected_file_part": "دليل صيدلة"
        },
        {
            "faculty": "العلاج الطبيعي (Physical Therapy)",
            "query": "ما هي لائحة كلية العلاج الطبيعي؟",
            "expected_program": "physical therapy",
            "expected_file_part": "علاج_طبيعي"
        },
        {
            "faculty": "الحاسبات والذكاء الاصطناعي (Computer Science)",
            "query": "ما هي لائحة كلية الحاسبات؟",
            "expected_program": "computer science",
            "expected_file_part": "الحاسوب"
        },
        {
            "faculty": "الطب البشري (Medicine)",
            "query": "ما هي لائحة كلية الطب البشري؟",
            "expected_program": "medicine",
            "expected_file_part": "طب وجراحه"
        },
        {
            "faculty": "طب الأسنان (Dentistry)",
            "query": "ما شروط التخرج في طب الأسنان؟",
            "expected_program": "dentistry",
            "expected_file_part": "الفم والاسنان"
        },
        {
            "faculty": "الألسن واللغات (Arts/Translation)",
            "query": "ما هي لائحة برنامج اللغة الإنجليزية والترجمة؟",
            "expected_program": "arts",
            "expected_file_part": "الترجمة"
        },
        {
            "faculty": "الطب البيطري (Veterinary)",
            "query": "ما هي لائحة كلية الطب البيطري؟",
            "expected_program": "veterinary",
            "expected_file_part": "بيطري"
        }
    ]
    
    results = []
    
    for i, tc in enumerate(test_cases):
        if i > 0:
            print("\nWaiting 12 seconds to respect API rate limits...")
            time.sleep(12)
            
        print(f"\n==================================================")
        print(f"TESTING FACULTY: {tc['faculty']}")
        print(f"QUERY: {tc['query']}")
        print(f"==================================================")
        
        # Run system understanding
        q_under = understand_query(tc['query'], llm=session.llm)
        detected_prog = q_under.program
        intent = q_under.intent
        print(f"DEBUG: Detected Program: '{detected_prog}' (Expected: '{tc['expected_program']}')")
        print(f"DEBUG: Detected Intent: '{intent}'")
        
        # Run full pipeline
        res = session.get_rag_response(tc['query'])
        answer = res.get("answer", "").strip()
        print(f"ANSWER:\n{answer}")
        
        # Check source documents
        sources = res.get("reranked", [])
        source_names = [r.get("metadata", {}).get("fileName", "") for r in sources]
        print(f"SOURCES RETRIEVED: {source_names}")
        
        # Verify correctness
        prog_ok = (detected_prog == tc['expected_program'])
        ans_exists = len(answer) > 0 and "المعلومات غير موجودة" not in answer
        citation_ok = any(tc['expected_file_part'] in name for name in source_names)
        
        status = "PASSED" if (prog_ok and ans_exists and citation_ok) else "FAILED"
        
        test_res = {
            "faculty": tc['faculty'],
            "query": tc['query'],
            "detected_program": detected_prog,
            "expected_program": tc['expected_program'],
            "program_match": prog_ok,
            "answer_length": len(answer),
            "answer_valid": ans_exists,
            "citation_ok": citation_ok,
            "status": status,
            "sources": source_names
        }
        results.append(test_res)
        
        print(f"STATUS: {status} (Prog Match: {prog_ok}, Ans Valid: {ans_exists}, Citation OK: {citation_ok})")
        
    print("\n\n" + "="*50)
    print("FINAL TEST REPORT")
    print("="*50)
    passed_count = sum(1 for r in results if r["status"] == "PASSED")
    print(f"Passed: {passed_count}/{len(results)}")
    
    with open("regulations_test_report.json", "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
        
    print("Test report saved to regulations_test_report.json")

if __name__ == "__main__":
    test_all()
