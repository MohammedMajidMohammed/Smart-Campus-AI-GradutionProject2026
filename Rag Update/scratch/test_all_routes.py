import sys
sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0, '.')
from chat_cli import RAGSession

session = RAGSession()

tests = [
    # (label, query)
    ("CLARIFY: no faculty",        "ما هو نظام الغياب"),
    ("CLARIFY reply: faculty only", "الحاسبات"),
    ("STUDY: مذاكرة",              "ازاي اذاكر الرياضيات"),
    ("STUDY: homework",            "حل مسألة في التفاضل والتكامل"),
    ("STUDY: explain subject",     "اشرحلي ميكروبيولوجيا"),
    ("STUDY: english",             "help me study for my physics exam"),
    ("NORMAL: should NOT redirect", "ما هو نظام الغياب في كلية الحاسبات"),
    ("NORMAL: regulations",        "اشرح نظام التسجيل في الجامعة"),
]

for label, q in tests:
    r = session.get_rag_response(q)
    route = r["route"]
    ans_preview = r["answer"][:120].replace("\n", " ")
    mem = r.get("memory_used", False)
    print(f"\n[{label}]")
    print(f"  Q: {q}")
    print(f"  Route: {route}  | Memory: {mem}")
    print(f"  A: {ans_preview}...")
