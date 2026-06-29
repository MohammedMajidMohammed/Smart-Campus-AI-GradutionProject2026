# eval_arabic_retrieval.py
"""Evaluation script for Arabic RAG retrieval.
Generates a detailed human‑readable text report (evaluation_report.txt)
and a structured JSON report (evaluation_report.json).
"""

import json, os, re, sys
from pathlib import Path

# Ensure project root is on sys.path (same logic as chat_cli)
HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

from chat_cli import RAGSession
from routes.arabic_cleaner import detect_language

# Load Arabic questions from test_questions.json
QUESTIONS_PATH = HERE / "test_questions.json"
with open(QUESTIONS_PATH, "r", encoding="utf-8") as f:
    data = json.load(f)
questions = data.get("arabic_questions", [])

session = RAGSession()

# Faculty keywords mapping (same as in chat_cli)
FACULTY_MAP = {
    "computer science": ["حاسبات", "حاسب", "حاسوب", "كمبيوتر", "computer", "cs", "it"],
    "veterinary": ["طب بيطري", "الطب البيطري", "بيطري"],
    "physical therapy": ["علاج طبيعي", "العلاج الطبيعي", "physio"],
    "dentistry": ["أسنان", "اسنان", "dent"],
    "medicine": ["طب", "طبية", "medicine", "medical"],
    "pharmacy": ["صيدلة", "pharmacy"],
    "nursing": ["تمريض", "nursing"],
    "engineering": ["هندسة", "هندسه", "engineering"],
    "law": ["حقوق", "قانون", "law"],
    "commerce": ["تجارة", "business", "commerce"],
    "arts": ["آداب", "اداب", "english", "translation"],
}

def infer_faculty(question: str) -> str | None:
    ql = question.lower()
    for fac, terms in FACULTY_MAP.items():
        for t in terms:
            if t.lower() in ql:
                return fac
    return None

# Helper to classify error categories
def classify_error(question, answer, chunks, detected_faculties, inferred_faculty, session=None):
    # Retrieval failure
    if not chunks:
        return "Retrieval Failure", "No chunks were retrieved"

    # Wrong faculty detection
    if inferred_faculty and inferred_faculty not in detected_faculties:
        return "Wrong Faculty", f"Inferred faculty '{inferred_faculty}' not in detected {detected_faculties}"

    # Correct Refusal (The model correctly refused to answer when chunks are irrelevant)
    if "عذرًا" in answer or "غير متوفرة" in answer or "I don't know" in answer:
        return "Correct Refusal", "Model correctly refused to hallucinate"

    chunk_text = " ".join([c.get("text", "") for c in chunks])
    
    # Partial retrieval – answer very short, but skip the naive chunk text length ratio since answers should be concise
    if len(answer.strip()) < 15:
        return "Partial Retrieval", "Answer is suspiciously short"

    # Contradiction – naive check for presence of both "نعم" and "لا" in answer
    if "نعم" in answer and "لا" in answer:
        return "Contradiction", "Answer contains both affirmative and negative statements"

    # Language Issue – detect if question is English but answer Arabic (or vice‑versa)
    lang = detect_language(question)
    if lang == "english" and re.search(r"[\u0600-\u06FF]", answer):
        return "Language Issue", "English question but Arabic answer"
    if lang == "arabic" and re.search(r"[A-Za-z]", answer):
        return "Language Issue", "Arabic question but English answer"

    # LLM-as-a-Judge for Hallucination
    if session and hasattr(session, 'llm'):
        judge_prompt = f"""You are an objective evaluator. Given the following Question, the Retrieved Context, and the Answer provided by an AI, your task is to determine if the Answer is fully supported by the Context (Correct) or if the Answer contains factual claims not present in the Context (Hallucination).

Ignore minor polite phrasing or Arabic connector words. Focus purely on the factual claims.
If the Answer contains ANY facts not found in the Context, output 'Hallucination'. Otherwise output 'Correct'.

Question: {question}
Context: {chunk_text[:4000]}
Answer: {answer}

Output ONLY 'Correct' or 'Hallucination' (no other text)."""
        try:
            resp = session.llm.invoke(judge_prompt)
            judgment = resp.content.strip() if hasattr(resp, "content") else str(resp).strip()
            if "Hallucination" in judgment:
                return "Hallucination", "LLM Judge flagged as Hallucination"
        except Exception as e:
            pass # fallback to string matching if LLM fails

    # Fallback to simple matching if LLM-as-a-judge is not used or fails
    answer_words = set(re.findall(r"\w+", answer.lower()))
    chunk_words = set(re.findall(r"\w+", chunk_text.lower()))
    missing = answer_words - chunk_words
    if len(missing) > 8:
        return "Over-generation (Fallback)", f"Many words not found: {list(missing)[:5]}"

    return "Correct", "Answer aligns with retrieved context"

