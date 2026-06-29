"""
run_accuracy_test.py
====================
Tests all questions and reports accuracy.
Usage: venv/Scripts/python.exe run_accuracy_test.py
"""
import json, sys, os, time
from pathlib import Path

os.chdir(Path(__file__).parent)
sys.path.insert(0, str(Path(__file__).parent))
sys.stderr = open(os.devnull, 'w')

from dotenv import load_dotenv
load_dotenv()

with open("test_questions.json", encoding="utf-8") as f:
    data = json.load(f)

expected = data.get("expected_answers", {})

all_questions = (
    [(q, "arabic")  for q in data["arabic_questions"]] +
    [(q, "english") for q in data["english_questions"]] +
    [(q, "complex") for q in data["complex_questions"]]
)

from chat_cli import RAGSession as RAGChatCLI
cli = RAGChatCLI()

_NOT_FOUND = [
    "المعلومات غير موجودة", "غير متوفرة", "لا تتوفر", "لم أجد",
    "Information not found", "not available", "not found", "no information",
    "CLARIFY", "سؤالك يحتاج", "Please specify", "تحديد الكلية",
    "عذرا، هذه المعلومة غير متوفرة", "Sorry, this information is not available",
]

def is_answered(answer: str) -> bool:
    return not any(m.lower() in answer.lower() for m in _NOT_FOUND)

def check_expected(question: str, answer: str) -> bool:
    """Check if answer contains expected keywords."""
    exp = expected.get(question)
    if not exp:
        return True  # no expected answer to check
    keywords = [kw.strip() for kw in exp.split("-")]
    return any(kw.lower() in answer.lower() for kw in keywords)

print("=" * 70)
print("ACCURACY TEST REPORT")
print("=" * 70)
print(f"Total questions: {len(all_questions)}\n")

results = []
for i, (q, qtype) in enumerate(all_questions, 1):
    try:
        t0 = time.time()
        resp = cli.get_rag_response(q)
        elapsed = time.time() - t0
        answer  = resp.get("answer", "")
        route   = resp.get("route", "?")
        answered = is_answered(answer)
        correct  = check_expected(q, answer) if answered else False
        results.append({
            "q": q, "type": qtype, "answered": answered,
            "correct": correct, "route": route,
            "elapsed": round(elapsed, 1)
        })
        if answered:
            status = "OK" if correct else "PARTIAL"
            icon = "✓" if correct else "~"
        else:
            status = "FAIL"
            icon = "✗"
        print(f"[{i:2d}] {icon} [{qtype:7s}] {route:8s} | {q[:55]}")
        if not answered:
            print(f"     → {answer[:120]}")
    except Exception as e:
        results.append({"q": q, "type": qtype, "answered": False,
                        "correct": False, "route": "ERROR", "error": str(e)})
        print(f"[{i:2d}] ✗ [{qtype:7s}] ERROR    | {q[:55]}")
        print(f"     → {e}")

# Summary
print("\n" + "=" * 70)
print("SUMMARY")
print("=" * 70)

total    = len(results)
answered = sum(1 for r in results if r["answered"])
accuracy = answered / total * 100

print(f"Overall: {answered}/{total} answered = {accuracy:.1f}%\n")

for qtype in ["arabic", "english", "complex"]:
    subset = [r for r in results if r["type"] == qtype]
    ok = sum(1 for r in subset if r["answered"])
    print(f"  {qtype:10s}: {ok}/{len(subset)} = {ok/max(len(subset),1)*100:.0f}%")

failed = [r for r in results if not r["answered"]]
if failed:
    print(f"\nFailed ({len(failed)}):")
    for r in failed:
        print(f"  [{r['type']}] {r['q'][:65]}")

routes = {}
for r in results:
    routes[r.get("route","?")] = routes.get(r.get("route","?"), 0) + 1
print(f"\nRoutes: {routes}")

avg_time = sum(r.get("elapsed",0) for r in results) / max(len(results),1)
print(f"Avg response time: {avg_time:.1f}s")
print("=" * 70)
