"""
section_booster.py
===================
Post-retrieval score boosting based on structural metadata alignment.

Problem it solves
-----------------
A chunk about "first year computer science subjects" may have a lower
embedding similarity score than a generic chunk about "university subjects"
simply because the embedding space is noisy. The booster corrects this by
adding a bonus to chunks whose metadata (sectionTitle, fileName, keywords)
explicitly matches the detected query intent.

Boost factors (additive, applied to rrf_score / rerank_score)
--------------------------------------------------------------
  +0.30  sectionTitle contains year phrase matching query year
  +0.25  sectionTitle contains program name matching query program
  +0.20  fileName contains program name
  +0.15  keywords contain intent-related terms
  +0.10  sectionTitle contains semester phrase matching query semester
  +0.05  language of chunk matches detected query language

All boosts are capped so the total bonus never exceeds +0.60.
"""

from __future__ import annotations

import re
import unicodedata
from typing import Optional

from routes.retrieval.query_understanding import QueryIntent


# ─────────────────────────────────────────────────────────────────────────────
# Boost tables
# ─────────────────────────────────────────────────────────────────────────────

MAX_BOOST = 0.60

# Year phrases to look for in sectionTitle / text (Arabic + English)
_YEAR_PHRASES: dict[int, list[str]] = {
    1: ["first year", "year 1", "1st year", "level 1",
        "الفرقة الأولى", "فرقه اوله", "فرقة اولى", "السنة الأولى",
        "المستوى الأول", "الاول", "اوله"],
    2: ["second year", "year 2", "2nd year", "level 2",
        "الفرقة الثانية", "فرقه تانيه", "السنة الثانية",
        "المستوى الثاني", "الثاني", "تانيه"],
    3: ["third year", "year 3", "3rd year", "level 3",
        "الفرقة الثالثة", "فرقه تالته", "السنة الثالثة",
        "المستوى الثالث", "الثالث", "تالته"],
    4: ["fourth year", "year 4", "4th year", "level 4",
        "الفرقة الرابعة", "فرقه رابعه", "السنة الرابعة",
        "المستوى الرابع", "الرابع", "رابعه"],
}

_SEMESTER_PHRASES: dict[int, list[str]] = {
    1: ["semester 1", "first semester", "term 1", "sem 1",
        "الترم الأول", "الفصل الأول", "ترم اول"],
    2: ["semester 2", "second semester", "term 2", "sem 2",
        "الترم الثاني", "الفصل الثاني", "ترم تاني"],
}

# Program keywords to look for in sectionTitle / fileName
_PROGRAM_KEYWORDS: dict[str, list[str]] = {
    "computer science":  ["حاسبات", "حاسوب", "الحاسب", "computer", "cs", "it", "ذكاء", "informatics", "تقنية معلومات", "نظم معلومات", "برمجه"],
    "engineering":       ["هندس", "engineer"],
    "medicine":          ["طب وجراحه", "طب_وجراحه", "وجراحه", "medicine and surgery", "medical", "mbbs", "الطب والجراحه", "الطب والجراحة", "كلية الطب", "برنامج الطب", "العلوم الطبيه", "العلوم الطبية", "طب بشري", "الطب البشري"],
    "dentistry":         ["أسنان", "اسنان", "dent", "فم والاسنان", "الفم والاسنان", "الفم والأسنان", "طب الاسنان", "طب الأسنان"],
    "pharmacy":          ["صيدل", "pharmac"],
    "law":               ["حقوق", "قانون", "law"],
    "commerce":          ["تجار", "commerce", "business", "اقتصاد", "محاسب", "اداره"],
    "nursing":           ["تمريض", "nursing"],
    "veterinary":        ["بيطر", "طب بيطري", "veterinar", "بيطري"],
    "physical therapy":  ["علاج طبيعي", "علاج_طبيعي", "physio", "physical therapy"],
    "arts":              ["لغه انجليزيه", "لغة إنجليزية", "ترجمه", "ترجمة", "english", "translation", "اداب", "آداب", "لغات"],
}

# Intent keywords to look for in chunk keywords / sectionTitle
_INTENT_KEYWORDS: dict[str, list[str]] = {
    # Issue 18: expanded curriculum keywords for better matching
    "subjects list":  [
        "subjects", "courses", "curriculum", "study plan", "academic plan",
        "مواد", "مقررات", "كورسات", "خطة دراسية", "برنامج دراسي",
        "course list", "program", "academic year",
        "الترجمة التحريرية", "الترجمة التخصصية", "الترجمة التتبعية", "الترجمة الفورية",
        "الترجمة السياسية", "الترجمة الاقتصادية", "الترجمة العلمية", "ترجمة الشاشة",
    ],
    "exam schedule":  ["exam", "امتحان", "امتحانات", "جدول"],
    "grades":         ["grades", "marks", "درجات", "نتائج", "نجاح", "رسوب", "تقدير"],
    "schedule":       ["schedule", "timetable", "جدول", "مواعيد"],
    "registration":   ["registration", "enroll", "تسجيل"],
    "fees":           ["fees", "tuition", "مصروفات", "رسوم"],
    "graduation":     ["graduation", "degree", "تخرج", "شهادة"],
    "regulations":    [
        "regulations", "rules", "لائحة", "قوانين", "شروط", "نظام", "قواعد",
        "تخرج", "متطلبات", "بكالوريوس", "تراكمي",
        # Training-specific keywords — NEW
        "تدريب", "التدريب", "تدريب صيفي", "التدريب الصيفي",
        "تدريب ميداني", "التدريب الميداني",
        "تدريب عملي", "التدريب العملي",
        "يشترط", "اشتراط", "شرط", "متطلب تدريب",
        "internship", "field training", "summer training", "practical training",
    ],
    "professors":     ["professor", "faculty", "دكتور", "استاذ"],
    "departments":    ["أقسام", "اقسام", "تخصصات", "تخصص", "قسم", "department", "division", "divisions", "تتكون الكلية من", "الأقسام العلمية", "الاقسام العلمية"],
}

