# -*- coding: utf-8 -*-
"""
evaluate_rag.py
==============
يقرأ ملف الإجابات model_answers.txt ويقارنه بـ scratch/ground_truth_30q.json
ويحسب Exact Match (Strict), Keyword Match (Factual EM), و Token F1-Score.
"""

import sys
import io
import json
import re
from pathlib import Path

# ── UTF-8 Setup ──────────────────────────────────────────────────────────────
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

# ── Paths ────────────────────────────────────────────────────────────────────
_HERE = Path(__file__).resolve().parent.parent
ANSWERS_FILE = _HERE / "model_answers.txt"
GT_FILE = _HERE / "scratch" / "ground_truth_cleaned.json"

# ── Helpers for cleaning and F1 calculation ──────────────────────────────────
def clean_text(text: str) -> str:
    """إزالة علامات الترقيم، الروابط، التشكيل، وتوحيد المسافات وبعض الحروف العربية."""
    if not text:
        return ""
    text = text.lower()
    # توحيد الـ الهمزات والتاء المربوطة والياء
    text = re.sub(r'[أإآا]', 'ا', text)
    text = re.sub(r'ة', 'ه', text)
    text = re.sub(r'ى', 'ي', text)
    # إزالة الحركات والتشكيل
    text = re.sub(r'[\u064B-\u0652]', '', text)
    # إزالة الرموز وعلامات الترقيم غير الهامة
    text = re.sub(r'[^\w\s\d]', ' ', text)
    # توحيد المسافات
    return " ".join(text.split())

def calculate_token_f1(pred: str, ref: str) -> float:
    """حسب الـ Token-level F1 Score بين كلمتين نظيفتين."""
    pred_tokens = clean_text(pred).split()
    ref_tokens = clean_text(ref).split()
    
    if not pred_tokens or not ref_tokens:
        return 0.0
    
    # حساب التداخل
    pred_counter = {}
    for t in pred_tokens:
        pred_counter[t] = pred_counter.get(t, 0) + 1
        
    ref_counter = {}
    for t in ref_tokens:
        ref_counter[t] = ref_counter.get(t, 0) + 1
        
    common_tokens = 0
    for token, count in ref_counter.items():
        if token in pred_counter:
            common_tokens += min(count, pred_counter[token])
            
    if common_tokens == 0:
        return 0.0
    
    precision = common_tokens / len(pred_tokens)
    recall = common_tokens / len(ref_tokens)
    f1 = 2 * (precision * recall) / (precision + recall)
    return f1

def parse_model_answers(path: Path) -> dict:
    """يقرأ ويحلل ملف model_answers.txt ويستخرج الإجابات الخاصة بـ [Q01] إلى [Q30]"""
    if not path.exists():
        raise FileNotFoundError(f"Answers file not found at: {path}")
        
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
        
    # تقسيم الملف بناءً على الفواصل ───────────────────
    # كل سؤال بيبدأ بـ [QXX]
    pattern = r"─{10,}\n\[(Q\d+)\] السؤال: (.*?)\nالحالة\s+:\s+(\w+).*?\nالإجابة:\n(.*?)(?=\n─{10,}|\n={10,}|\Z)"
    matches = re.findall(pattern, content, re.DOTALL)
    
    answers = {}
    for qid, qtext, status, ans_body in matches:
        answers[qid] = {
            "question": qtext.strip(),
            "status": status.strip(),
            "answer": ans_body.strip()
        }
    return answers

