# -*- coding: utf-8 -*-
"""
run_ground_truth_test.py  v2
============================
يشغّل الـ 30 سؤال من Ground Truth Test Set على الـ RAG الكامل
(chat_cli.RAGSession.get_rag_response) ويسجّل الإجابات في model_answers.txt
"""

import sys, io, os, time
from pathlib import Path

# ── UTF-8 output ──────────────────────────────────────────────────────────────
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

# ── Project root ──────────────────────────────────────────────────────────────
_HERE = Path(__file__).resolve().parent.parent   # .../Rag Update/Rag Update
if str(_HERE) not in sys.path:
    sys.path.insert(0, str(_HERE))

from dotenv import load_dotenv
load_dotenv(dotenv_path=_HERE / ".env")

# ─── الـ 30 سؤال ──────────────────────────────────────────────────────────────
QUESTIONS = [
    # ── 1-8: أسئلة على الكليات (من regulations_test_report) ──────────────
    ("Q01", "ما هي مواد السنة الأولى في كلية الهندسة؟"),
    ("Q02", "ما هي لائحة كلية الصيدلة؟"),
    ("Q03", "ما هي لائحة كلية العلاج الطبيعي؟"),
    ("Q04", "ما هي لائحة كلية الحاسبات؟"),
    ("Q05", "ما هي لائحة كلية الطب البشري؟"),
    ("Q06", "ما شروط التخرج في طب الأسنان؟"),
    ("Q07", "ما هي لائحة برنامج اللغة الإنجليزية والترجمة؟"),
    ("Q08", "ما هي لائحة كلية الطب البيطري؟"),
    # ── 9-20: أسئلة عربية عامة ───────────────────────────────────────────
    ("Q09",  "ما هي شروط القبول في الجامعة؟"),
    ("Q10",  "كم عدد الساعات المعتمدة المطلوبة للتخرج؟"),
    ("Q11",  "ما هي شروط النجاح في المادة؟"),
    ("Q12",  "ما هي نسبة الحضور المطلوبة؟"),
    ("Q13",  "كيف يمكنني التقدم لامتحان تعويضي؟"),
    ("Q14",  "ما هي متطلبات التخرج من كلية العلاج الطبيعي؟"),
    ("Q15",  "ما هي المواد الإجبارية في برنامج التمريض؟"),
    ("Q16",  "ما هي إجراءات الانسحاب من المادة؟"),
    ("Q17",  "كم عدد ساعات التدريب العملي المطلوبة في التمريض؟"),
    ("Q18",  "ما هي متطلبات التخرج من كلية التمريض؟"),
    ("Q19",  "ما هي جميع الخطوات المطلوبة للتسجيل في الفصل الدراسي الجديد؟"),
    ("Q20",  "ما الفرق بين متطلبات التمريض والعلاج الطبيعي؟"),
    # ── 21-30: أسئلة إنجليزية ────────────────────────────────────────────
    ("Q21",  "What are the admission requirements?"),
    ("Q22",  "How many credit hours are required for graduation?"),
    ("Q23",  "What are the passing requirements for a course?"),
    ("Q24",  "What is the required attendance percentage?"),
    ("Q25",  "How can I apply for a make-up exam?"),
    ("Q26",  "What are the graduation requirements for Physical Therapy?"),
    ("Q27",  "What are the mandatory courses in the Nursing program?"),
    ("Q28",  "What are the withdrawal procedures from a course?"),
    ("Q29",  "What is the complete process for applying to graduate?"),
    ("Q30",  "What are the differences between Nursing and Physical Therapy requirements?"),
]

# ─── تحميل الـ RAGSession ────────────────────────────────────────────────────
print("=" * 70)
print("  Ground Truth Test — 30 Questions  |  Model: openai/gpt-oss-120b:free")
print("=" * 70)
print("\nInitialising RAG session …\n")
sys.stdout.flush()

from chat_cli import RAGSession
session = RAGSession(top_k=8, rerank_method="cosine")

# ─── تشغيل الأسئلة وكتابة النتائج ────────────────────────────────────────────
OUTPUT_FILE = _HERE / "model_answers.txt"
results = []

with open(OUTPUT_FILE, "w", encoding="utf-8") as fout:
    def write(text):
        """Write to both file and stdout without duplication."""
        fout.write(text)
        sys.stdout.write(text)
        sys.stdout.flush()

    write(
        "=" * 70 + "\n"
        f"  Ground Truth Test — 30 Questions\n"
        f"  Model : openai/gpt-oss-120b:free\n"
        f"  Date  : {time.strftime('%Y-%m-%d %H:%M:%S')}\n"
        + "=" * 70 + "\n\n"
    )

    for i, (qid, question) in enumerate(QUESTIONS, 1):
        sys.stderr.write(f"[{i:02d}/30] {qid}: {question[:55]}…\n")
        sys.stderr.flush()
        t0 = time.time()

        try:
            result  = session.get_rag_response(question)
            answer  = result.get("answer", "NO ANSWER")
            elapsed = result.get("elapsed_ms", (time.time() - t0) * 1000)
            sources = [
                r.get("metadata", {}).get("fileName", "?")
                for r in result.get("reranked", [])[:3]
            ]
            status = "OK"
        except Exception as e:
            answer  = f"ERROR: {e}"
            elapsed = (time.time() - t0) * 1000
            sources = []
            status  = "ERROR"

        block = (
            "─" * 70 + "\n"
            f"[{qid}] السؤال: {question}\n"
            f"الحالة  : {status}  |  الزمن: {elapsed:.0f} ms\n"
            f"المصادر : {', '.join(sources) if sources else 'لا توجد'}\n\n"
            f"الإجابة:\n{answer}\n\n"
        )
        write(block)

        sys.stderr.write(f"      ✓ {elapsed:.0f} ms — {status}\n\n")
        sys.stderr.flush()

        results.append({
            "id": qid, "question": question,
            "status": status, "elapsed_ms": round(elapsed),
            "answer_length": len(answer),
        })

        time.sleep(0.8)

    ok_count = sum(1 for r in results if r["status"] == "OK")
    avg_ms   = sum(r["elapsed_ms"] for r in results) / max(len(results), 1)
    write(
        "\n" + "=" * 70 + "\n"
        f"  SUMMARY\n"
        f"  Total   : {len(results)} questions\n"
        f"  Success : {ok_count} / {len(results)}\n"
        f"  Avg Time: {avg_ms:.0f} ms\n"
        + "=" * 70 + "\n"
    )

sys.stderr.write(f"\nDone. Results saved to: {OUTPUT_FILE}\n")
