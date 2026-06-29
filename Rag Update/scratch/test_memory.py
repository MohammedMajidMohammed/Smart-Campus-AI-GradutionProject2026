import sys
from pathlib import Path
import re

# Mock classes to avoid loading full databases and LLMs
class MockCollection:
    def count(self):
        return 100

class MockClient:
    def get_collection(self, name):
        return MockCollection()

# Mock components needed to import RAGSession
import chromadb
from langchain_openai import ChatOpenAI

sys.path.append(str(Path(__file__).parent.parent))

# Import RAGSession
from chat_cli import RAGSession, normalize_query, detect_language

def run_test():
    # Instantiate RAGSession with mock LLM/DB
    # We patch chromadb.PersistentClient to return MockClient
    original_client = chromadb.PersistentClient
    chromadb.PersistentClient = lambda *args, **kwargs: MockClient()
    
    session = RAGSession()
    # Mock collection
    session.collection = MockCollection()
    session.embeddings = object()  # dummy
    
    # Initialize session context
    session.session_context = {
        "last_faculty": None,
        "last_query": None,
        "last_intent": None,
        "last_clarify_query": None
    }
    
    # Query 1: Explicit faculty
    q1 = "ما هو شروط التدريب الصيفي لكلية الحاسبات والذكاء الاصطناعي"
    print(f"--- Query 1: {q1} ---")
    
    # Manually simulate the first part of get_rag_response routing
    route1, route_meta1 = session._route_query(q1)
    print(f"Route: {route1}")
    print(f"Detected Faculties: {route_meta1.get('detected_faculties')}")
    print(f"Clarify Reason: {route_meta1.get('clarify_reason')}")
    print(f"General University: {route_meta1.get('general_university')}")
    
    # Update memory as get_rag_response would:
    _detected_faculties1 = route_meta1.get("detected_faculties", [])
    if _detected_faculties1:
        session.session_context["last_faculty"] = _detected_faculties1[0]
    session.session_context["last_query"] = q1
    
    print(f"Session memory (last_faculty): {session.session_context.get('last_faculty')}")
    
    # Query 2: Follow-up query with no faculty, but contains general university keyword "تسجيل"
    q2 = "متي يتم تسجيل التدريب الصيفي"
    print(f"\n--- Query 2: {q2} ---")
    
    # Let's run the routing and memory logic of get_rag_response
    query = q2
    query_norm = normalize_query(query)
    query_lang = detect_language(query_norm)
    
    route, route_meta = session._route_query(query)
    _detected_faculties = route_meta.get("detected_faculties", [])
    _clarify_reason     = route_meta.get("clarify_reason")
    
    _memory_faculty = session.session_context.get("last_faculty")
    
    print(f"Initial Route: {route}")
    print(f"Initial Clarify Reason: {_clarify_reason}")
    print(f"Initial Detected Faculties: {_detected_faculties}")
    print(f"Initial General University: {route_meta.get('general_university')}")
    
    # Existing memory logic in chat_cli.py
    _memory_used = False
    _pending_clarify = session.session_context.get("last_clarify_query")
    
    if _pending_clarify and _detected_faculties and route in ("CLARIFY", "RAG", "CATALOG"):
        pass
    elif (
        _clarify_reason == "no_faculty"
        and _memory_faculty
        and not _detected_faculties
    ):
        _augmented_query = f"{query} في {_memory_faculty}"
        _new_route, _new_meta = session._route_query(_augmented_query)
        if _new_route in ("RAG", "HYBRID", "CATALOG"):
            route              = _new_route
            route_meta         = _new_meta
            _detected_faculties = [_memory_faculty]
            _clarify_reason    = None
            _memory_used       = True
            query_norm = normalize_query(_augmented_query)
            
    print(f"\nAfter existing memory check:")
    print(f"Final Route: {route}")
    print(f"Final Detected Faculties: {_detected_faculties}")
    print(f"Final General University: {route_meta.get('general_university')}")
    print(f"Memory Used: {_memory_used}")
    print(f"Query Norm: {query_norm}")

if __name__ == "__main__":
    run_test()
