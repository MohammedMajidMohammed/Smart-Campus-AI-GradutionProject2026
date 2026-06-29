"""
query_understanding.py
=======================
Structured query understanding for Arabic/English university RAG queries.

Two-tier architecture:
  Tier 1 (always runs): Rule-based parser — zero latency, zero API calls.
                        Handles clear cases: "مواد الفرقة الأولى حاسبات"
  Tier 2 (optional):    LLM-based classifier — called only when rule-based
                        confidence is low (< LOW_CONF_THRESHOLD) AND an LLM
                        is provided. Handles ambiguous cases like:
                        "Explain database normalization in medical records"

The LLM classifier is a single structured prompt that returns JSON.
It never runs during normal high-confidence queries, so latency is unaffected.

Extracts:
  - program   : academic program (computer science, engineering, …)
  - year      : academic year (1–4)
  - semester  : semester number (1–2) if mentioned
  - intent    : what the user wants (subjects, exams, grades, schedule, …)
  - clean_query : rewritten semantic search query (English, normalised)
  - query_variants : list of alternative phrasings for multi-query retrieval
  - classifier_tier : "rule_based" | "llm_assisted"

Example
-------
>>> from routes.retrieval.query_understanding import understand_query
>>> understand_query("مواد الترم الاول فرق اوله حاسبات")
QueryIntent(
    program='computer science',
    year=1,
    semester=1,
    intent='subjects list',
    clean_query='first year computer science semester 1 subjects courses',
    query_variants=[...],
    confidence=0.92,
    classifier_tier='rule_based',
    raw_query='مواد الترم الاول فرق اوله حاسبات',
    normalized_query='مواد الترم الاول فرقه اوله حاسبات'
)
"""

from __future__ import annotations

import json
import logging
import re
import unicodedata
from dataclasses import dataclass, field
from typing import Optional

logger = logging.getLogger(__name__)

# Confidence below this threshold triggers LLM fallback (if LLM provided)
LOW_CONF_THRESHOLD = 0.55

# Retrieval score below this → flag as low confidence (ask for clarification)
RETRIEVAL_CONF_THRESHOLD = 0.15

# Intent-specific keyword augmentation for BM25 retrieval.
# Mapping from detected intent to a list of Arabic keywords that help broaden the BM25 search.
# These are lightweight heuristics; extend as needed for new intents.
_INTENT_KEYWORDS = {
    "subjects list": ["مواد", "مقررات", "دورات", "منهج"],
    "schedule": ["جدول", "مواعيد", "فصل", "موعد"],
    "registration": ["تسجيل", "التحاق", "قيد", "انضمام"],
    "exams": ["امتحان", "اختبار", "امتحانات", "اختبارات"],
    "grades": ["درجات", "علامات", "نتائج", "مجموع"],
    "general": []
}



# ─────────────────────────────────────────────────────────────────────────────
# Data class
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class QueryIntent:
    """Structured representation of a parsed user query."""
    raw_query:        str
    normalized_query: str
    clean_query:      str                    # rewritten for semantic search
    program:          Optional[str] = None   # "computer science", "engineering", …
    year:             Optional[int] = None   # 1 | 2 | 3 | 4
    semester:         Optional[int] = None   # 1 | 2
    intent:           str = "general"        # subjects | exams | grades | schedule | …
    query_variants:   list[str] = field(default_factory=list)
    confidence:       float = 0.5            # 0–1 how confident we are in the parse
    metadata_filter:  dict = field(default_factory=dict)  # ready for ChromaDB where
    classifier_tier:  str = "rule_based"     # "rule_based" | "llm_assisted"


# ─────────────────────────────────────────────────────────────────────────────
# Arabic normalisation (inline, no circular import)
# ─────────────────────────────────────────────────────────────────────────────

_AR_NORM = str.maketrans({
    "\u0622": "\u0627",  # آ → ا
    "\u0623": "\u0627",  # أ → ا
    "\u0625": "\u0627",  # إ → ا
    "\u0671": "\u0627",  # ٱ → ا
    "\u0649": "\u064A",  # ى → ي
    "\u0624": "\u0648",  # ؤ → و
    "\u0626": "\u064A",  # ئ → ي
    "\u0629": "\u0647",  # ة → ه  (ta marbuta → ha, helps matching)
})
_DIACRITICS = re.compile(r"[\u064B-\u065F\u0610-\u061A\u06D6-\u06ED]")
_TATWEEL    = re.compile(r"\u0640+")


def _normalize_ar(text: str) -> str:
    """Standard Arabic normalization."""
    if not text:
        return ""
    # Remove punctuation by replacing with space
    text = re.sub(r"[?؟.,!;:()\[\]{}'\"\-–—_/]", " ", text)
    # Remove diacritics
    text = _DIACRITICS.sub("", text)
    # Remove tatweel
    text = _TATWEEL.sub("", text)
    # Basic character mapping
    text = text.translate(_AR_NORM)
    # Strip leading 'al-' (ال) from each word if it's longer than 4 chars
    # (prevents stripping 'al' from short words like 'ال' itself if any)
    words = []
    for word in text.split():
        # Handle "wa-al-" (والـ)
        if word.startswith("وال") and len(word) > 5:
            words.append(word[3:])
        # Handle "al-" (الـ)
        elif word.startswith("ال") and len(word) > 4:
            words.append(word[2:])
        # Handle "wa-" (وـ)
        elif word.startswith("و") and len(word) > 4:
            words.append(word[1:])
        else:
            words.append(word)
    return " ".join(words)


