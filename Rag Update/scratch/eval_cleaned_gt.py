# -*- coding: utf-8 -*-
"""
eval_cleaned_gt.py
==================
يشغّل الأسئلة الـ 15 من ground_truth_cleaned.json على الـ RAG الكامل
ويحسب ثلاثة مقاييس:
  1. Exact Match          — هل الإجابة مطابقة تماماً للمرجع؟  (نادر، للمقارنة)
  2. Factual Keyword Match — هل توجد الكلمات المفتاحية الفعلية في الإجابة؟
  3. Token F1             — دقة ولا-محدودية على مستوى الكلمات (أسلوب SQuAD)

الإخراج:
  - طباعة تفصيلية لكل سؤال
  - ملف eval_results_cleaned.txt  (نص)
  - ملف eval_results_cleaned.json (JSON للتحليل)
"""

import sys, io, os, time, json, re, math
from pathlib import Path
from collections import Counter

# ── UTF-8 output ──────────────────────────────────────────────────────────────
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

# ── Project root ──────────────────────────────────────────────────────────────
_HERE = Path(__file__).resolve().parent.parent   # .../Rag Update/Rag Update
_SCRATCH = Path(__file__).resolve().parent
if str(_HERE) not in sys.path:
    sys.path.insert(0, str(_HERE))

from dotenv import load_dotenv
load_dotenv(dotenv_path=_HERE / ".env")


# ═══════════════════════════════════════════════════════════════════
#  METRIC HELPERS
# ═══════════════════════════════════════════════════════════════════