# Issue 18: curriculum queries get a higher boost cap
# because course-list chunks are often not tagged with explicit metadata
_CURRICULUM_INTENTS = {"subjects list", "schedule", "registration"}
MAX_BOOST_CURRICULUM = 0.75   # higher cap for curriculum-type queries
MAX_BOOST            = 0.60   # standard cap


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

_AR_NORM = str.maketrans({
    "\u0622": "\u0627",  # آ → ا
    "\u0623": "\u0627",  # أ → ا
    "\u0625": "\u0627",  # إ → ا
    "\u0671": "\u0627",  # ٱ → ا
    "\u0649": "\u064A",  # ى → ي
    "\u0624": "\u0648",  # ؤ → و
    "\u0626": "\u064A",  # ئ → ي
    "\u0629": "\u0647",  # ه → ة
})
_DIACRITICS = re.compile(r"[\u064B-\u065F\u0610-\u061A\u06D6-\u06ED]")

def _normalize_text(text: str) -> str:
    """Case-insensitive + Arabic-normalised text."""
    if not text: return ""
    text = text.lower()
    text = unicodedata.normalize("NFC", text)
    text = text.translate(_AR_NORM)
    text = _DIACRITICS.sub("", text)
    return re.sub(r"\s+", " ", text).strip()

def _contains_any(text: str, phrases: list[str]) -> bool:
    """Sub-string check with normalization for both text and phrases."""
    if not text: return False
    norm_text = _normalize_text(text)
    for p in phrases:
        if _normalize_text(p) in norm_text:
            return True
    return False


def _is_curriculum_table(text: str) -> bool:
    """Detect if text looks like a curriculum/course table (codes + hours)."""
    # Look for course code patterns: AAA 123
    codes = len(re.findall(r"\b[A-Z]{2,4}\s*\d{3,4}\b", text, re.IGNORECASE))
    # Look for table-like rows ending in hours: "Course Name 3 2" or "[3]"
    rows  = len(re.findall(r"[\u0600-\u06FF\w\s]+\s*\[?\d\]?\s*[\d\"]?", text))
    # Look for English course list headers
    headers = len(re.findall(r"level\s*[1-4]|semester\s*[1-2]|credit\s*hours", text, re.IGNORECASE))
    
    return codes >= 2 or rows >= 5 or headers >= 1