# ─────────────────────────────────────────────────────────────────────────────
# Program detection
# ─────────────────────────────────────────────────────────────────────────────

# Each entry: (canonical_name, [Arabic patterns], [English patterns])
_PROGRAMS: list[tuple[str, list[str], list[str]]] = [
    (
        "computer science",
        ["حاسبات", "حاسب", "كمبيوتر", "علوم الحاسب", "تقنيه معلومات",
         "تقنية معلومات", "نظم معلومات", "نظم المعلومات", "برمجه", "برمجة",
         "البرمجه", "البرمجة", "كليه البرمجه", "كلية البرمجة",
         "كليه حاسبات", "كلية حاسبات", "حاسبات ومعلومات", "كليه الحاسبات", "كلية الحاسبات",
         "قسم حاسبات", "قسم الحاسبات", "الحاسوب", "كلية الحاسوب", "كليه الحاسوب",
         "سايبر", "السايبر", "هاكر", "الهاكر", "امن معلومات", "امن سيبراني", "الذكاء الاصطناعي"],
        ["computer science", "cs", "computing", "informatics",
         "information technology", "it", "information systems", "programming",
         "faculty of computers", "college of computers", "cyber", "hacker", "cybersecurity", "ai", "artificial intelligence"],
    ),
    (
        "engineering",
        ["هندسه", "هندسة", "مهندس"],
        ["engineering", "eng"],
    ),
    (
        "medicine",
        ["طبيه", "طبية", "كليه الطب", "كلية الطب", "برنامج الطب",
         "طب وجراحه", "طب والجراحه", "الطب البشري", "طب بشري", "الطب", "طب"],
        ["medicine", "medical", "mbbs"],
    ),
    (
        "pharmacy",
        ["صيدله", "صيدلة", "صيدلي"],
        ["pharmacy", "pharmaceutical"],
    ),
    (
        "law",
        ["حقوق", "قانون"],
        ["law", "legal"],
    ),
    (
        "commerce",
        ["تجاره", "تجارة", "اقتصاد", "محاسبه", "محاسبة", "اداره اعمال",
         "إدارة أعمال", "اداره"],
        ["commerce", "business", "accounting", "economics", "management"],
    ),
    (
        "arts",
        ["اداب", "آداب", "لغه عربيه", "لغة عربية", "تاريخ", "جغرافيا", 
         "لغة انجليزية", "لغة إنجليزية", "انجليزي", "انجليزي", "ترجمة", "ترجمه"],
        ["arts", "humanities", "arabic", "english", "history", "geography", "translation"],
    ),
    (
        "science",
        ["علوم", "فيزياء", "كيمياء", "احياء", "رياضيات"],
        ["science", "physics", "chemistry", "biology", "mathematics", "math"],
    ),
    (
        "education",
        ["تربيه", "تربية", "تعليم"],
        ["education", "teaching"],
    ),
    (
        "nursing",
        ["تمريض", "تمريضيه", "علوم التمريض", "علوم_التمريض", "برنامج علوم التمريض"],
        ["nursing", "nurse", "nurses", "nursing science", "nursing program"],
    ),
    (
        "veterinary",
        ["طب بيطري", "بيطره", "بيطرة", "بيطري", "كلية الطب البيطري", "كليه الطب البيطري", "الطب البيطري"],
        ["veterinary", "veterinarian", "vet", "veterinary medicine"],
    ),
    (
        "physical therapy",
        ["علاج طبيعي", "علاج_طبيعي", "علاج فيزيائي"],
        ["physical therapy", "physiotherapy", "physio", "physical therapist"],
    ),
    (
        "dentistry",
        ["طب اسنان", "طب أسنان", "اسنان", "فم واسنان", "الفم واسنان",
         "أسنان", "طب الاسنان", "طب الأسنان", "كلية طب الأسنان",
         "كلية الأسنان", "كليه الاسنان", "برنامج طب الأسنان"],
        ["dentistry", "dental", "oral", "dentist"],
    ),
]

# Build fast lookup: normalised token → canonical name
_PROGRAM_LOOKUP: dict[str, str] = {}
for _canon, _ar_pats, _en_pats in _PROGRAMS:
    for _p in _ar_pats:
        _PROGRAM_LOOKUP[_normalize_ar(_p)] = _canon
    for _p in _en_pats:
        _PROGRAM_LOOKUP[_p.lower()] = _canon