# ── Main Eval Logic ──────────────────────────────────────────────────────────
def main():
    print("=" * 80)
    print("  RAG Evaluation Tool — Exact-Match & F1-Score")
    print("=" * 80)
    
    # 1. تحميل الـ Ground Truth
    if not GT_FILE.exists():
        print(f"ERROR: Ground Truth file not found at {GT_FILE}")
        return
    with open(GT_FILE, "r", encoding="utf-8") as f:
        gt_data = json.load(f)
        
    # 2. تحميل إجابات الموديل
    try:
        model_answers = parse_model_answers(ANSWERS_FILE)
    except Exception as e:
        print(f"ERROR reading answers: {e}")
        return
        
    print(f"Loaded {len(gt_data['questions'])} Ground Truth questions.")
    print(f"Extracted {len(model_answers)} answers from model_answers.txt\n")
    
    print(f"{'QID':<6} | {'Exact Match (Strict)':<22} | {'Keyword Match (Factual EM)':<26} | {'F1-Score':<10} | {'Status'}")
    print("-" * 85)
    
    strict_em_total = 0.0
    factual_em_total = 0.0
    f1_total = 0.0
    evaluated_count = 0
    
    for gt_item in gt_data["questions"]:
        qid = gt_item["id"]
        ref_ans = gt_item["reference_answer"]
        expected_kws = gt_item["expected_keywords"]
        
        if qid not in model_answers:
            print(f"{qid:<6} | {'N/A':<22} | {'N/A':<26} | {'N/A':<10} | Missing")
            continue
            
        model_item = model_answers[qid]
        pred_ans = model_item["answer"]
        status = model_item["status"]
        
        # 1. Strict Exact Match (Strict String Matching after cleaning)
        clean_pred = clean_text(pred_ans)
        clean_ref = clean_text(ref_ans)
        strict_em = 1.0 if clean_pred == clean_ref else 0.0
        
        # 2. Keyword Match (Factual EM - whether all expected keywords are present)
        # We search for normalized versions of the keywords
        clean_pred_tokens = clean_pred.split()
        matched_kws = []
        for kw in expected_kws:
            clean_kw = clean_text(kw)
            # check if keyword matches any token as substring or exact word
            if any(clean_kw in token for token in clean_pred_tokens):
                matched_kws.append(kw)
        
        # Factual EM is 1.0 if all expected keywords were hit, else fraction
        factual_em = len(matched_kws) / len(expected_kws)
        
        # 3. Token level F1 Score
        f1_score = calculate_token_f1(pred_ans, ref_ans)
        
        # Accummulate
        strict_em_total += strict_em
        factual_em_total += factual_em
        f1_total += f1_score
        evaluated_count += 1
        
        factual_em_pct = factual_em * 100
        f1_score_pct = f1_score * 100
        
        print(f"{qid:<6} | {strict_em:<22.0f} | {factual_em_pct:<25.1f}% | {f1_score_pct:<9.1f}% | {status}")
        
    if evaluated_count > 0:
        avg_strict_em = (strict_em_total / evaluated_count) * 100
        avg_factual_em = (factual_em_total / evaluated_count) * 100
        avg_f1 = (f1_total / evaluated_count) * 100
        
        print("=" * 85)
        print("SUMMARY:")
        print(f"Evaluated Questions        : {evaluated_count}")
        print(f"Strict Exact Match (EM)    : {avg_strict_em:.2f}%")
        print(f"Keyword Factual EM         : {avg_factual_em:.2f}%")
        print(f"Average Token F1-Score     : {avg_f1:.2f}%")
        print("=" * 85)
        
        # Save summary report
        report_file = _HERE / "evaluation_report.txt"
        with open(report_file, "w", encoding="utf-8") as rf:
            rf.write("=" * 80 + "\n")
            rf.write("  RAG Evaluation Report\n")
            rf.write("=" * 80 + "\n")
            rf.write(f"Evaluated Questions        : {evaluated_count}\n")
            rf.write(f"Strict Exact Match (EM)    : {avg_strict_em:.2f}%\n")
            rf.write(f"Keyword Factual EM         : {avg_factual_em:.2f}%\n")
            rf.write(f"Average Token F1-Score     : {avg_f1:.2f}%\n")
            rf.write("=" * 80 + "\n")
        print(f"Report saved to: {report_file}")

if __name__ == "__main__":
    main()