def _normalize(text: str) -> str:
    """Lowercase, remove punctuation, normalise Arabic whitespace."""
    text = text.lower().strip()
    # Remove common Arabic diacritics
    text = re.sub(r"[\u064B-\u065F\u0670]", "", text)
    # Unify Arabic alef variants
    text = re.sub(r"[أإآا]", "ا", text)
    # Remove punctuation (keep numbers and letters)
    text = re.sub(r"[^\w\s\u0600-\u06FF]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def exact_match(prediction: str, reference: str) -> int:
    """1 if normalised strings are identical, else 0."""
    return int(_normalize(prediction) == _normalize(reference))


def token_f1(prediction: str, reference: str) -> float:
    """
    Token-level F1 (SQuAD-style).
    Measures overlap of word tokens between prediction and reference.
    """
    pred_tokens = _normalize(prediction).split()
    ref_tokens  = _normalize(reference).split()

    if not pred_tokens or not ref_tokens:
        return 0.0

    common   = Counter(pred_tokens) & Counter(ref_tokens)
    n_common = sum(common.values())

    if n_common == 0:
        return 0.0

    precision = n_common / len(pred_tokens)
    recall    = n_common / len(ref_tokens)
    f1        = 2 * precision * recall / (precision + recall)
    return round(f1, 4)


def keyword_match(prediction: str, keywords: list[str]) -> dict:
    """
    Checks whether each expected keyword appears in the prediction.
    Returns:
      found     : list of matched keywords
      missing   : list of missing keywords
      score     : fraction found (0.0 – 1.0)
    """
    pred_lower = prediction.lower()
    found, missing = [], []
    for kw in keywords:
        if kw.lower() in pred_lower:
            found.append(kw)
        else:
            missing.append(kw)
    score = len(found) / len(keywords) if keywords else 1.0
    return {"found": found, "missing": missing, "score": round(score, 4)}


def grade_keyword_score(score: float) -> str:
    if score >= 0.80: return "✅ ممتاز"
    if score >= 0.60: return "🟡 جيد"
    if score >= 0.40: return "🟠 مقبول"
    return "❌ ضعيف"


def grade_f1(f1: float) -> str:
    if f1 >= 0.50: return "✅ ممتاز"
    if f1 >= 0.30: return "🟡 جيد"
    if f1 >= 0.15: return "🟠 مقبول"
    return "❌ ضعيف"


# ═══════════════════════════════════════════════════════════════════
#  LOAD GROUND TRUTH
# ═══════════════════════════════════════════════════════════════════

GT_FILE = _SCRATCH / "ground_truth_cleaned.json"
with open(GT_FILE, encoding="utf-8") as f:
    gt_data = json.load(f)

questions = gt_data["questions"]
print(f"\n📋 تحميل {len(questions)} سؤال من {GT_FILE.name}\n")


# ═══════════════════════════════════════════════════════════════════
#  INITIALISE RAG SESSION
# ═══════════════════════════════════════════════════════════════════

print("=" * 70)
print("  Cleaned Ground Truth Evaluation  |  Model: openai/gpt-oss-120b:free")
print("=" * 70)
print("\nInitialising RAG session …\n")
sys.stdout.flush()

from chat_cli import RAGSession
session = RAGSession(top_k=8, rerank_method="cosine", show_debug=False)


# ═══════════════════════════════════════════════════════════════════
#  RUN EVALUATION
# ═══════════════════════════════════════════════════════════════════

OUTPUT_TXT  = _HERE / "eval_results_cleaned.txt"
OUTPUT_JSON = _HERE / "eval_results_cleaned.json"

all_results = []
divider = "─" * 70

with open(OUTPUT_TXT, "w", encoding="utf-8") as fout:

    def write(text: str):
        fout.write(text)
        sys.stdout.write(text)
        sys.stdout.flush()

    header = (
        "=" * 70 + "\n"
        f"  Cleaned Ground Truth Evaluation — {len(questions)} Questions\n"
        f"  Model : openai/gpt-oss-120b:free\n"
        f"  Date  : {time.strftime('%Y-%m-%d %H:%M:%S')}\n"
        + "=" * 70 + "\n\n"
    )
    write(header)

    for idx, item in enumerate(questions, 1):
        qid       = item["id"]
        question  = item["question"]
        reference = item.get("reference_answer", "")
        keywords  = item.get("expected_keywords", [])

        sys.stderr.write(f"[{idx:02d}/{len(questions)}] {qid}: {question[:60]}…\n")
        sys.stderr.flush()
        t0 = time.time()

        # ── Run RAG ───────────────────────────────────────────────────────────
        try:
            session.session_context = {
                "last_faculty": None,
                "last_intent":  None,
                "last_query":   None,
            }
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

        # ── Compute metrics ───────────────────────────────────────────────────
        em   = exact_match(answer, reference) if reference else 0
        f1   = token_f1(answer, reference) if reference else 0.0
        km   = keyword_match(answer, keywords)

        rec = {
            "id":            qid,
            "question":      question,
            "status":        status,
            "elapsed_ms":    round(elapsed),
            "answer":        answer,
            "reference":     reference,
            "exact_match":   em,
            "token_f1":      f1,
            "keyword_score": km["score"],
            "keywords_found": km["found"],
            "keywords_missing": km["missing"],
            "sources":       sources,
        }
        all_results.append(rec)

        # ── Print block ───────────────────────────────────────────────────────
        block = (
            divider + "\n"
            f"[{qid}]  {question}\n"
            f"الزمن   : {elapsed:.0f} ms  |  المصادر: {', '.join(sources) or 'لا توجد'}\n\n"
            f"══ الإجابة الفعلية:\n{answer}\n\n"
            f"══ المرجع:\n{reference}\n\n"
            f"══ المقاييس:\n"
            f"   • Exact Match      : {'✅ نعم' if em else '❌ لا'}\n"
            f"   • Token F1         : {f1:.4f}  {grade_f1(f1)}\n"
            f"   • Keyword Match    : {km['score']:.2%}  {grade_keyword_score(km['score'])}\n"
            f"     ✓ موجودة : {km['found']}\n"
            f"     ✗ مفقودة : {km['missing']}\n\n"
        )
        write(block)

        sys.stderr.write(
            f"      EM={em}  F1={f1:.3f}  KM={km['score']:.0%}  "
            f"{elapsed:.0f}ms  {status}\n\n"
        )
        sys.stderr.flush()
        time.sleep(0.8)   # Respect API rate limits

    # ── Aggregate summary ─────────────────────────────────────────────────────
    ok_results = [r for r in all_results if r["status"] == "OK"]
    n_ok = len(ok_results)
    n_total = len(all_results)

    avg_em  = sum(r["exact_match"]   for r in ok_results) / max(n_ok, 1)
    avg_f1  = sum(r["token_f1"]      for r in ok_results) / max(n_ok, 1)
    avg_km  = sum(r["keyword_score"] for r in ok_results) / max(n_ok, 1)
    avg_ms  = sum(r["elapsed_ms"]    for r in all_results) / max(n_total, 1)

    # Per-question breakdown table
    table_header = f"\n{'ID':<6} {'EM':<5} {'F1':>6} {'KM':>7}  {'Grade':<14}  السؤال\n" + "─" * 70
    table_rows = []
    for r in all_results:
        grade = grade_keyword_score(r["keyword_score"])
        row = (
            f"{r['id']:<6} "
            f"{'1' if r['exact_match'] else '0':<5} "
            f"{r['token_f1']:>6.3f} "
            f"{r['keyword_score']:>7.2%}  "
            f"{grade:<14}  "
            f"{r['question'][:40]}"
        )
        table_rows.append(row)

    summary = (
        "\n" + "=" * 70 + "\n"
        "  📊 EVALUATION SUMMARY — Cleaned Ground Truth (15 Questions)\n"
        + "=" * 70 + "\n\n"
        + table_header + "\n"
        + "\n".join(table_rows) + "\n"
        + "─" * 70 + "\n\n"
        f"  النتائج الإجمالية ({n_ok}/{n_total} أسئلة ناجحة):\n\n"
        f"  Exact Match (EM)       : {avg_em:.2%}\n"
        f"  Token F1               : {avg_f1:.4f}  ({avg_f1:.2%})\n"
        f"  Factual Keyword Match  : {avg_km:.2%}  {grade_keyword_score(avg_km)}\n"
        f"  متوسط زمن الإجابة      : {avg_ms:.0f} ms\n\n"
    )

    # Per-band breakdown
    bands = {
        "ممتاز  (KM ≥ 80%)": [r for r in ok_results if r["keyword_score"] >= 0.80],
        "جيد    (KM 60-79%)": [r for r in ok_results if 0.60 <= r["keyword_score"] < 0.80],
        "مقبول  (KM 40-59%)": [r for r in ok_results if 0.40 <= r["keyword_score"] < 0.60],
        "ضعيف   (KM < 40%)": [r for r in ok_results if r["keyword_score"] < 0.40],
    }
    summary += "  توزيع الدرجات (Keyword Match):\n"
    for band, items in bands.items():
        ids = [r["id"] for r in items]
        summary += f"    {band:30s} → {len(items):2d} سؤال  {ids}\n"

    summary += "\n" + "=" * 70 + "\n"
    write(summary)


# ── Save JSON results ─────────────────────────────────────────────────────────
json_output = {
    "meta": {
        "model":       "openai/gpt-oss-120b:free",
        "date":        time.strftime("%Y-%m-%d %H:%M:%S"),
        "n_questions": n_total,
        "n_ok":        n_ok,
    },
    "aggregate": {
        "exact_match_accuracy": round(avg_em, 4),
        "token_f1":             round(avg_f1, 4),
        "keyword_match_score":  round(avg_km, 4),
        "avg_latency_ms":       round(avg_ms),
    },
    "results": all_results,
}

with open(OUTPUT_JSON, "w", encoding="utf-8") as jf:
    json.dump(json_output, jf, ensure_ascii=False, indent=2)

sys.stderr.write(f"\n✅ Done.\n")
sys.stderr.write(f"   TXT  → {OUTPUT_TXT}\n")
sys.stderr.write(f"   JSON → {OUTPUT_JSON}\n")