def _detect_program(text_ar: str, text_en: str) -> Optional[str]:
    """Return canonical program name or None."""
    # Arabic letter ranges ONLY — excludes Arabic punctuation (؟ ، ؛ ـ etc.)
    # \u0621-\u063A = basic Arabic letters (ء to غ)
    # \u0641-\u064A = more Arabic letters (ف to ي)
    # \u0671-\u06D3 = extended Arabic letters
    _AR_LETTERS = re.compile(r"[\u0621-\u063A\u0641-\u064A\u0671-\u06D3]+")

    tokens_ar = _AR_LETTERS.findall(text_ar)

    # Multi-word Arabic phrases (4 down to 2 words) — catches "طب اسنان", "كليه حاسبات" etc.
    # We check phrases BEFORE single words to ensure "طب اسنان" isn't caught by "طب" (medicine)
    for phrase_len in (4, 3, 2):
        for i in range(len(tokens_ar) - phrase_len + 1):
            phrase = _normalize_ar(" ".join(tokens_ar[i:i + phrase_len]))
            if phrase in _PROGRAM_LOOKUP:
                return _PROGRAM_LOOKUP[phrase]

    # Also try a sliding window that skips stop-words (في, من, على, و, ب, ل, ك, ال)
    # This catches "طب في الاسنان" or other fragmented phrases
    _STOPS = {"في", "من", "على", "عن", "الى", "إلى", "هي", "هو", "ما", "ان", "أن"}
    content_tokens = [t for t in tokens_ar if _normalize_ar(t) not in _STOPS]
    for phrase_len in (4, 3, 2):
        for i in range(len(content_tokens) - phrase_len + 1):
            phrase = _normalize_ar(" ".join(content_tokens[i:i + phrase_len]))
            if phrase in _PROGRAM_LOOKUP:
                return _PROGRAM_LOOKUP[phrase]

    # Arabic tokens (single words)
    for token in tokens_ar:
        norm = _normalize_ar(token)
        if norm in _PROGRAM_LOOKUP:
            return _PROGRAM_LOOKUP[norm]

    # English phrases (3 down to 2 words)
    # English phrases (3 down to 2 words)
    tokens_en = re.findall(r'[a-z]+', text_en.lower())
    for phrase_len in (3, 2):
        for i in range(len(tokens_en) - phrase_len + 1):
            phrase = " ".join(tokens_en[i:i + phrase_len])
            if phrase in _PROGRAM_LOOKUP:
                return _PROGRAM_LOOKUP[phrase]

    # English tokens (single words)
    for token in tokens_en:
        if token in _PROGRAM_LOOKUP:
            return _PROGRAM_LOOKUP[token]

    return None


def _detect_all_programs(raw_query: str) -> list[str]:
    """Detect all unique canonical program names mentioned in the query."""
    lower_q = raw_query.lower()
    norm_q = _normalize_ar(raw_query)
    found = []
    
    for canon, ar_pats, en_pats in _PROGRAMS:
        ar_match = False
        for p in ar_pats:
            norm_p = _normalize_ar(p)
            q_tokens = norm_q.split()
            p_tokens = norm_p.split()
            # Check if p_tokens is a sublist of q_tokens
            for i in range(len(q_tokens) - len(p_tokens) + 1):
                if q_tokens[i:i + len(p_tokens)] == p_tokens:
                    ar_match = True
                    break
            if ar_match:
                break
        if ar_match:
            found.append(canon)
            continue
            
        en_match = False
        for p in en_pats:
            if re.search(r'\b' + re.escape(p.lower()) + r'\b', lower_q):
                en_match = True
                break
        if en_match:
            found.append(canon)
            
    # Resolve conflicts: if 'dentistry' (طب اسنان) is matched, we might have also matched 'medicine' (طب).
    # If the only reason 'medicine' matched was 'طب' inside 'طب اسنان', we remove it.
    if "dentistry" in found and "medicine" in found:
        med_specific = ["وجراحه", "بشري", "كليه الطب", "كلية الطب", "برنامج الطب", "medicine", "medical", "mbbs"]
        has_med_specific = any(s in lower_q or _normalize_ar(s) in norm_q for s in med_specific)
        if not has_med_specific:
            found.remove("medicine")

    # Resolve conflicts: if 'veterinary' (طب بيطري) is matched, 'medicine' may also match
    # purely because of the standalone "طب" inside "طب بيطري". If there's no medicine-specific
    # signal, drop "medicine".
    if "veterinary" in found and "medicine" in found:
        med_specific = ["وجراحه", "بشري", "كليه الطب", "كلية الطب", "برنامج الطب", "medicine", "medical", "mbbs"]
        has_med_specific = any(s in lower_q or _normalize_ar(s) in norm_q for s in med_specific)
        if not has_med_specific:
            found.remove("medicine")

    # Resolve: "علوم التمريض" → nursing only, not science+nursing
    if "nursing" in found and "science" in found:
        nursing_specific = ["تمريض", "nursing"]
        has_nursing_specific = any(s in lower_q or s in norm_q for s in nursing_specific)
        science_specific = ["فيزياء", "كيمياء", "احياء", "رياضيات", "physics", "chemistry", "biology", "math"]
        has_science_specific = any(s in lower_q for s in science_specific)
        if has_nursing_specific and not has_science_specific:
            found.remove("science")

    return found


# ─────────────────────────────────────────────────────────────────────────────
# Year detection
# ─────────────────────────────────────────────────────────────────────────────

