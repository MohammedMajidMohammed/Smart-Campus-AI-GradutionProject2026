import sys, io, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

PROJECT_ROOT = r"C:\Users\Right Click\Downloads\Telegram Desktop\Rag Update\Rag Update"
os.chdir(PROJECT_ROOT)
sys.path.insert(0, PROJECT_ROOT)

from dotenv import load_dotenv
load_dotenv('.env')

from chat_cli import RAGSession

session = RAGSession()

# Comprehensive questions about the English & Translation program
questions = [
    "ما هي رؤية برنامج اللغة الإنجليزية والترجمة التخصصية؟",
    "ما هي شروط القبول والالتحاق ببرنامج اللغة الإنجليزية والترجمة؟",
    "ما هو نظام الدراسة في برنامج الترجمة؟ وكم عدد الساعات المعتمدة للتخرج؟",
    "ما هي مواد السنة الأولى الترم الأول في برنامج اللغة الإنجليزية والترجمة؟",
    "ما هي شروط التخرج من برنامج اللغة الإنجليزية والترجمة؟",
    "كيف يتم حساب المعدل التراكمي في برنامج الترجمة؟",
    "ما هي شروط إيقاف القيد في برنامج اللغة الإنجليزية؟",
]

DIVIDER = "=" * 60

for q in questions:
    print(DIVIDER)
    print(f"Q: {q}")
    print(DIVIDER)

    result = session.get_rag_response(q)

    route    = result.get("route", "?")
    faculties = result.get("detected_faculties", [])
    stats    = result.get("retrieval_stats", {})
    prog     = stats.get("program_filter", stats.get("program", "—"))
    answer   = result.get("answer", "")
    chunks   = result.get("chunks_used", 0)

    print(f"Route: {route} | Faculties: {faculties} | Program: {prog} | Chunks: {chunks}")
    print()

    # Print answer (first 600 chars)
    print("Answer:")
    print(answer[:600])
    print()

    # Top 3 sources
    reranked = result.get("reranked", [])
    if reranked:
        print("Top Sources:")
        for i, r in enumerate(reranked[:3], 1):
            m = r.get("metadata", {})
            score = r.get("rerank_score", r.get("rrf_score", 0))
            fname = m.get("fileName", "?")
            page  = m.get("page", "?")
            prog2 = m.get("program", "?")
            print(f"  {i}. {fname} (p.{page}) [{prog2}] score={score:.3f}")
    print()