results = []
faculty_correct = 0
total_chunks = 0
error_counts = {}

for q in questions:
    resp = session.get_rag_response(q)
    answer = resp.get("answer", "")
    reranked = resp.get("reranked", [])[:5]  # top 5 chunks
    detected = resp.get("detected_faculties", [])
    inferred = infer_faculty(q)
    error_cat, note = classify_error(q, answer, reranked, detected, inferred, session=session)
    if error_cat == "Correct":
        pass
    else:
        error_counts[error_cat] = error_counts.get(error_cat, 0) + 1
    if inferred and inferred in detected:
        faculty_correct += 1
    total_chunks += len(reranked)
    # Build per‑question dict for JSON report
    results.append({
        "question": q,
        "answer": answer,
        "top_chunks": [
            {
                "id": c.get("id"),
                "text": c.get("text"),
                "metadata": c.get("metadata", {}),
                "score": c.get("score", c.get("rrf_score", 0))
            }
            for c in reranked
        ],
        "detected_faculties": detected,
        "inferred_faculty": inferred,
        "error_category": error_cat,
        "notes": note
    })

# ---------- Write reports ----------
report_txt_path = HERE / "evaluation_report.txt"
with open(report_txt_path, "w", encoding="utf-8") as txt:
    txt.write("=== Arabic Retrieval Evaluation Report ===\n\n")
    for idx, rec in enumerate(results, 1):
        txt.write(f"--- Question {idx} ---\n")
        txt.write(f"Question: {rec['question']}\n")
        txt.write(f"Inferred faculty: {rec['inferred_faculty']}\n")
        txt.write(f"Detected faculties: {', '.join(rec['detected_faculties'])}\n")
        txt.write(f"Error category: {rec['error_category']}\n")
        txt.write(f"Notes: {rec['notes']}\n")
        txt.write("Answer (first 300 chars):\n")
        txt.write(rec['answer'][:300] + "\n")
        txt.write("Top retrieved chunks (up to 5):\n")
        for i, ch in enumerate(rec['top_chunks'], 1):
            meta = ch['metadata']
            txt.write(f"  [{i}] {meta.get('fileName','?')} (page {meta.get('page','?')}) – score {ch['score']:.3f}\n")
            txt.write(f"      {ch['text'][:200].replace('\n',' ')}…\n")
        txt.write("\n")
    # Summary statistics
    txt.write("=== Summary Statistics ===\n")
    total_q = len(results)
    txt.write(f"Total questions evaluated: {total_q}\n")
    txt.write("Error counts per category:\n")
    for cat, cnt in error_counts.items():
        txt.write(f"  {cat}: {cnt} ({cnt/total_q:.1%})\n")
    avg_chunks = total_chunks / total_q if total_q else 0
    txt.write(f"Average retrieved chunks per question: {avg_chunks:.2f}\n")
    txt.write(f"% questions with correct faculty detection: {faculty_correct/total_q:.1%}\n")
    # Approximate overall factual accuracy (questions not flagged as Hallucination/Over‑generation)
    factual_ok = total_q - error_counts.get("Hallucination",0) - error_counts.get("Over-generation",0)
    txt.write(f"Overall factual accuracy (approx): {factual_ok/total_q:.1%}\n")

# JSON report
report_json_path = HERE / "evaluation_report.json"
with open(report_json_path, "w", encoding="utf-8") as jf:
    json.dump({
        "metadata": {
            "total_questions": len(results),
            "average_chunks": total_chunks/len(results) if results else 0,
            "faculty_detection_rate": faculty_correct/len(results) if results else 0,
            "error_distribution": error_counts
        },
        "results": results
    }, jf, ensure_ascii=False, indent=2)

print("Evaluation completed. Reports written to evaluation_report.txt / evaluation_report.json")