# Arabic ordinals and colloquial forms for years 1–4
_YEAR_PATTERNS: list[tuple[int, list[str]]] = [
    (0, [
        r"اعدادي", r"إعدادي", r"الاعدادي[هة]?", r"الإعدادي[هة]?",
        r"تمهيدي", r"التمهيدي",
        r"prep", r"preparatory", r"level\s*0",
    ]),
    (1, [
        r"فرق[هة]\s*اول[هى]?", r"الفرق[هة]\s*الاول[هى]?", r"السن[هة]\s*الاول[هى]?",
        r"المستو[يى]\s*الاول", r"اول[هى]?\s*فرق[هة]", r"اول[هى]?\s*سن[هة]",
        r"الاول[هى]?", r"فرق[هة]\s*1", r"سن[هة]\s*1",
        r"\باول[هى]\b",
        r"first\s*year", r"year\s*1", r"level\s*1", r"1st\s*year",
        r"\b1\b(?=\s*(year|سنه|فرقه|مستوي))",
    ]),
    (2, [
        r"فرق[هة]\s*تاني[هة]?", r"الفرق[هة]\s*التاني[هة]?", r"السن[هة]\s*التاني[هة]?",
        r"المستو[يى]\s*التاني", r"تاني[هة]?\s*فرق[هة]", r"تاني[هة]?\s*سن[هة]",
        r"الثاني[هة]?", r"فرق[هة]\s*2", r"سن[هة]\s*2",
        r"second\s*year", r"year\s*2", r"level\s*2", r"2nd\s*year",
    ]),
    (3, [
        r"فرق[هة]\s*تالت[هة]?", r"الفرق[هة]\s*التالت[هة]?", r"السن[هة]\s*التالت[هة]?",
        r"المستو[يى]\s*التالت", r"تالت[هة]?\s*فرق[هة]",
        r"الثالث[هة]?", r"فرق[هة]\s*3", r"سن[هة]\s*3",
        r"third\s*year", r"year\s*3", r"level\s*3", r"3rd\s*year",
    ]),
    (4, [
        r"فرق[هة]\s*رابع[هة]?", r"الفرق[هة]\s*الرابع[هة]?", r"السن[هة]\s*الرابع[هة]?",
        r"المستو[يى]\s*الرابع", r"رابع[هة]?\s*فرق[هة]",
        r"الرابع[هة]?", r"فرق[هة]\s*4", r"سن[هة]\s*4",
        r"fourth\s*year", r"year\s*4", r"level\s*4", r"4th\s*year",
    ]),
    (5, [
        r"فرق[هة]\s*خامس[هة]?", r"الفرق[هة]\s*الخامس[هة]?", r"السن[هة]\s*الخامس[هة]?",
        r"المستو[يى]\s*الخامس", r"خامس[هة]?\s*فرق[هة]",
        r"الخامس[هة]?", r"فرق[هة]\s*5", r"سن[هة]\s*5",
        r"fifth\s*year", r"year\s*5", r"level\s*5", r"5th\s*year",
    ]),
]

# Compile all patterns
_YEAR_COMPILED: list[tuple[int, list[re.Pattern]]] = [
    (yr, [re.compile(p, re.IGNORECASE | re.UNICODE) for p in pats])
    for yr, pats in _YEAR_PATTERNS
]


def _detect_year(text: str) -> Optional[int]:
    """Return academic year (1–4) or None."""
    norm = _normalize_ar(text)
    combined = norm + " " + text.lower()
    for year, patterns in _YEAR_COMPILED:
        for pat in patterns:
            if pat.search(combined):
                return year
    return None


# ─────────────────────────────────────────────────────────────────────────────
# Semester detection
# ─────────────────────────────────────────────────────────────────────────────

_SEM1_PATTERNS = re.compile(
    r"ترم\s*اول|الترم\s*الاول|فصل\s*اول|الفصل\s*الاول|"
    r"semester\s*1|first\s*semester|sem\s*1|term\s*1",
    re.IGNORECASE | re.UNICODE,
)
_SEM2_PATTERNS = re.compile(
    r"ترم\s*تاني|الترم\s*التاني|فصل\s*تاني|الفصل\s*الثاني|"
    r"semester\s*2|second\s*semester|sem\s*2|term\s*2",
    re.IGNORECASE | re.UNICODE,
)


def _detect_semester(text: str) -> Optional[int]:
    norm = _normalize_ar(text)
    combined = norm + " " + text.lower()
    if _SEM1_PATTERNS.search(combined):
        return 1
    if _SEM2_PATTERNS.search(combined):
        return 2
    return None


# ─────────────────────────────────────────────────────────────────────────────
# Intent detection
# ─────────────────────────────────────────────────────────────────────────────