def _compute_boost(chunk: dict, intent: QueryIntent) -> float:
    """
    Compute the total boost score for a single chunk given the query intent.
    Returns a value in [0, MAX_BOOST] or [0, MAX_BOOST_CURRICULUM].
    """
    meta    = chunk.get("metadata", {})
    section = (meta.get("sectionTitle") or "").lower()
    fname   = (meta.get("fileName") or "").lower()
    kw      = (meta.get("keywords") or "").lower()
    lang    = (meta.get("language") or "").lower()
    text    = (chunk.get("text") or "").lower()

    # Issue 9: search deeper into text body for curriculum chunks
    # (course tables often have no sectionTitle metadata)
    searchable = f"{section} {fname} {kw} {text[:600]}"

    boost = 0.0

    _programs = intent.program if isinstance(intent.program, list) else ([intent.program] if intent.program else [])

    # ── Program mismatch penalty ──────────────────────────────────────────
    # If the user explicitly asked for a program, penalize chunks from OTHER programs.
    if _programs:
        matched_requested_program = False
        # 1. Check if the chunk strongly matches the requested program
        for _prog in _programs:
            if _prog and _prog in _PROGRAM_KEYWORDS:
                phrases = _PROGRAM_KEYWORDS[_prog]
                if _contains_any(section, phrases) or _contains_any(fname, phrases):
                    matched_requested_program = True
                    break
        
        # 2. If not, check if it matches ANOTHER known program
        if not matched_requested_program:
            matched_other_program = False
            for other_prog, phrases in _PROGRAM_KEYWORDS.items():
                if other_prog not in _programs:
                    if _contains_any(fname, phrases) or _contains_any(section, phrases):
                        matched_other_program = True
                        break
            
            if matched_other_program:
                # Huge penalty to prevent unrelated curriculum tables from bubbling up
                return -0.50

    # ── Year match ────────────────────────────────────────────────────────
    if intent.year and intent.year in _YEAR_PHRASES:
        phrases = _YEAR_PHRASES[intent.year]
        if _contains_any(section, phrases):
            boost += 0.30
        elif _contains_any(text[:400], phrases):   # Issue 9: check text body
            boost += 0.20
        elif _contains_any(searchable, phrases):
            boost += 0.15

    # ── Program match ─────────────────────────────────────────────────────
    for _prog in _programs:
        if _prog and _prog in _PROGRAM_KEYWORDS:
            phrases = _PROGRAM_KEYWORDS[_prog]
            if _contains_any(section, phrases):
                boost += 0.25
            elif _contains_any(fname, phrases):
                boost += 0.20
            elif _contains_any(text[:400], phrases):
                boost += 0.15
            elif _contains_any(kw, phrases):
                boost += 0.10
            break  # use first matching program only

    # ── Semester match ────────────────────────────────────────────────────
    if intent.semester and intent.semester in _SEMESTER_PHRASES:
        phrases = _SEMESTER_PHRASES[intent.semester]
        if _contains_any(section, phrases):
            boost += 0.15
        elif _contains_any(searchable, phrases):
            boost += 0.10

    # ── Intent keyword match ──────────────────────────────────────────────
    if intent.intent in _INTENT_KEYWORDS:
        phrases = _INTENT_KEYWORDS[intent.intent]
        if _contains_any(section, phrases):
            boost += 0.15
        if _contains_any(kw, phrases):
            boost += 0.10
        if _contains_any(text[:600], phrases):   # Deep scan for formal lists
            boost += 0.45                          # Hyper-boost (0.45) to ensure formal lists > subject tables
            
        # Issue 20: specifically boost curriculum tables for subjects list intent
        if intent.intent == "subjects list" and _is_curriculum_table(text):
            boost += 0.40   # Significant boost for actual tables
            
    if boost > 0.3:
        try:
            print(f"DEBUG BOOST: [{fname}] Page {meta.get('page')} Boost={boost:.2f} Text={text[:50].replace('\n', ' ')}...")
        except Exception:
            pass

    # ── Language match ────────────────────────────────────────────────────
    query_lang = _infer_query_lang(intent.raw_query)
    # Issue 19: treat unknown/empty language as a match (don't penalise)
    if not lang or lang in ("unknown", "?", ""):
        boost += 0.03   # small bonus — don't penalise missing lang metadata
    elif lang == query_lang:
        boost += 0.05

    # Issue 18: apply higher cap for curriculum-type queries
    cap = MAX_BOOST_CURRICULUM if intent.intent in _CURRICULUM_INTENTS else MAX_BOOST
    return min(boost, cap)


def _infer_query_lang(query: str) -> str:
    """Quick language detection for the query."""
    ar = len(re.findall(r"[\u0600-\u06FF]", query))
    en = len(re.findall(r"[A-Za-z]", query))
    if ar > en:
        return "arabic"
    if en > ar:
        return "english"
    return "mixed"


# ─────────────────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────────────────

def apply_section_boost(
    results: list[dict],
    intent: QueryIntent,
    score_key: str = "rrf_score",
) -> list[dict]:
    """
    Apply structural metadata boosts to a list of retrieval results and
    re-sort by the boosted score.

    Parameters
    ----------
    results : list[dict]
        Retrieval results (each must have "metadata" and score_key).
    intent : QueryIntent
        Parsed query intent from understand_query().
    score_key : str
        The score field to boost (default: "rrf_score").
        After boosting, a new field "boosted_score" is added.

    Returns
    -------
    list[dict] sorted by descending boosted_score.
    """
    # Skip boosting if no structured intent was detected
    if not intent.program and not intent.year and intent.intent == "general":
        for r in results:
            r["boosted_score"] = r.get(score_key, 0.0)
            r["boost_applied"] = 0.0
        return results

    boosted = []
    for chunk in results:
        base  = chunk.get(score_key, 0.0)
        # Preserve hybrid_search boosted_score if it exists
        current_boosted = chunk.get("boosted_score", base)
        bonus = _compute_boost(chunk, intent)
        entry = dict(chunk)
        entry["boosted_score"] = current_boosted + bonus
        entry["boost_applied"] = bonus
        boosted.append(entry)

    boosted.sort(key=lambda x: x["boosted_score"], reverse=True)
    return boosted


def filter_by_intent(
    results: list[dict],
    intent: QueryIntent,
    min_boost: float = 0.0,
    fallback_if_empty: bool = True,
) -> list[dict]:
    """
    Soft-filter results by intent boost score.

    Only activates when:
      - min_boost > 0
      - intent.confidence ≥ 0.85  (aligned with STRICT_FILTER_CONFIDENCE)

    Always falls back to the full list if filtering removes everything.
    The caller (hybrid_search._boost_and_filter) handles protected anchors.
    """
    # Threshold aligned with hybrid_search.STRICT_FILTER_CONFIDENCE = 0.85
    if min_boost <= 0 or intent.confidence < 0.85:
        return results

    filtered = [r for r in results if r.get("boost_applied", 0.0) >= min_boost]

    if not filtered and fallback_if_empty:
        return results

    return filtered
