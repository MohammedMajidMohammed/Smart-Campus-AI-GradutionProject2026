import sys
sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0, '.')
from chat_cli import RAGSession

session = RAGSession()

tests = [
    ("بدون كلية",         "ما هو نظام الغياب"),
    ("بدون كلية 2",       "كم ساعة للتخرج"),
    ("رد بالكلية",        "الصيدلة"),   # after clarify
    ("مع كلية صريحة",    "ما هو نظام الغياب في الحاسبات"),
    ("عام الجامعة",      "من هو رئيس الجامعة"),
    ("عام الجامعة 2",    "اشرح نظام التسجيل في الجامعة"),
    ("مذاكرة",           "ازاي اذاكر الرياضيات"),
    ("مذاكرة 2",         "اشرحلي الجبر الخطي"),
    ("catalog مع كلية",  "مواد الفرقة الاولى حاسبات"),
]

print()
for label, q in tests:
    r = session.get_rag_response(q)
    route = r["route"]
    ans   = r["answer"][:90].replace("\n"," ")
    mem   = "✓mem" if r.get("memory_used") else ""
    print(f"[{label:20s}] Route={route:15s} {mem}")
    print(f"  Q: {q}")
    print(f"  A: {ans}")
    print()