# ── Compound patterns checked BEFORE single-word patterns ────────────────────
# These catch multi-word phrases that would otherwise be misclassified.
# e.g. "تسجيل التدريب" → regulations (not registration)
# Order matters: more specific compound patterns first.
_COMPOUND_INTENT_PATTERNS: list[tuple[str, list[str]]] = [
    ("regulations", [
        # Summer / field training — must beat "registration" (which catches "تسجيل")
        r"تدريب\s*صيفي",
        r"التدريب\s*الصيفي",
        r"تدريب\s*ميداني",
        r"التدريب\s*الميداني",
        r"تدريب\s*عملي",
        r"التدريب\s*العملي",
        r"شروط\s*التدريب",
        r"متطلبات\s*التدريب",
        r"موعد\s*التدريب",
        r"متى\s*(?:يتم|يبدأ|ينتهي)\s*التدريب",
        r"امتى\s*(?:بدأ|بيبدأ|يبدأ)\s*التدريب",
        r"(?:كيف|كيفية)\s*(?:تسجيل|الالتحاق|الانضمام)\s*(?:ب)?التدريب",
        r"تسجيل\s*(?:في\s*)?(?:ال)?تدريب",
        r"internship",
        r"field\s*training",
        r"summer\s*training",
        r"practical\s*training",
    ]),
]

_COMPOUND_INTENT_COMPILED: list[tuple[str, list[re.Pattern]]] = [
    (intent, [re.compile(p, re.IGNORECASE | re.UNICODE) for p in pats])
    for intent, pats in _COMPOUND_INTENT_PATTERNS
]


_INTENT_PATTERNS = [
    ("subjects list", [
        r"مواد", r"ماد[هة]", r"مقررات", r"مقرر", r"كورسات", r"كورس",
        r"subjects?", r"courses?", r"modules?", r"curriculum",
    ]),
    ("exam schedule", [
        r"امتحانات", r"امتحان", r"جدول\s*امتحان", r"موعد\s*امتحان",
        r"exams?", r"exam\s*schedule", r"test\s*dates?",
    ]),
    ("grades", [
        r"درجات", r"درج[هة]", r"نتيج[هة]", r"نتائج", r"رسوب", r"نجاح", r"تقدير", r"تقديرات",
        r"grades?", r"marks?", r"results?", r"gpa", r"pass", r"fail",
    ]),
    ("schedule", [
        r"جدول\s*محاضرات", r"جدول\s*الدراس[هة]", r"مواعيد", r"توقيت",
        r"schedule", r"timetable", r"lecture\s*times?",
    ]),
    ("registration", [
        # Note: bare "تسجيل" is here, but compound "تسجيل التدريب" is caught
        # earlier by _COMPOUND_INTENT_PATTERNS → regulations.
        r"تسجيل", r"قيد", r"تسجيل\s*مواد",
        r"registr", r"enroll", r"sign\s*up",
    ]),
    ("fees", [
        r"مصروفات", r"رسوم", r"مصاريف",
        r"fees?", r"tuition", r"payment",
    ]),
    ("graduation", [
        r"تخرج", r"شهاد[هة]", r"دبلوم",
        r"graduat", r"degree", r"diploma", r"certificate",
    ]),
    ("regulations", [
        r"لائح[هة]", r"قوانين", r"قانون", r"نظام", r"شروط", r"قواعد", r"ضوابط", r"متطلبات",
        r"حقوق\s*الطالب", r"واجبات\s*الطالب", r"حقوق", r"واجبات",
        r"انسحاب", r"الانسحاب", r"اجراءات\s*الانسحاب",
        r"شكوى", r"شكاوى", r"تظلم",
        r"منحة", r"منح\s*دراسية",
        r"مدة\s*الدراسة", r"مدة\s*البرنامج", r"سنوات\s*الدراسة",
        r"كم\s*سنة", r"كم\s*عام", r"كم\s*فصل",
        r"تنقسم\s*الدراسة", r"مراحل\s*الدراسة",
        # Training-related regulations (kept here as backup)
        r"تدريب", r"التدريب",
        r"regulat", r"rules?", r"policy", r"policies", r"requirements?", r"conditions?",
        r"rights?", r"student\s*rights?", r"responsibilities?", r"duties?",
        r"withdrawal", r"withdraw", r"drop\s*course",
        r"complaint", r"grievance",
        r"scholarship", r"grant", r"financial\s*aid",
        r"duration", r"how\s*many\s*years?", r"how\s*long",
        r"study\s*period", r"program\s*duration",
    ]),
    ("professors", [
        r"دكتور", r"استاذ", r"مدرس", r"هيئ[هة]\s*تدريس",
        r"professor", r"lecturer", r"instructor", r"faculty",
    ]),
    ("departments", [
        r"قسم", r"اقسام", r"تخصصات", r"تخصص", r"علمي[هة]", r"برامج", r"برنامج",
        r"department", r"division", r"branch", r"major", r"majors", r"specialization",
        r"what\s+majors", r"available\s+majors", r"available\s+programs",
    ]),
]

_INTENT_COMPILED: list[tuple[str, list[re.Pattern]]] = [
    (intent, [re.compile(p, re.IGNORECASE | re.UNICODE) for p in pats])
    for intent, pats in _INTENT_PATTERNS
]


def _detect_intent(text: str) -> str:
    """Return the most likely intent label.

    Two-pass detection:
      Pass 1: compound patterns (_COMPOUND_INTENT_PATTERNS) — higher specificity,
              catches multi-word phrases like 'تسجيل التدريب' before bare 'تسجيل'.
      Pass 2: single-word patterns (_INTENT_PATTERNS) — normal matching.
    """
    norm = _normalize_ar(text)
    combined = norm + " " + text.lower()

    # Pass 1: compound (high-priority) patterns
    for intent, patterns in _COMPOUND_INTENT_COMPILED:
        for pat in patterns:
            if pat.search(combined):
                return intent

    # Pass 2: standard single-word patterns
    for intent, patterns in _INTENT_COMPILED:
        for pat in patterns:
            if pat.search(combined):
                return intent

    return "general"


# ─────────────────────────────────────────────────────────────────────────────
# Clean query rewriter
# ─────────────────────────────────────────────────────────────────────────────

_YEAR_EN = {
    0: "level 0 preparatory prep year",
    1: "level 1 first year",
    2: "level 2 second year",
    3: "level 3 third year",
    4: "level 4 fourth year",
    5: "level 5 fifth year",
}
_SEM_EN  = {1: "semester 1", 2: "semester 2"}

_INTENT_EN: dict[str, str] = {
    # Issue 2: expanded keyword sets for better retrieval coverage
    "subjects list":  "subjects courses curriculum study plan program academic year semester course list",
    "exam schedule":  "exam schedule dates assessment timetable",
    "grades":         "grades marks results grading system pass fail",
    "schedule":       "lecture schedule timetable academic calendar",
    "registration":   "course registration enrollment academic",
    "fees":           "tuition fees payment academic",
    "graduation":     "graduation requirements degree academic program",
    "regulations":    "regulations rules requirements academic policy success passing criteria conditions",
    "professors":     "professors faculty instructors academic staff",
    "departments":    "departments divisions branches sections academic specialized fields",
    "general":        "",
}


def _build_clean_query(
    program: Optional[str | list[str]],
    year: Optional[int],
    semester: Optional[int],
    intent: str,
    original: str,
) -> str:
    """
    Build a clean semantic search query from extracted intent.
    """
    parts: list[str] = []
    if year:
        parts.append(_YEAR_EN[year])
    if program:
        if isinstance(program, list):
            parts.append(" ".join(program))
        else:
            parts.append(program)
    if semester:
        parts.append(_SEM_EN[semester])
    intent_words = _INTENT_EN.get(intent, "")
    if intent_words:
        parts.append(intent_words)

    if not parts:
        return _normalize_ar(original)

    english_part = " ".join(parts)
    arabic_suffix = _normalize_ar(original)
    if arabic_suffix and arabic_suffix != english_part:
        return f"{english_part} {arabic_suffix}"
    return english_part


def _build_query_variants(
    program: Optional[str | list[str]],
    year: Optional[int],
    semester: Optional[int],
    intent: str,
    clean_query: str,
    original: str,
) -> list[str]:
    """
    Generate alternative query phrasings for multi-query retrieval.
    """
    norm_orig = _normalize_ar(original)
    variants: list[str] = [norm_orig]

    english_parts: list[str] = []
    if year:
        english_parts.append(_YEAR_EN[year])
    if program:
        if isinstance(program, list):
            english_parts.append(" ".join(program))
        else:
            english_parts.append(program)
    if semester:
        english_parts.append(_SEM_EN[semester])
    intent_words = _INTENT_EN.get(intent, "")
    if intent_words:
        english_parts.append(intent_words)

    if english_parts:
        english_query = " ".join(english_parts)
        if english_query not in variants:
            variants.append(english_query)

    # Variant 2: Arabic structured query
    ar_parts: list[str] = []
    if year:
        ar_parts.append(["الفرقة الأولى", "الفرقة الثانية",
                          "الفرقة الثالثة", "الفرقة الرابعة"][year - 1])
    if program:
        _prog_ar = {
            "computer science": "حاسبات",
            "engineering":      "هندسة",
            "medicine":         "طب",
            "pharmacy":         "صيدلة",
            "law":              "حقوق",
            "commerce":         "تجارة",
            "arts":             "آداب",
            "science":          "علوم",
            "education":        "تربية",
            "nursing":          "تمريض",
            "physical therapy":  "علاج طبيعي",
            "veterinary":        "طب بيطري",
            "dentistry":        "طب أسنان",
        }
        if isinstance(program, list):
            ar_parts.append(" و ".join(_prog_ar.get(p, p) for p in program))
        else:
            ar_parts.append(_prog_ar.get(program, program))
    if semester:
        ar_parts.append(f"الترم {['الأول', 'الثاني'][semester - 1]}")
    _intent_ar = {
        "subjects list":  "مواد ومقررات",
        "exam schedule":  "جدول الامتحانات",
        "grades":         "درجات ونتائج",
        "schedule":       "جدول المحاضرات",
        "registration":   "تسجيل المواد",
        "fees":           "المصروفات والرسوم",
        "graduation":     "متطلبات التخرج",
        "regulations":    "اللائحة والقوانين",
        "professors":     "أعضاء هيئة التدريس",
        "general":        "",
    }
    intent_ar = _intent_ar.get(intent, "")
    if intent_ar:
        ar_parts.append(intent_ar)

    if ar_parts:
        arabic_query = " ".join(ar_parts)
        if arabic_query not in variants:
            variants.append(arabic_query)

    return variants[:3]


# ─────────────────────────────────────────────────────────────────────────────
# Confidence scoring
# ─────────────────────────────────────────────────────────────────────────────

def _score_confidence(
    program: Optional[str],
    year: Optional[int],
    semester: Optional[int],
    intent: str,
) -> float:
    score = 0.3  # base
    if program:
        score += 0.3
    if year:
        score += 0.25
    if semester:
        score += 0.1
    if intent != "general":
        score += 0.05
    return min(score, 1.0)


# ─────────────────────────────────────────────────────────────────────────────
# Tier 2: LLM-based intent classifier
# ─────────────────────────────────────────────────────────────────────────────

# Known program names for the LLM prompt
_KNOWN_PROGRAMS = [
    "computer science", "engineering", "medicine", "dentistry",
    "pharmacy", "law", "commerce", "arts", "science", "education", "nursing",
]

_LLM_CLASSIFIER_PROMPT = """\
You are an expert university query analyzer. Your PRIMARY job is to detect the specific academic program/faculty the user is asking about, even if it is not explicitly named.
Given a student question, extract:
1. program  — the academic faculty/program the question belongs to.
   Must be one of: {programs}
   CRITICAL: You MUST map implicitly related terms to the correct program. 
   - Examples: "database", "programming", "AI", "خوارزميات" -> computer science
   - Examples: "anatomy", "جراحة", "تشريح" -> medicine
   - Examples: "قانون", "دستور", "محكمة" -> law
   - Examples: "اقتصاد", "محاسبة", "تسويق" -> commerce
   If the question is purely administrative (e.g., "شروط القبول", "التسجيل", "الرسوم", "رئيس الجامعة"), return "general".
   Only return null if the query is complete gibberish.
2. intent   — one of: subjects_list, exam_schedule, grades, schedule,
               registration, fees, graduation, regulations, professors, general
3. confidence — float 0.0–1.0 for your classification

Return ONLY valid JSON, no explanation:
{{"program": "...", "intent": "...", "confidence": 0.0}}

Question: {query}
"""

_VALID_PROGRAMS = set(_KNOWN_PROGRAMS)
_VALID_INTENTS  = {
    "subjects_list", "exam_schedule", "grades", "schedule",
    "registration", "fees", "graduation", "regulations", "professors", "general",
}
# Map LLM intent names → internal intent names
_INTENT_MAP = {
    "subjects_list": "subjects list",
    "exam_schedule": "exam schedule",
    "grades":        "grades",
    "schedule":      "schedule",
    "registration":  "registration",
    "fees":          "fees",
    "graduation":    "graduation",
    "regulations":   "regulations",
    "professors":    "professors",
    "general":       "general",
}

# ── Intent result cache ───────────────────────────────────────────────────────
# Keyed on normalised query text → cached LLM result dict.
# Prevents repeated LLM calls for the same (or near-identical) query.
# Max size: 256 entries (covers a full session comfortably).
# Thread-safe: dict operations in CPython are GIL-protected.
_INTENT_CACHE: dict[str, dict] = {}
_INTENT_CACHE_MAX = 256

# Minimum query length to consider LLM classification worthwhile.
# Very short queries (< 4 words) are usually clear enough for rule-based.
_LLM_MIN_WORDS = 4

# Ambiguity signals: words/patterns that suggest the query is about a
# domain topic rather than a named program. LLM is only called when at
# least one of these is present AND rule-based found no program.
_AMBIGUITY_TERMS_EN = {
    "normaliz", "index", "algorithm", "data struct", "network", "protocol",
    "circuit", "thermodynam", "organic", "anatomy", "pharmacolog",
    "jurisprudence", "accounting", "audit", "macroeconom", "microeconom",
    "pedagog", "curriculum design", "sorting", "searching", "recursion",
    "inheritance", "polymorphism", "encryption", "compression",
}
_AMBIGUITY_TERMS_AR_RAW = {
    "خوارزميات", "هياكل بيانات", "شبكات", "بروتوكول", "دوائر",
    "ديناميكا", "عضوية", "تشريح", "صيدلانيات", "فقه",
    "محاسبة", "اقتصاد كلي", "مناهج دراسية", "تشفير", "ضغط بيانات",
    "وراثة", "تعددية", "تكرار",
}
# Pre-normalise Arabic terms so they match the normalised query text
_AMBIGUITY_TERMS_AR = {_normalize_ar(t) for t in _AMBIGUITY_TERMS_AR_RAW}


def _llm_classify(query: str, llm) -> Optional[dict]:
    """
    Call the LLM to classify program + intent for an ambiguous query.

    Returns dict with keys: program, intent, confidence
    Returns None on any failure (network error, bad JSON, etc.)

    Design principles:
    - Cache-first: normalised query checked against _INTENT_CACHE before
      any LLM call. Cache hit = zero latency, zero tokens.
    - Single short prompt → minimal tokens, fast response
    - Structured JSON output → no parsing ambiguity
    - Fails silently → rule-based result is used as fallback
    - Never raises — all exceptions are caught and logged
    """
    # ── Cache lookup ──────────────────────────────────────────────────────
    cache_key = _normalize_ar(query).lower().strip()
    if cache_key in _INTENT_CACHE:
        logger.debug("[llm_classify] Cache hit for '%s'", query[:50])
        return _INTENT_CACHE[cache_key]

    prompt = _LLM_CLASSIFIER_PROMPT.format(
        programs=", ".join(_KNOWN_PROGRAMS),
        query=query[:300],   # cap at 300 chars to limit tokens
    )
    try:
        response = llm.invoke(prompt)
        raw = response.content if hasattr(response, "content") else str(response)

        # Extract JSON from response (handle markdown code blocks)
        json_match = re.search(r"\{[^{}]+\}", raw, re.DOTALL)
        if not json_match:
            logger.debug("[llm_classify] No JSON found in response: %s", raw[:100])
            return None

        data = json.loads(json_match.group())

        # Validate fields
        program    = data.get("program")
        intent_raw = data.get("intent", "general")
        confidence = float(data.get("confidence", 0.5))

        if program and program not in _VALID_PROGRAMS:
            logger.debug("[llm_classify] Unknown program: %s", program)
            program = None

        intent = _INTENT_MAP.get(intent_raw, "general")

        result = {
            "program":    program,
            "intent":     intent,
            "confidence": min(max(confidence, 0.0), 1.0),
        }

        # ── Cache store (evict oldest if full) ────────────────────────────
        if len(_INTENT_CACHE) >= _INTENT_CACHE_MAX:
            # Remove the first (oldest) entry — dict preserves insertion order
            try:
                oldest = next(iter(_INTENT_CACHE))
                del _INTENT_CACHE[oldest]
            except StopIteration:
                pass
        _INTENT_CACHE[cache_key] = result
        logger.debug("[llm_classify] Cached result for '%s'", query[:50])

        return result

    except Exception as e:
        logger.debug("[llm_classify] Failed: %s", e)
        return None


def _is_ambiguous_query(query: str, normalized: str) -> bool:
    """
    Return True when the LLM classifier should be called.
    We are now being aggressive: if the program wasn't detected by rules,
    and the query has at least 2 words, we call the LLM to aggressively infer it.
    """
    if len(query.split()) < 2:
        return False
    return True


# ─────────────────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────────────────

def understand_query(raw_query: str, llm=None) -> QueryIntent:
    """
    Parse a raw user query (Arabic, English, or mixed) into a structured
    QueryIntent object.

    Two-tier pipeline:
      Tier 1: Rule-based (always runs, zero latency)
      Tier 2: LLM-based (runs only when confidence < LOW_CONF_THRESHOLD
               AND llm is provided)

    Parameters
    ----------
    raw_query : str
        The user's question exactly as typed.
    llm : optional
        A LangChain-compatible LLM instance. When provided and rule-based
        confidence is low, the LLM classifier is called to improve accuracy.
        If None, only the rule-based tier runs.

    Returns
    -------
    QueryIntent
        Structured intent with program, year, semester, intent label,
        clean rewritten query, query variants, and classifier_tier.
    """
    normalized = _normalize_ar(raw_query)
    lower_en   = raw_query.lower()

    # ── Tier 1: Rule-based ────────────────────────────────────────────────
    programs = _detect_all_programs(raw_query)
    if len(programs) > 1:
        program = programs
    elif len(programs) == 1:
        program = programs[0]
    else:
        program = None

    year     = _detect_year(raw_query)
    semester = _detect_semester(raw_query)
    intent   = _detect_intent(raw_query)
    confidence = _score_confidence(program, year, semester, intent)
    classifier_tier = "rule_based"

    # ── Tier 2: LLM classifier (lazy fallback — strict trigger conditions) ─
    if (
        llm is not None
        and program is None
        and _is_ambiguous_query(raw_query, normalized)
    ):
        logger.info(
            "[understand_query] Ambiguous query (conf=%.2f, %d words) — "
            "checking cache then LLM: '%s'",
            confidence, len(raw_query.split()), raw_query[:60],
        )
        llm_result = _llm_classify(raw_query, llm)
        if llm_result and llm_result["confidence"] > confidence:
            program    = llm_result["program"]    or program
            intent     = llm_result["intent"]     or intent
            confidence = llm_result["confidence"]
            classifier_tier = "llm_assisted"
            logger.info(
                "[understand_query] LLM classified: program=%s intent=%s conf=%.2f",
                program, intent, confidence,
            )

    clean_query = _build_clean_query(program, year, semester, intent, raw_query)
    variants    = _build_query_variants(
        program, year, semester, intent, clean_query, raw_query
    )

    return QueryIntent(
        raw_query        = raw_query,
        normalized_query = normalized,
        clean_query      = clean_query,
        program          = program,
        year             = year,
        semester         = semester,
        intent           = intent,
        query_variants   = variants,
        confidence       = confidence,
        metadata_filter  = {},
        classifier_tier  = classifier_tier,
    )
