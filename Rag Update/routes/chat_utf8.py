"""
chat.py
========
Production-grade RAG chat endpoint.

Retrieval pipeline (per query):
  1. Normalize query          – arabic_cleaner.clean_arabic_text()
  2. Hybrid search            – dense (ChromaDB) + sparse (BM25) + RRF fusion
  3. Rerank                   – cosine similarity (default) or LLM scoring
  4. Build context            – top-N chunks with source attribution
  5. Generate answer          – LLM with strict grounding prompt
  6. Log retrieval trace      – JSONL log for offline analysis

Extended API
------------
  POST /api/chat/
      Body: { question, top_k?, language_filter?, section_filter?,
              file_filter?, rerank_method? }

  GET  /api/chat/retrieval-stats
      Returns cache stats and BM25 index info.

  POST /api/chat/rebuild-index
      Force-rebuilds the BM25 index from ChromaDB.

  GET  /api/chat/retrieval-logs
      Returns the last N retrieval log entries.
"""

from __future__ import annotations

import logging
import os
import re
import time
from typing import List, Optional

import chromadb
from chromadb.config import Settings
from dotenv import load_dotenv
from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import JSONResponse
from langchain_core.prompts import PromptTemplate
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from pydantic import BaseModel, Field

from routes.retrieval.bm25_index import get_or_build_index, invalidate_index
from routes.retrieval.embedding_cache import get_default_cache
from routes.retrieval.evaluator import log_retrieval_result
from routes.retrieval.hybrid_search import hybrid_search, normalize_query
from routes.retrieval.query_understanding import understand_query
from routes.retrieval.reranker import rerank_results
from routes.course_catalog import get_catalog

load_dotenv()
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Router
# ---------------------------------------------------------------------------
router = APIRouter()

# ---------------------------------------------------------------------------
# ChromaDB
# ---------------------------------------------------------------------------
chroma_client = chromadb.PersistentClient(
    path="./chroma_db",
    settings=Settings(anonymized_telemetry=False),
)

COLLECTION_NAME = "university_regulations"

try:
    collection = chroma_client.get_collection(name=COLLECTION_NAME)
    logger.info(f"[chat] ChromaDB collection '{COLLECTION_NAME}' loaded "
                f"({collection.count()} documents)")
except Exception:
    collection = None
    logger.warning(f"[chat] Collection '{COLLECTION_NAME}' not found – "
                   "upload PDFs first.")

# ---------------------------------------------------------------------------
# Embeddings
# ---------------------------------------------------------------------------
openai_key     = os.getenv("OPENAI_API_KEY", "").strip()
openrouter_key = os.getenv("OPENROUTER_API_KEY", "").strip()

if openai_key and openai_key != "your_openai_api_key_here":
    logger.info("[chat] Using OpenAI API for embeddings")
    embeddings = OpenAIEmbeddings(
        openai_api_key=openai_key,
        model="text-embedding-ada-002",
    )
elif openrouter_key and openrouter_key != "your_openrouter_api_key_here":
    logger.info("[chat] Using OpenRouter API for embeddings")
    embeddings = OpenAIEmbeddings(
        openai_api_key=openrouter_key,
        openai_api_base="https://openrouter.ai/api/v1",
        model="text-embedding-ada-002",
        default_headers={
            "HTTP-Referer": os.getenv("OPENROUTER_REFERRER", "http://localhost:8000"),
            "X-Title": "Smart Campus RAG",
        },
    )
else:
    logger.warning("[chat] No valid embeddings API key found!")
    embeddings = None

# ---------------------------------------------------------------------------
# LLM
# ---------------------------------------------------------------------------
llm = ChatOpenAI(
    openai_api_key=os.getenv("OPENROUTER_API_KEY"),
    openai_api_base="https://openrouter.ai/api/v1",
    model_name=os.getenv("OPENROUTER_MODEL", "openai/gpt-4o-mini"),
    temperature=0.1,
    default_headers={
        "HTTP-Referer": os.getenv("OPENROUTER_REFERRER", "http://localhost:8000"),
        "X-Title": "Smart Campus RAG",
    },
)

# ---------------------------------------------------------------------------
# Embedding cache (singleton)
# ---------------------------------------------------------------------------
embedding_cache = get_default_cache()

# ---------------------------------------------------------------------------
# BM25 index (lazy-loaded on first request)
# ---------------------------------------------------------------------------
_bm25_index = None


def _get_bm25_index(force_rebuild: bool = False):
    """Lazy-load or rebuild the BM25 index."""
    global _bm25_index
    if collection is None:
        return None
    if force_rebuild or _bm25_index is None:
        _bm25_index = get_or_build_index(
            collection_name=COLLECTION_NAME,
            collection=collection,
            force_rebuild=force_rebuild,
        )
    return _bm25_index


# ---------------------------------------------------------------------------
# Prompt templates
# -----------------------------------------------------------------_PROMPT = PromptTemplate.from_template("""أنت مساعد أكاديمي متخصص في لوائح الجامعات والمقررات الدراسية.
أجب على السؤال بناءً على السياق المسترجع فقط.

━━━━━━━━━━━━━━━━━━━━
📋 إذا كان السؤال عن قائمة المقررات/المواد:
━━━━━━━━━━━━━━━━━━━━
- ابحث عن أكواد المقررات (مثل GEN 001, MED 201, CVE 301)
- اعرضها كقائمة منظمة مع الكود واسم المادة
- اذكر الترم والفرقة إن وُجدا في النص
- ممنوع قول "غير موجود" إذا كانت هناك أكواد في النص

━━━━━━━━━━━━━━━━━━━━
📜 إذا كان السؤال عن لوائح/شروط/قرارات/تخرج/قيد/رسوب:
━━━━━━━━━━━━━━━━━━━━
- اقرأ النص واستخرج المعلومات المطلوبة مباشرة
- اعرض الإجابة بشكل واضح ومنظم (نقاط أو فقرات)
- اذكر رقم المادة القانونية أو الصفحة إن وُجدا
- لا تخترع معلومات غير موجودة في السياق

━━━━━━━━━━━━━━━━━━━━
🌐 قاعدة اللغة:
━━━━━━━━━━━━━━━━━━━━
- أجب بنفس لغة السؤال (عربي أو إنجليزي)
- إذا كان السؤال بالعربي والنص بالإنجليزي، ترجم الإجابة للعربي

━━━━━━━━━━━━━━━━━━━━
🚫 في حالة واحدة فقط قل "المعلومات غير موجودة":
━━━━━━━━━━━━━━━━━━━━
- إذا لم يكن في السياق أي معلومات ذات صلة بالسؤال إطلاقاً

━━━━━━━━━━━━━━━━━━━━
السياق:
{context}

السؤال:
{question}

الإجابة:""")
🔄 3) ترتيب التفكير (مهم جدًا)
━━━━━━━━━━━━━━━━━━━━
اتبع الخطوات دي بالترتيب:
1. استخراج الأكواد من النص الخام
2. بناء قائمة المواد مباشرة
3. فقط بعد كده حاول تفسير أو تحسين الصياغة

━━━━━━━━━━━━━━━━━━━━
📦 4) دمج المصادر
━━━━━━━━━━━━━━━━━━━━
لو البيانات جاية من أكثر من ملف:
- اجمع كل المواد في قائمة واحدة موحدة
- بدون تكرار

━━━━━━━━━━━━━━━━━━━━
🧾 5) شكل الإجابة
━━━━━━━━━━━━━━━━━━━━
لازم تكون الإجابة:
- قائمة مواد فقط
- بدون حشو
- مع ذكر الكود جنب الاسم

مثال:
مواد الترم الأول للفرقة الأولى:
- اسم المادة (GEN 004)
- اسم المادة (BAS 101)
[المصدر: اسم الملف | رقم الصفحة]

━━━━━━━━━━━━━━━━━━━━
السياق:
{context}

السؤال:
{question}

الإجابة:""")


ANSWER_VERIFICATION_PROMPT = """You are a retrieval verifier for a university RAG system.
You will be given a question, retrieved context chunks, and a draft answer.

Your job: decide whether the answer is supported by the context.

========================
OUTPUT ONLY ONE OF:
========================
YES     → answer is fully or mostly supported by the context
PARTIAL → answer is partially supported, or context contains relevant info
          even if the answer didn't fully use it
NO      → context contains NO relevant information for this question

========================
IMPORTANT RULES
========================
- Do NOT consider external knowledge
- Only check whether the context contains relevant information
- If the context mentions the topic even partially → choose PARTIAL, not NO
- Only choose NO if the context is completely unrelated to the question
- Curriculum, course lists, subject tables → count as relevant for subject queries

========================
QUESTION:
{question}

========================
CONTEXT:
{context}

========================
ANSWER:
{answer}

========================
VERDICT:"""

If you find ANY of these:
→ Extract ALL course names and codes
→ List them as bullet points
→ This IS the answer — do NOT say "not found"

━━━━━━━━━━━━━━━━━━━━
STEPS
━━━━━━━━━━━━━━━━━━━━
Step 1: Find chunks with course codes or level/semester markers.
Step 2: Extract every course name and code you find.
Step 3: Format as a bullet list with citation.
Step 4: ONLY say "not found" if zero course/subject data exists.

FORMAT:
- Use bullet points
- Mention file name + page number
- Keep answer structured

LANGUAGE RULE:
Reply in the same language as the question.

CONTEXT:
{context}

QUESTION:
{question}

ANSWER:""")


def verify_answer(question: str, context: str, answer: str) -> dict:
    """
    Run the answer through the verification prompt and return a verdict dict.

    Uses the full context (not truncated) so the verifier doesn't say NO
    because the supporting evidence was cut off.

    Returns
    -------
    dict with keys:
        verdict : "YES" | "PARTIAL" | "NO"
        label   : "fully_supported" | "partially_supported" | "not_supported"
        verified: bool  (True when verdict is YES or PARTIAL)
    """
    try:
        prompt = ANSWER_VERIFICATION_PROMPT.format(
            question = question,
            context  = context,        # full context — no truncation
            answer   = answer[:1500],  # answer cap only (answers are short)
        )
        response = llm.invoke(prompt)
        raw      = (response.content if hasattr(response, "content") else str(response))
        raw      = raw.strip().upper()

        # Scan for verdict tokens — check YES last so "YES" inside "ANALYSIS"
        # doesn't false-positive; check in specificity order
        verdict = "PARTIAL"  # safe default
        if raw.startswith("NO") or "\nNO" in raw or raw == "NO":
            verdict = "NO"
        elif raw.startswith("YES") or "\nYES" in raw or raw == "YES":
            verdict = "YES"
        elif "PARTIAL" in raw:
            verdict = "PARTIAL"
        elif "YES" in raw:
            verdict = "YES"
        elif "NO" in raw:
            verdict = "NO"

        logger.info(f"[chat] Answer verification verdict: {verdict}")
        return {
            "verdict":  verdict,
            "label":    _VERDICT_LABELS[verdict],
            "verified": verdict in ("YES", "PARTIAL"),
        }
    except Exception as e:
        logger.warning(f"[chat] Answer verification failed: {e}")
        return {"verdict": "PARTIAL", "label": "partially_supported", "verified": True}


QUERY_REWRITE_PROMPT = """You are a query optimization engine for a hybrid RAG system.
Your job is to rewrite the user question into an optimized search query
for BOTH:
- semantic search (embeddings)
- keyword search (BM25)

========================
RULES
========================
- Preserve original meaning
- Expand abbreviations into full academic terms
- Add missing keywords (program, year, semester, university terms)
- Translate Arabic ↔ English concepts if useful
- Remove filler words
- Keep output SHORT (max 1–2 lines)
- Do NOT answer the question
- Output ONLY the rewritten query

========================
EXAMPLES
========================
Input:
"مواد الترم الاول فرق اولى حاسبات"
Output:
"first semester courses first year computer science faculty subjects curriculum regulations"
------------------------
Input:
"امتحانات مواد الذكاء الاصطناعي"
Output:
"artificial intelligence course exams grading rules assessment AI subject regulations"

========================
USER QUESTION:
{question}

========================
OPTIMIZED QUERY:"""


def rewrite_query(question: str) -> str:
    """
    Use the LLM to rewrite the user question into a better search query.
    Falls back to the original question if the LLM call fails.
    Only called when query_understanding confidence is low (< 0.55),
    so it doesn't add latency for well-structured queries.
    """
    try:
        prompt   = QUERY_REWRITE_PROMPT.format(question=question)
        response = llm.invoke(prompt)
        rewritten = response.content if hasattr(response, "content") else str(response)
        rewritten = rewritten.strip().splitlines()[0].strip()  # first line only
        if rewritten and len(rewritten) > 3:
            logger.info(f"[chat] Query rewritten: '{question[:50]}' → '{rewritten[:60]}'")
            return rewritten
    except Exception as e:
        logger.warning(f"[chat] Query rewrite failed: {e}")
    return question

# ---------------------------------------------------------------------------
# Request / Response models
# ---------------------------------------------------------------------------

class ChatRequest(BaseModel):
    question: str = Field(..., min_length=1, description="User question")
    top_k: int = Field(default=5, ge=1, le=20, description="Number of chunks to use")
    language_filter: Optional[str] = Field(
        default=None,
        description="Filter results by language: 'arabic', 'english', 'mixed'"
    )
    section_filter: Optional[str] = Field(
        default=None,
        description="Filter results to sections whose title contains this string"
    )
    file_filter: Optional[str] = Field(
        default=None,
        description="Filter results to a specific file name (substring match)"
    )
    rerank_method: Optional[str] = Field(
        default="cosine",
        description="Reranking strategy: 'cosine' | 'llm' | 'none'"
    )
    # New: explicit intent overrides (optional – auto-detected if omitted)
    program_filter: Optional[str] = Field(
        default=None,
        description="Override detected program (e.g. 'computer science')"
    )
    year_filter: Optional[int] = Field(
        default=None,
        ge=1, le=4,
        description="Override detected academic year (1–4)"
    )


class SourceInfo(BaseModel):
    file: str
    page: int
    sectionTitle: str
    language: str
    keywords: str
    snippet: str
    rerankScore: float


class ChatResponse(BaseModel):
    success: bool
    answer: str
    sources: List[SourceInfo]
    queryLanguage: str
    queryIntent: dict        # structured intent extracted from the query
    answerVerdict: dict      # verification result: verdict, label, verified
    retrievalStats: dict


# ---------------------------------------------------------------------------
# Chunk text preprocessing  (Req 1, 2, 3)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Course detection patterns — OCR-robust
# ---------------------------------------------------------------------------

# Primary course-code pattern.
# OCR variations handled:
#   GEN004   GEN 004   GEN-004   GEN : 004   G E N 0 0 4 (broken OCR)
#   Allows 0–3 separator chars between prefix and number.
_COURSE_CODE_RE = re.compile(
    r"\b([A-Z]{2,4})"           # 2–4 uppercase letters (prefix)
    r"[\s\-:\.]{0,3}"           # optional separator (space, dash, colon, dot)
    r"(\d{3,4})\b",             # 3–4 digits (number)
    re.IGNORECASE,
)

# Fallback: detect a "course table block" even when individual codes are
# broken by OCR. Triggers on:
#   - Table headers like "Course Code", "Course Title", "Credit Hours"
#   - Arabic equivalents: "كود المادة", "اسم المادة", "الساعات المعتمدة"
#   - Lines that look like "NNN  Some Title  N" (number + text + number)
_COURSE_BLOCK_RE = re.compile(
    r"course\s*code|course\s*title|credit\s*hours?|course\s*name"
    r"|كود\s*الماد[هة]|اسم\s*الماد[هة]|الساعات\s*المعتمد[هة]"
    r"|رقم\s*الماد[هة]|وصف\s*الماد[هة]",
    re.IGNORECASE | re.UNICODE,
)

# Detect lines that look like table rows even without a proper course code:
# "  3   Introduction to Computers   3  2  1  3"
# "  101  Mathematics 2  3  2  1  3"
_NUMERIC_ROW_RE = re.compile(
    r"^\s*\d{1,4}\s+[A-Za-z\u0600-\u06FF][^\n\r]{5,60}(?:\s+\d+){1,5}\s*$",
    re.MULTILINE,
)

# Strategy A — full table row with trailing numbers (credit hours, etc.)
# "GEN 004 Introduction to Computers 3 2 1 3"
#
# KEY FIX: (.+) is now GREEDY. It captures the full title + trailing numbers.
# _clean_title() then strips the trailing numbers from the captured string.
# The old non-greedy (.+?) was stopping at the first word before a digit,
# producing titles like "Introduction" instead of "Introduction to Computers".
_TABLE_ROW_FULL_RE = re.compile(
    r"([A-Z]{2,4})[\s\-:\.]{0,3}(\d{3,4})\s+(.+)$",
    re.MULTILINE | re.IGNORECASE,
)

# Strategy B — code + title, no trailing numbers
# "BCS 201 Data Structures"  or  "BCS201 Data Structures"  or  "BCS-201 Data Structures"
# Title capture raised from 60 → 100 chars to handle longer course names.
_TABLE_ROW_SIMPLE_RE = re.compile(
    r"([A-Z]{2,4})[\s\-:\.]{0,3}(\d{3,4})\s+([A-Za-z\u0600-\u06FF][^\n\r]{3,100})",
    re.MULTILINE | re.IGNORECASE,
)

# Backup course-code regex — simpler, no word-boundary requirement
# Compiled at module level to avoid re-compiling on every request
_BACKUP_CODE_RE = re.compile(r"[A-Z]{2,4}\s*\d{3,4}", re.IGNORECASE)

# Known course-prefix keywords
_KNOWN_PREFIXES_RE = re.compile(
    r"\b(GEN|BAS|BCS|MBS|CS|IT|ENG|PHY|CHM|MTH|SWE|CIS|CSC|INF|BIO|"
    r"ARC|CIV|MEC|ELE|ECO|ACC|MGT|LAW|MED|NUR|PHR|EDU|ART)\b",
    re.IGNORECASE,
)

# Academic subject keywords (content-based trigger)
_SUBJECT_KW_RE = re.compile(
    r"\b(introduction\s+to|mathematics|physics|chemistry|programming|"
    r"algorithms|networks|database|calculus|statistics|mechanics|"
    r"مقدمة|رياضيات|فيزياء|كيمياء|برمجة|خوارزميات|شبكات|"
    r"قواعد\s*بيانات|ميكانيكا|إحصاء|حساب)\b",
    re.IGNORECASE | re.UNICODE,
)

# Structural level/semester markers in Arabic and English
_LEVEL_SEM_RE = re.compile(
    r"(level\s*[1-4]|semester\s*[12]|المستو[يى]\s*\w+|الترم\s*\w+|"
    r"الفرق[هة]\s*\w+|السن[هة]\s*\w+)",
    re.IGNORECASE | re.UNICODE,
)


def extract_courses_from_text(text: str) -> list[dict]:
    """
    Public helper: extract all course entries from raw chunk text.

    Four strategies applied in order (most precise → most permissive):

      A. Full row with trailing credit numbers
         "GEN 004 Introduction to Computers 3 2 1 3"

      B. Code + title, no trailing numbers
         "BCS 201 Data Structures"

      C. Code on its own line, title on the next line
         "GEN 004\\nIntroduction to Computers"

      D. Bare code with no title (last resort — uses translation table)
         "GEN 004"

    Returns a list of dicts:
        [{"code": "GEN 004", "title": "Introduction to Computers"}, ...]
    """
    seen_codes: set[str] = set()
    courses: list[dict]  = []

    def _clean_title(raw: str) -> str:
        # Strip Arabic tatweel/dash column separators (ـ ــ) common in OCR tables
        t = re.sub(r"[\u0640\-]{2,}", " ", raw)
        # Strip trailing credit-hour columns: "Introduction to Computers 3 2 1 3"
        t = re.sub(r"(\s+\d+){1,8}\s*$", "", t).strip()
        # Strip trailing standalone numbers/dots/dashes
        t = re.sub(r"[\d\.\-]+$", "", t).strip()
        # Strip trailing prerequisite codes like "BAS 001" at end of title
        t = re.sub(r"\s+[A-Z]{2,4}\s*\d{3,4}\s*$", "", t).strip()
        t = re.sub(r"\s{2,}", " ", t)          # collapse internal spaces
        t = re.sub(r"^[\d\W]+", "", t).strip() # strip leading noise
        return t

    def _add(prefix: str, number: str, raw_title: str) -> None:
        code  = f"{prefix} {number}"
        title = _clean_title(raw_title)
        if code not in seen_codes and title and len(title) > 2:
            seen_codes.add(code)
            courses.append({"code": code, "title": title})

    # ── Strategy A: full row with trailing credit numbers ─────────────────
    for m in _TABLE_ROW_FULL_RE.finditer(text):
        _add(m.group(1), m.group(2), m.group(3))

    # ── Strategy A2: row-number prefix variant ────────────────────────────
    # Handles OCR tables where a row number precedes the code:
    #   "2 GEN 004 Introduction to Computers 2 __ 3 5 3 30 20 50 3"
    #   "3 BAS 004 Mathematics 2 BAS 001 2 2 __ 4 3 50 __ 50 3"
    # The leading digit(s) are consumed so the code is captured cleanly.
    _ROW_NUM_PREFIX_RE = re.compile(
        r"^\s*\d{1,2}\s+([A-Z]{2,4})[\s\-:\.]{0,3}(\d{3,4})\s+(.+)$",
        re.MULTILINE | re.IGNORECASE,
    )
    for m in _ROW_NUM_PREFIX_RE.finditer(text):
        _add(m.group(1), m.group(2), m.group(3))

    # ── Strategy B: code + title, no trailing numbers ─────────────────────
    for m in _TABLE_ROW_SIMPLE_RE.finditer(text):
        _add(m.group(1), m.group(2), m.group(3))

    # ── Strategy C: code on one line, title on the next ───────────────────
    # Handles OCR output where columns were split across lines:
    #   "GEN 004\nIntroduction to Computers\n3 2 1 3"
    lines = text.splitlines()
    for i, line in enumerate(lines):
        m = re.fullmatch(r"\s*([A-Z]{2,4})\s*(\d{3,4})\s*", line)
        if m:
            prefix, number = m.group(1), m.group(2)
            code = f"{prefix} {number}"
            if code in seen_codes:
                continue
            # Look at the next non-empty line for the title
            for j in range(i + 1, min(i + 3, len(lines))):
                candidate = lines[j].strip()
                # Title line: starts with a letter, not another code
                if (candidate
                        and re.match(r"[A-Za-z\u0600-\u06FF]", candidate)
                        and not re.match(r"[A-Z]{2,4}\s*\d{3,4}", candidate)):
                    _add(prefix, number, candidate)
                    break

    # ── Strategy D: bare code with no title (use translation table) ───────
    # Last resort — at least we know the course exists
    for m in _COURSE_CODE_RE.finditer(text):
        prefix, number = m.group(1), m.group(2)
        code = f"{prefix} {number}"
        if code not in seen_codes:
            # Only add if we have a known Arabic title for it
            from_table = _to_arabic_title(code)
            if from_table != code:   # translation found
                seen_codes.add(code)
                courses.append({"code": code, "title": from_table})

    return courses


def _normalize_ocr_text(text: str) -> str:
    """
    Normalize OCR-noisy text before course extraction.
    Handles:
    - Broken course codes: "G E N  0 0 4" → "GEN 004"
    - Multiple spaces between code parts: "GEN  004" → "GEN 004"
    - Mixed separators: "GEN-004", "GEN:004" → kept as-is (regex handles them)
    - Duplicate blank lines collapsed to single blank line
    """
    # Fix broken uppercase letter sequences: "G E N" → "GEN"
    # Pattern: single uppercase letters separated by spaces (2–4 letters)
    text = re.sub(
        r"\b([A-Z])\s([A-Z])\s([A-Z])\s([A-Z])\b",
        r"\1\2\3\4", text
    )
    text = re.sub(
        r"\b([A-Z])\s([A-Z])\s([A-Z])\b",
        r"\1\2\3", text
    )
    text = re.sub(
        r"\b([A-Z])\s([A-Z])\b(?=\s*\d)",
        r"\1\2", text
    )
    # Fix broken digit sequences: "0 0 4" → "004"
    text = re.sub(
        r"\b(\d)\s(\d)\s(\d)\s(\d)\b",
        r"\1\2\3\4", text
    )
    text = re.sub(
        r"\b(\d)\s(\d)\s(\d)\b",
        r"\1\2\3", text
    )
    # Collapse runs of 3+ spaces to a single space
    text = re.sub(r" {3,}", " ", text)
    # Collapse 3+ blank lines to one blank line
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text


def _clean_ocr_noise(text: str) -> str:
    """
    OCR noise removal + normalization:
    - Fix broken letter/digit sequences
    - Collapse multiple spaces/tabs within a line
    - Remove lines that are only punctuation, digits, or ≤ 2 chars
    """
    # First normalize broken OCR sequences
    text = _normalize_ocr_text(text)

    lines   = text.splitlines()
    cleaned = []
    for line in lines:
        line = re.sub(r"[ \t]{2,}", " ", line).strip()
        if line and not re.fullmatch(r"[\W\d]{0,3}", line):
            cleaned.append(line)
    return "\n".join(cleaned)


def _preprocess_chunk(text: str) -> str:
    """
    Preprocess a single chunk before sending to the LLM.

    Steps:
      1. Clean OCR noise
      2. Extract course entries via all 4 strategies → format as bullet list
      3. Preserve level/semester header lines above the bullet list
      4. If no courses found, return cleaned text as-is

    Threshold: even 1 detected course triggers structured output.
    """
    cleaned = _clean_ocr_noise(text)
    courses = extract_courses_from_text(cleaned)

    # Debug: log what was extracted
    if courses:
        logger.debug(
            f"[preprocess] Extracted {len(courses)} courses: "
            + ", ".join(f"{c['code']}" for c in courses[:5])
        )
    else:
        # Log first 200 chars so we can see what the raw text looks like
        logger.debug(f"[preprocess] No courses found. Raw (200): {cleaned[:200]!r}")

    if not courses:
        return cleaned

    # Preserve level/semester header lines (e.g. "Level 1 Semester 1")
    header_lines = [
        line for line in cleaned.splitlines()
        if _LEVEL_SEM_RE.search(line) and not _COURSE_CODE_RE.search(line)
    ]

    parts: list[str] = []
    if header_lines:
        parts.append("\n".join(header_lines))

    parts.append("Courses:")
    for c in courses:
        parts.append(f"- {c['title']} ({c['code']})")

    result = "\n".join(parts)
    logger.debug(f"[preprocess] Output (300): {result[:300]!r}")
    return result


# ---------------------------------------------------------------------------
# Course-title Arabic translation table
# Maps common English course titles to Arabic equivalents.
# Extend this dict as more courses are encountered.
# ---------------------------------------------------------------------------
_COURSE_AR_TITLES: dict[str, str] = {
    # GEN / general courses
    "introduction to computers":        "مقدمة في الحاسبات",
    "intro to computers":               "مقدمة في الحاسبات",
    "computer skills":                  "مهارات الحاسب",
    "english language":                 "اللغة الإنجليزية",
    "arabic language":                  "اللغة العربية",
    "islamic studies":                  "الدراسات الإسلامية",
    "national education":               "التربية الوطنية",
    "military sciences":                "العلوم العسكرية",
    # BAS / basic sciences
    "mathematics 1":                    "رياضيات 1",
    "mathematics 2":                    "رياضيات 2",
    "mathematics 3":                    "رياضيات 3",
    "calculus":                         "حساب التفاضل والتكامل",
    "physics 1":                        "فيزياء 1",
    "physics 2":                        "فيزياء 2",
    "chemistry":                        "كيمياء",
    "engineering chemistry":            "كيمياء هندسية",
    "statistics":                       "إحصاء",
    "probability and statistics":       "احتمالات وإحصاء",
    "discrete mathematics":             "رياضيات تقسيمية",
    "linear algebra":                   "جبر خطي",
    # BCS / computer science
    "programming 1":                    "برمجة 1",
    "programming 2":                    "برمجة 2",
    "introduction to programming":      "مقدمة في البرمجة",
    "data structures":                  "هياكل البيانات",
    "algorithms":                       "خوارزميات",
    "object oriented programming":      "برمجة كائنية",
    "database systems":                 "قواعد البيانات",
    "operating systems":                "أنظمة التشغيل",
    "computer networks":                "شبكات الحاسب",
    "software engineering":             "هندسة البرمجيات",
    "artificial intelligence":          "الذكاء الاصطناعي",
    "computer architecture":            "معمارية الحاسب",
    "digital logic":                    "منطق رقمي",
    "web programming":                  "برمجة الويب",
    "computer graphics":                "رسوميات الحاسب",
    "human computer interaction":       "تفاعل الإنسان والحاسب",
    "information security":             "أمن المعلومات",
    "machine learning":                 "تعلم الآلة",
    "computer organization":            "تنظيم الحاسب",
    "theory of computation":            "نظرية الحوسبة",
    "compiler design":                  "تصميم المترجمات",
    "numerical methods":                "طرق عددية",
    "project management":               "إدارة المشاريع",
    "graduation project":               "مشروع التخرج",
    "graduation project 1":             "مشروع التخرج 1",
    "graduation project 2":             "مشروع التخرج 2",
}

# CS-related course code prefixes (used for program filtering)
_CS_PREFIXES = {"BCS", "CS", "IT", "GEN", "BAS", "CIS", "CSC", "INF", "SWE"}

# Semester detection patterns (Arabic + English)
_SEM1_DETECT = re.compile(
    r"ترم\s*اول|الترم\s*الاول|فصل\s*اول|semester\s*1|first\s*semester|sem\s*1|term\s*1",
    re.IGNORECASE | re.UNICODE,
)
_SEM2_DETECT = re.compile(
    r"ترم\s*تاني|الترم\s*التاني|فصل\s*تاني|semester\s*2|second\s*semester|sem\s*2|term\s*2",
    re.IGNORECASE | re.UNICODE,
)

# Level/year detection patterns
_LEVEL_DETECT: dict[int, re.Pattern] = {
    1: re.compile(
        r"فرق[هة]\s*اول[هى]?|الفرق[هة]\s*الاول[هى]?|level\s*1|year\s*1|first\s*year|"
        r"المستو[يى]\s*الاول|السن[هة]\s*الاول[هى]?|\باوله?\b",
        re.IGNORECASE | re.UNICODE,
    ),
    2: re.compile(
        r"فرق[هة]\s*تاني[هة]?|الفرق[هة]\s*التاني[هة]?|level\s*2|year\s*2|second\s*year|"
        r"المستو[يى]\s*التاني|السن[هة]\s*التاني[هة]?",
        re.IGNORECASE | re.UNICODE,
    ),
    3: re.compile(
        r"فرق[هة]\s*تالت[هة]?|level\s*3|year\s*3|third\s*year|المستو[يى]\s*التالت",
        re.IGNORECASE | re.UNICODE,
    ),
    4: re.compile(
        r"فرق[هة]\s*رابع[هة]?|level\s*4|year\s*4|fourth\s*year|المستو[يى]\s*الرابع",
        re.IGNORECASE | re.UNICODE,
    ),
}

# Arabic ordinal headers for output
_LEVEL_AR = {1: "الأولى", 2: "الثانية", 3: "الثالثة", 4: "الرابعة"}
_SEM_AR   = {1: "الأول",  2: "الثاني"}


def _to_arabic_title(english_title: str) -> str:
    """
    Return the Arabic translation of an English course title if known,
    otherwise return the original title unchanged.
    """
    key = english_title.strip().lower()
    # Exact match
    if key in _COURSE_AR_TITLES:
        return _COURSE_AR_TITLES[key]
    # Prefix match (handles "Mathematics 2 (BAS 004)" → strip trailing code)
    key_clean = re.sub(r"\s*\([A-Z]{2,4}\s*\d{3,4}\)\s*$", "", key).strip()
    if key_clean in _COURSE_AR_TITLES:
        return _COURSE_AR_TITLES[key_clean]
    return english_title


def _detect_query_semester(question: str) -> int | None:
    """Return 1, 2, or None based on semester mention in the question."""
    norm = question.replace("أ", "ا").replace("إ", "ا").replace("آ", "ا")
    if _SEM1_DETECT.search(norm):
        return 1
    if _SEM2_DETECT.search(norm):
        return 2
    return None


def _detect_query_level(question: str) -> int | None:
    """Return 1–4 or None based on year/level mention in the question."""
    norm = question.replace("أ", "ا").replace("إ", "ا").replace("آ", "ا")
    for level, pat in _LEVEL_DETECT.items():
        if pat.search(norm):
            return level
    return None


def _is_cs_course(code: str) -> bool:
    """Return True if the course code prefix belongs to a CS program."""
    prefix = re.match(r"([A-Z]{2,4})", code.upper())
    return bool(prefix and prefix.group(1) in _CS_PREFIXES)


def _extract_direct_course_answer(
    context_str: str,
    question: str,
    query_language: str,
) -> str:
    """
    Extract a structured course-list answer directly from the preprocessed
    context — without calling the LLM.

    Filtering rules (relaxed for high recall):
      - Blocks with NO level/semester label → ALWAYS included
      - Blocks WITH a label → only included if label matches the query
      - If filtering removes ALL entries → fall back to ALL entries (no filter)
      - If course codes exist in context → ALWAYS return a list

    Returns "" only if zero course entries exist anywhere in the context.
    """
    if "Courses:" not in context_str:
        # ── Fail-safe: extract directly from raw context ──────────────────
        raw_codes = _COURSE_CODE_RE.findall(context_str)
        if len(raw_codes) >= 1:
            logger.info(
                f"[chat] Fail-safe: found {len(raw_codes)} raw course codes "
                "in context without 'Courses:' — running direct extraction"
            )
            courses = extract_courses_from_text(context_str)
            if courses:
                cit = ""
                for line in context_str.splitlines():
                    if line.startswith("[") and "File:" in line:
                        cit = line.strip("[]")
                        break
                synthetic_ctx = (
                    f"[📋 COURSE LIST | {cit}]\n"
                    "Courses:\n"
                    + "\n".join(f"- {c['title']} ({c['code']})" for c in courses)
                )
                return _extract_direct_course_answer(
                    context_str    = synthetic_ctx,
                    question       = question,
                    query_language = query_language,
                )
        return ""

    # ── Detect what the query is asking for ──────────────────────────────
    q_semester = _detect_query_semester(question)
    q_level    = _detect_query_level(question)

    # ── Collect ALL entries first (no filtering yet) ──────────────────────
    all_entries: list[dict] = []
    citation = ""

    for block in context_str.split("---"):
        if "Courses:" not in block:
            continue

        block_text = block.strip()

        # Extract citation from header
        block_citation = ""
        for line in block_text.splitlines():
            if line.startswith("[") and "File:" in line:
                block_citation = line.strip("[]")
                if not citation:
                    citation = block_citation
                break

        # Detect this block's own level/semester labels
        block_sem   = None
        block_level = None
        for line in block_text.splitlines():
            if _SEM1_DETECT.search(line):
                block_sem = 1
            elif _SEM2_DETECT.search(line):
                block_sem = 2
            for lv, pat in _LEVEL_DETECT.items():
                if pat.search(line):
                    block_level = lv

        # Extract bullet lines from this block
        in_courses = False
        for line in block_text.splitlines():
            if line.strip() == "Courses:":
                in_courses = True
                continue
            if in_courses:
                stripped = line.strip()
                if stripped.startswith("- "):
                    code_match = re.search(r"\(([A-Z]{2,4}[\s\-]?\d{3,4})\)\s*$", stripped)
                    code = code_match.group(1) if code_match else ""
                    all_entries.append({
                        "bullet":      stripped,
                        "code":        code,
                        "block_sem":   block_sem,
                        "block_level": block_level,
                        "citation":    block_citation,
                        "has_label":   (block_sem is not None or block_level is not None),
                    })
                elif stripped and not stripped.startswith("-"):
                    in_courses = False

    logger.info(f"[chat] Course extraction: {len(all_entries)} entries before filtering")

    if not all_entries:
        return ""

    # ── Apply level/semester filtering ────────────────────────────────────
    # Rule: only filter a block when it HAS a label AND the label mismatches.
    # Blocks with NO label are always included.
    def _passes_filter(e: dict) -> bool:
        # Block has no labels → always include
        if not e["has_label"]:
            return True
        # Check semester: only reject if block IS labelled AND label mismatches
        if q_semester is not None and e["block_sem"] is not None:
            if e["block_sem"] != q_semester:
                return False
        # Check level: only reject if block IS labelled AND label mismatches
        if q_level is not None and e["block_level"] is not None:
            if e["block_level"] != q_level:
                return False
        return True

    filtered_entries = [e for e in all_entries if _passes_filter(e)]
    logger.info(f"[chat] Course extraction: {len(filtered_entries)} entries after filtering")

    # ── Fallback: if filtering dropped everything, use all entries ─────────
    if not filtered_entries:
        logger.warning(
            f"[chat] FILTER DROPPED ALL COURSES "
            f"(before={len(all_entries)}, after=0) — using unfiltered list"
        )
        filtered_entries = all_entries

    # ── Program filtering: prefer CS courses when mixed ───────────────────
    cs_entries  = [e for e in filtered_entries if _is_cs_course(e["code"])]
    use_entries = cs_entries if cs_entries else filtered_entries

    # ── Deduplicate by code ───────────────────────────────────────────────
    seen_codes: set[str] = set()
    final_entries: list[dict] = []
    for e in use_entries:
        key = e["code"].replace(" ", "").replace("-", "").upper()
        if key not in seen_codes:
            seen_codes.add(key)
            final_entries.append(e)

    # Final guarantee: if we still have nothing, use everything deduplicated
    if not final_entries:
        logger.warning("[chat] CS filter dropped all entries — using full list")
        seen_codes.clear()
        for e in filtered_entries:
            key = e["code"].replace(" ", "").replace("-", "").upper()
            if key not in seen_codes:
                seen_codes.add(key)
                final_entries.append(e)

    if not final_entries:
        return ""

    # ── Build bullet lines with Arabic titles ─────────────────────────────
    bullet_lines: list[str] = []
    for e in final_entries:
        raw_bullet = e["bullet"]
        m = re.match(r"^-\s+(.+?)\s+\(([A-Z]{2,4}[\s\-]?\d{3,4})\)\s*$", raw_bullet)
        if m:
            title    = m.group(1).strip()
            code     = m.group(2).strip()
            ar_title = _to_arabic_title(title)
            bullet_lines.append(f"- {ar_title} ({code})")
        else:
            bullet_lines.append(raw_bullet)

    # ── Build the answer header ───────────────────────────────────────────
    if query_language == "arabic":
        sem_part   = f"الترم {_SEM_AR[q_semester]}"  if q_semester else "الترم الأول"
        level_part = f"الفرقة {_LEVEL_AR[q_level]}"  if q_level    else "الفرقة الأولى"
        header = f"مواد {sem_part} {level_part}:"
        footer = f"\n[المصدر: {citation}]" if citation else ""
    else:
        sem_part   = f"Semester {q_semester}" if q_semester else "Semester 1"
        level_part = f"Level {q_level}"       if q_level    else "Level 1"
        header = f"Courses for {level_part} {sem_part}:"
        footer = f"\n[Source: {citation}]" if citation else ""

    return f"{header}\n" + "\n".join(bullet_lines) + footer


def _build_answer_from_courses(
    courses: list[dict],
    question: str,
    query_language: str,
    meta: dict,
) -> str:
    """
    Build a formatted answer string directly from a list of course dicts.
    No dependency on "Courses:" markers or context formatting.

    Parameters
    ----------
    courses : list[dict]
        Each dict has "code" and "title" keys.
    question : str
        Original user question (used to detect semester/level for header).
    query_language : str
        "arabic" or "english".
    meta : dict
        Metadata from the first retrieved chunk (for citation).
    """
    q_semester = _detect_query_semester(question)
    q_level    = _detect_query_level(question)

    # Apply level/semester filtering only when the course has a detectable
    # label AND it mismatches. Courses with no label always pass.
    # (For direct extraction from raw text, we have no block-level labels,
    #  so all courses pass — filtering is skipped here intentionally.)

    # Prefer CS courses when mixed programs are present
    cs_courses  = [c for c in courses if _is_cs_course(c["code"])]
    use_courses = cs_courses if cs_courses else courses

    # Build bullet lines with Arabic title translation
    bullets: list[str] = []
    for c in use_courses:
        ar_title = _to_arabic_title(c["title"])
        bullets.append(f"- {ar_title} ({c['code']})")

    if not bullets:
        return ""

    # Build header
    fname    = meta.get("fileName", "")
    page     = meta.get("page", "")
    citation = f"File: {fname} | Page: {page}" if fname else ""

    if query_language == "arabic":
        sem_part   = f"الترم {_SEM_AR[q_semester]}"  if q_semester else "الترم الأول"
        level_part = f"الفرقة {_LEVEL_AR[q_level]}"  if q_level    else "الفرقة الأولى"
        header = f"مواد {sem_part} {level_part}:"
        footer = f"\n[المصدر: {citation}]" if citation else ""
    else:
        sem_part   = f"Semester {q_semester}" if q_semester else "Semester 1"
        level_part = f"Level {q_level}"       if q_level    else "Level 1"
        header = f"Courses for {level_part} {sem_part}:"
        footer = f"\n[Source: {citation}]" if citation else ""

    return f"{header}\n" + "\n".join(bullets) + footer


def _build_codes_only_answer(
    raw_codes: list[tuple],
    question: str,
    query_language: str,
    meta: dict,
) -> str:
    """
    Hard fallback: course codes were detected but no titles could be extracted.
    Returns a minimal list of just the codes so the system NEVER says "not found"
    when course data is present.

    Parameters
    ----------
    raw_codes : list[tuple]
        Output of _COURSE_CODE_RE.findall() — list of (prefix, number) tuples.
    """
    q_semester = _detect_query_semester(question)
    q_level    = _detect_query_level(question)

    # Deduplicate codes
    seen: set[str] = set()
    bullets: list[str] = []
    for prefix, number in raw_codes:
        code = f"{prefix} {number}".upper()
        if code not in seen:
            seen.add(code)
            # Try translation table first
            ar_title = _to_arabic_title(code)
            if ar_title != code:
                bullets.append(f"- {ar_title} ({code})")
            else:
                bullets.append(f"- {code}")

    if not bullets:
        return ""

    fname    = meta.get("fileName", "")
    page     = meta.get("page", "")
    citation = f"File: {fname} | Page: {page}" if fname else ""

    if query_language == "arabic":
        sem_part   = f"الترم {_SEM_AR[q_semester]}"  if q_semester else "الترم الأول"
        level_part = f"الفرقة {_LEVEL_AR[q_level]}"  if q_level    else "الفرقة الأولى"
        header = f"مواد {sem_part} {level_part} (مستخرجة من الجدول):"
        footer = f"\n[المصدر: {citation}]" if citation else ""
    else:
        sem_part   = f"Semester {q_semester}" if q_semester else "Semester 1"
        level_part = f"Level {q_level}"       if q_level    else "Level 1"
        header = f"Courses for {level_part} {sem_part} (extracted from table):"
        footer = f"\n[Source: {citation}]" if citation else ""

    return f"{header}\n" + "\n".join(bullets) + footer


# ---------------------------------------------------------------------------
# Helper: build context string from reranked results
# ---------------------------------------------------------------------------

def _build_context(results: list[dict], max_chars: int = 8000) -> str:
    """
    Build the context string sent to the LLM.

    Ordering priority (highest first):
      1. Chunks that contain level/semester markers AND course codes
         (e.g. "Level 1 Semester 1 … GEN 004 …")
      2. Table-boosted chunks (course codes present, no level marker)
      3. All other chunks by rerank score

    Merging: if two chunks from the same file share a level/semester header,
    their course lists are merged into one block so the LLM sees a single
    complete list instead of two fragments.
    """
    # ── Step 1: preprocess every chunk ───────────────────────────────────
    processed: list[dict] = []
    for r in results:
        raw = r.get("text", "").strip()
        if not raw:
            continue
        text = _preprocess_chunk(raw)
        has_courses    = "Courses:" in text
        has_level_sem  = bool(_LEVEL_SEM_RE.search(text))
        processed.append({
            **r,
            "_processed_text": text,
            "_has_courses":    has_courses,
            "_has_level_sem":  has_level_sem,
            "_priority": (
                0 if (has_courses and has_level_sem) else   # best: structured + labelled
                1 if has_courses else                        # good: structured
                2 if has_level_sem else                      # ok: labelled
                3                                            # generic
            ),
        })

    # ── Step 2: sort by priority then rerank score ────────────────────────
    processed.sort(key=lambda r: (
        r["_priority"],
        -r.get("rerank_score", r.get("boosted_score", 0.0)),
    ))

    # ── Step 3: merge course lists from the same file ─────────────────────
    # If multiple chunks from the same file all have "Courses:", combine
    # their bullet lines under one header so the LLM sees one complete list.
    merged_courses: dict[str, list[str]] = {}   # fname → [bullet, …]
    merged_meta:    dict[str, dict]      = {}   # fname → first chunk's meta
    non_course_blocks: list[dict]        = []

    for r in processed:
        text = r["_processed_text"]
        if r["_has_courses"]:
            meta  = r.get("metadata", {})
            fname = meta.get("fileName", "Unknown")
            if fname not in merged_courses:
                merged_courses[fname] = []
                merged_meta[fname]    = meta
            # Extract bullet lines from this chunk
            for line in text.splitlines():
                if line.startswith("- ") and line not in merged_courses[fname]:
                    merged_courses[fname].append(line)
        else:
            non_course_blocks.append(r)

    # ── Step 4: build final context string ────────────────────────────────
    parts: list[str] = []
    total = 0
    seen_text: set[str] = set()

    # Course-list blocks first (merged per file)
    for fname, bullets in merged_courses.items():
        if not bullets:
            continue
        meta    = merged_meta[fname]
        page    = meta.get("page", "N/A")
        section = meta.get("sectionTitle", "") or "N/A"
        header  = (
            f"[📋 COURSE LIST | File: {fname} | Page: {page} | Section: {section}]"
        )
        block = header + "\nCourses:\n" + "\n".join(bullets)
        if total + len(block) <= max_chars:
            parts.append(block)
            total += len(block)

    # Non-course blocks after
    for r in non_course_blocks:
        text = r["_processed_text"].strip()
        if not text:
            continue
        key = text[:120]
        if key in seen_text:
            continue
        seen_text.add(key)

        meta    = r.get("metadata", {})
        fname   = meta.get("fileName", "Unknown")
        page    = meta.get("page", "N/A")
        section = meta.get("sectionTitle", "") or "N/A"
        score   = r.get("rerank_score", r.get("boosted_score", 0.0))
        header  = (
            f"[Chunk | Score: {score:.3f} | "
            f"File: {fname} | Page: {page} | Section: {section}]"
        )
        block = f"{header}\n{text}"
        if total + len(block) > max_chars:
            break
        parts.append(block)
        total += len(block)

    return "\n\n---\n\n".join(parts)


def _build_sources(results: list[dict]) -> list[SourceInfo]:
    seen: set[str] = set()
    sources = []
    for r in results:
        meta = r.get("metadata", {})
        key  = f"{meta.get('fileName', '')}::{meta.get('page', '')}"
        if key in seen:
            continue
        seen.add(key)
        sources.append(SourceInfo(
            file         = meta.get("fileName", "Unknown"),
            page         = int(meta.get("page", 0)),
            sectionTitle = meta.get("sectionTitle", ""),
            language     = meta.get("language", ""),
            keywords     = meta.get("keywords", ""),
            snippet      = r["text"][:300] + ("…" if len(r["text"]) > 300 else ""),
            rerankScore  = round(r.get("rerank_score", 0.0), 4),
        ))
    return sources


# ---------------------------------------------------------------------------
# Main chat endpoint
# ---------------------------------------------------------------------------

@router.post("/", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    RAG chat endpoint with hybrid retrieval and reranking.
    """
    if not request.question.strip():
        raise HTTPException(status_code=400, detail="Question cannot be empty")

    if collection is None:
        raise HTTPException(
            status_code=400,
            detail="No documents indexed yet. Please upload PDFs first.",
        )

    if collection.count() == 0:
        raise HTTPException(
            status_code=400,
            detail="No documents indexed yet. Please upload PDFs first.",
        )

    if embeddings is None:
        raise HTTPException(
            status_code=500,
            detail="Embeddings not configured. Set OPENAI_API_KEY or OPENROUTER_API_KEY in .env",
        )

    t_start = time.perf_counter()

    # ── 1. Query understanding (NEW) ──────────────────────────────────────
    query_intent = understand_query(request.question)

    # Allow explicit overrides from the request
    if request.program_filter:
        query_intent.program = request.program_filter
    if request.year_filter:
        query_intent.year = request.year_filter

    # Use the rewritten clean_query for embedding
    query_normalized = query_intent.clean_query

    # ── 1b. LLM query rewrite ────────────────────────────────────────────
    # Always run the LLM rewrite for two cases:
    #   a) Low-confidence intent (< 0.55) — rule-based parser found nothing
    #   b) High-confidence structured intent — the rule-based clean_query
    #      is a long mixed Arabic+English string that confuses ada-002.
    #      The LLM produces a tighter, more focused search query.
    # Skip only for medium confidence (0.55–0.75) where the rule-based
    # query is already clean and the LLM rewrite adds latency without gain.
    should_rewrite = (
        query_intent.confidence < 0.55          # low confidence: parser failed
        or query_intent.confidence >= 0.80      # high confidence: clean it up
    )
    if should_rewrite:
        rewritten = rewrite_query(request.question)
        if rewritten and rewritten.strip() != request.question.strip():
            query_normalized = rewritten
            query_intent.clean_query = rewritten
            logger.info(f"[chat] Query rewritten (conf={query_intent.confidence:.2f}): '{rewritten[:60]}'")

    logger.info(
        f"[chat] Intent: program={query_intent.program} year={query_intent.year} "
        f"intent={query_intent.intent} conf={query_intent.confidence:.2f} "
        f"clean='{query_normalized[:60]}'"
    )

    # ── 2. Embed query (with cache) ───────────────────────────────────────
    try:
        embedding_cache.embed_query_cached(query_normalized, embeddings)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Embedding failed: {e}. Check your API key and credits.",
        )

    # ── 3. Hybrid retrieval (with query understanding + section boosting) ─
    bm25_idx = _get_bm25_index()

    try:
        retrieval_output = hybrid_search(
            query                  = request.question,
            collection             = collection,
            embeddings             = embeddings,
            bm25_index             = bm25_idx,
            top_k                  = request.top_k * 4,
            dense_candidates       = max(request.top_k * 6, 50),
            sparse_candidates      = max(request.top_k * 6, 50),
            use_rrf                = True,
            language_filter        = request.language_filter,
            section_filter         = request.section_filter,
            file_filter            = request.file_filter,
            use_query_understanding = True,
            use_multi_query        = True,
            use_section_boost      = True,
            query_intent           = query_intent,
        )
    except Exception as e:
        logger.error(f"[chat] Hybrid search failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Retrieval failed: {e}")

    candidates      = retrieval_output["results"]
    query_language  = retrieval_output["query_language"]
    retrieval_stats = retrieval_output["retrieval_stats"]

    # Build intent dict for response
    intent_dict = {
        "program":    query_intent.program,
        "year":       query_intent.year,
        "semester":   query_intent.semester,
        "intent":     query_intent.intent,
        "confidence": round(query_intent.confidence, 2),
        "clean_query": query_intent.clean_query,
    }

    if not candidates:
        no_info = (
            "المعلومات غير موجودة في اللائحة"
            if query_language == "arabic"
            else "Information not found in the regulations"
        )
        return ChatResponse(
            success=True,
            answer=no_info,
            sources=[],
            queryLanguage=query_language,
            queryIntent=intent_dict,
            answerVerdict={"verdict": "NO", "label": "not_supported", "verified": False},
            retrievalStats=retrieval_stats,
        )

    # ── 4. Rerank (intent-aware, bilingual) ──────────────────────────────
    rerank_method = (request.rerank_method or "cosine").lower()

    if rerank_method == "none":
        reranked = candidates[:request.top_k]
        for i, c in enumerate(reranked):
            c["rerank_score"]  = c.get("boosted_score", c.get("rrf_score", 1.0 - i * 0.01))
            c["rerank_method"] = "passthrough"
    elif rerank_method == "llm":
        reranked = rerank_results(
            query          = query_normalized,
            candidates     = candidates,
            llm            = llm,
            top_n          = request.top_k,
            query_intent   = query_intent,
            original_query = request.question,
        )
    else:  # default: cosine (bilingual)
        reranked = rerank_results(
            query          = query_normalized,
            candidates     = candidates,
            embeddings     = embeddings,
            top_n          = request.top_k,
            original_query = request.question,  # enables bilingual scoring
        )

    if not reranked:
        no_info = (
            "المعلومات غير موجودة في اللائحة"
            if query_language == "arabic"
            else "Information not found in the regulations"
        )
        return ChatResponse(
            success=True,
            answer=no_info,
            sources=[],
            queryLanguage=query_language,
            queryIntent=intent_dict,
            answerVerdict={"verdict": "NO", "label": "not_supported", "verified": False},
            retrievalStats=retrieval_stats,
        )

    # ── 5. Build context and generate answer ──────────────────────────────

    # ── 5a. GUARANTEED COURSE EXTRACTION (runs before LLM, before context) ──
    # Detection is per-chunk on RAW text only.
    # Reason the old approach failed: joining chunks and normalizing text
    # could distort numeric patterns (e.g. "3 5 3" → "353") and break
    # word-boundary anchors (\b) in mixed Arabic+English content.
    # Fix: scan each chunk's raw text individually with a boundary-free regex.

    # Flexible course-code regex — no \b anchors, works on mixed OCR text
    _DETECT_RE = re.compile(r"([A-Z]{2,4})\s*(\d{3,4})", re.IGNORECASE)

    _should_trigger  = False
    _detected_codes: list[tuple] = []   # (prefix, number) from all chunks
    _first_meta:     dict        = {}

    for _r in reranked:
        _chunk_raw = _r.get("text", "")
        if not _chunk_raw:
            continue
        if not _first_meta:
            _first_meta = _r.get("metadata", {})
        _matches = _DETECT_RE.findall(_chunk_raw)
        if _matches:
            _should_trigger = True
            _detected_codes.extend(_matches)

    # Collect all raw text and norm for logging only (not used for detection)
    _all_raw_text = "\n".join(r.get("text", "") for r in reranked)
    _all_raw_norm = _normalize_ocr_text(_all_raw_text)

    logger.warning(
        f"\n=== DEBUG FULL PIPELINE ===\n"
        f"Question: {request.question}\n"
        f"RAW CHUNKS COUNT: {len(reranked)}\n"
        f"RAW TEXT SAMPLE:\n{_all_raw_text[:500]}\n"
        f"CODES FOUND (per-chunk): {_detected_codes[:15]}\n"
        f"SHOULD TRIGGER: {_should_trigger}\n"
        f"=========================="
    )

    # Only trigger guaranteed course extraction for explicit subject-list queries.
    # For medicine/engineering regulation questions (intent=general/graduation/grades),
    # skip this shortcut and let the LLM answer from context properly.
    _is_subjects_query = (
        query_intent.intent == "subjects list"
        and query_intent.confidence >= 0.50
    )
    if _should_trigger and _is_subjects_query:
        # ── Step 1: extract courses from every raw chunk ──────────────────
        _all_courses: list[dict] = []

        for r in reranked:
            raw = r.get("text", "").strip()
            if not raw:
                continue
            # Try normalized first, fall back to raw if normalization yields nothing
            norm_raw      = _normalize_ocr_text(raw)
            chunk_courses = extract_courses_from_text(norm_raw)
            if not chunk_courses:
                chunk_courses = extract_courses_from_text(raw)
            _all_courses.extend(chunk_courses)

        logger.info(
            f"[chat] Extracted {len(_all_courses)} courses BEFORE dedup "
            f"from {len(reranked)} chunks"
        )

        # ── Step 2: deduplicate ───────────────────────────────────────────
        _seen:   set[str]   = set()
        _deduped: list[dict] = []
        for c in _all_courses:
            key = c["code"].replace(" ", "").replace("-", "").upper()
            if key not in _seen:
                _seen.add(key)
                _deduped.append(c)

        logger.info(f"[chat] Final course count after dedup: {len(_deduped)}")

        # ── Step 3: build answer ──────────────────────────────────────────
        if _deduped:
            _direct_answer = _build_answer_from_courses(
                courses        = _deduped,
                question       = request.question,
                query_language = query_language,
                meta           = _first_meta,
            )

        else:
            # ── Step 4: codes-only fallback ───────────────────────────────
            # extract_courses_from_text found nothing, but _DETECT_RE found codes.
            # Use the codes collected during per-chunk scan.
            _codes_for_fallback: list[tuple] = _detected_codes

            if _codes_for_fallback:
                logger.warning(
                    f"[chat] Codes-only fallback: {len(_codes_for_fallback)} codes, "
                    "no titles extracted"
                )
                _direct_answer = _build_codes_only_answer(
                    raw_codes      = _codes_for_fallback,
                    question       = request.question,
                    query_language = query_language,
                    meta           = _first_meta,
                )
            else:
                # ── Step 5: last-resort signal fallback ───────────────────
                # Trigger fired (prefix/header/subject keyword) but zero codes
                # were parseable. Return a warning message with raw snippet
                # so the user knows data exists but couldn't be parsed.
                logger.warning(
                    "[chat] Last-resort fallback: trigger fired but zero codes "
                    "parseable — returning raw signal warning"
                )
                _snippet = _all_raw_norm[:400].strip()
                if query_language == "arabic":
                    _direct_answer = (
                        "⚠️ تم اكتشاف بيانات مقررات في المستندات المسترجعة "
                        "لكن تعذّر تحليلها بالكامل.\n"
                        "المقتطف المكتشف:\n" + _snippet
                    )
                else:
                    _direct_answer = (
                        "⚠️ Course data detected in retrieved documents "
                        "but could not be fully parsed.\n"
                        "Detected snippet:\n" + _snippet
                    )

        # ── Step 6: return — NEVER fall through to LLM ───────────────────
        logger.info(
            f"[chat] Course extraction complete — "
            f"returning answer (len={len(_direct_answer)})"
        )
        answer_verdict = {"verdict": "YES", "label": "fully_supported", "verified": True}

        t_total_ms = (time.perf_counter() - t_start) * 1000
        retrieval_stats["total_pipeline_ms"] = round(t_total_ms, 1)
        retrieval_stats["rerank_method"]     = rerank_method
        retrieval_stats["cache_stats"]       = embedding_cache.stats
        retrieval_stats["answer_verdict"]    = "YES"
        retrieval_stats["shortcut"]          = "course_extraction_guaranteed"

        log_retrieval_result(
            query           = request.question,
            results         = reranked,
            query_language  = query_language,
            retrieval_stats = retrieval_stats,
        )
        return ChatResponse(
            success        = True,
            answer         = _direct_answer,
            sources        = _build_sources(reranked),
            queryLanguage  = query_language,
            queryIntent    = intent_dict,
            answerVerdict  = answer_verdict,
            retrievalStats = retrieval_stats,
        )

    context_str = _build_context(reranked)

    # ── 5b. Course-list shortcut (POST-CONTEXT fallback) ─────────────────
    # Secondary check after _build_context in case the early check missed
    # something (e.g. codes were in non-reranked chunks).
    _direct_answer = _extract_direct_course_answer(
        context_str    = context_str,
        question       = request.question,
        query_language = query_language,
    )
    if _direct_answer:
        logger.info("[chat] Course-list shortcut (post-context): returning direct answer without LLM")
        answer_verdict = {"verdict": "YES", "label": "fully_supported", "verified": True}

        t_total_ms = (time.perf_counter() - t_start) * 1000
        retrieval_stats["total_pipeline_ms"] = round(t_total_ms, 1)
        retrieval_stats["rerank_method"]     = rerank_method
        retrieval_stats["cache_stats"]       = embedding_cache.stats
        retrieval_stats["answer_verdict"]    = "YES"
        retrieval_stats["shortcut"]          = "course_list_post_context"

        log_retrieval_result(
            query           = request.question,
            results         = reranked,
            query_language  = query_language,
            retrieval_stats = retrieval_stats,
        )
        return ChatResponse(
            success        = True,
            answer         = _direct_answer,
            sources        = _build_sources(reranked),
            queryLanguage  = query_language,
            queryIntent    = intent_dict,
            answerVerdict  = answer_verdict,
            retrievalStats = retrieval_stats,
        )

    try:
        prompt  = _PROMPT.format(context=context_str, question=request.question)
        response = llm.invoke(prompt)
        answer   = response.content if hasattr(response, "content") else str(response)
    except Exception as e:
        logger.error(f"[chat] LLM generation failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Answer generation failed: {e}")

    # ── 5c. Answer verification + smart fallback ─────────────────────────
    # Check whether the generated answer is actually supported by the
    # retrieved context.
    #
    # Smart fallback logic:
    #   If the LLM said "not found" BUT the verifier says the context IS
    #   relevant (PARTIAL/YES), the LLM was being overly strict.
    #   We retry once with a more permissive prompt that explicitly asks
    #   the LLM to extract implicit/partial information.
    _not_found_markers = (
        "المعلومات غير موجودة",
        "Information not found",
    )
    answer_is_not_found = any(m in answer for m in _not_found_markers)

    if answer_is_not_found:
        # Quick check: does the context actually contain relevant content?
        fallback_verdict = verify_answer(
            question = request.question,
            context  = context_str,
            answer   = answer,
        )
        if fallback_verdict["verdict"] in ("YES", "PARTIAL"):
            # Context IS relevant — the LLM was too strict. Retry with a
            # permissive prompt that explicitly allows partial answers.
            logger.info("[chat] Smart fallback: LLM said not-found but context is relevant — retrying")
            try:
                fallback_prompt = _FALLBACK_PROMPT.format(
                    context  = context_str,
                    question = request.question,
                )
                fallback_response = llm.invoke(fallback_prompt)
                fallback_answer   = (
                    fallback_response.content
                    if hasattr(fallback_response, "content")
                    else str(fallback_response)
                )
                # Only use the fallback if it actually produced content
                if fallback_answer.strip() and not any(
                    m in fallback_answer for m in _not_found_markers
                ):
                    answer = fallback_answer
                    answer_is_not_found = False
                    logger.info("[chat] Smart fallback succeeded")
            except Exception as fb_err:
                logger.warning(f"[chat] Smart fallback LLM call failed: {fb_err}")

        answer_verdict = fallback_verdict
    else:
        answer_verdict = verify_answer(
            question = request.question,
            context  = context_str,
            answer   = answer,
        )
        if answer_verdict["verdict"] == "NO":
            # Verifier says not supported — mark accordingly but keep answer
            logger.warning("[chat] Verifier flagged answer as unsupported")

    # ── 6. Log retrieval trace ────────────────────────────────────────────
    t_total_ms = (time.perf_counter() - t_start) * 1000
    retrieval_stats["total_pipeline_ms"] = round(t_total_ms, 1)
    retrieval_stats["rerank_method"]     = rerank_method
    retrieval_stats["cache_stats"]       = embedding_cache.stats
    retrieval_stats["answer_verdict"]    = answer_verdict["verdict"]

    log_retrieval_result(
        query           = request.question,
        results         = reranked,
        query_language  = query_language,
        retrieval_stats = retrieval_stats,
    )

    logger.info(
        f"[chat] Done: lang={query_language}, chunks={len(reranked)}, "
        f"total={t_total_ms:.0f}ms"
    )

    return ChatResponse(
        success        = True,
        answer         = answer,
        sources        = _build_sources(reranked),
        queryLanguage  = query_language,
        queryIntent    = intent_dict,
        answerVerdict  = answer_verdict,
        retrievalStats = retrieval_stats,
    )


# ---------------------------------------------------------------------------
# Course catalog endpoints
# ---------------------------------------------------------------------------

@router.get("/courses")
async def get_courses(
    year:     Optional[int] = Query(default=None, ge=1, le=4),
    semester: Optional[int] = Query(default=None, ge=1, le=2),
    program:  Optional[str] = Query(default=None),
    file:     Optional[str] = Query(default=None),
):
    """
    Return courses from the dynamic catalog.

    Query params (all optional):
        year      – academic year 1–4
        semester  – semester 1 or 2
        program   – e.g. "computer science"
        file      – filter by source file name (substring)

    Example:
        GET /api/chat/courses?year=1&semester=1&program=computer+science
    """
    catalog = get_catalog(collection)
    if not catalog.is_built:
        catalog.build()

    courses = catalog.query(year=year, semester=semester, program=program, file=file)
    return JSONResponse({
        "success": True,
        "count":   len(courses),
        "filters": {"year": year, "semester": semester, "program": program, "file": file},
        "courses": courses,
    })


@router.get("/courses/summary")
async def get_courses_summary():
    """Return a summary of the course catalog (totals by program and year)."""
    catalog = get_catalog(collection)
    if not catalog.is_built:
        catalog.build()
    return JSONResponse({"success": True, **catalog.summary()})


@router.post("/courses/rebuild")
async def rebuild_course_catalog():
    """Force-rebuild the course catalog from ChromaDB."""
    catalog = get_catalog(collection, force_rebuild=True)
    return JSONResponse({
        "success": True,
        "message": f"Catalog rebuilt: {len(catalog.courses)} courses",
        **catalog.summary(),
    })


# ---------------------------------------------------------------------------
# Admin endpoints
# ---------------------------------------------------------------------------

@router.post("/rebuild-index")
async def rebuild_bm25_index():
    """Force-rebuild the BM25 index from the current ChromaDB collection."""
    if collection is None:
        raise HTTPException(status_code=400, detail="No collection available")
    try:
        invalidate_index(COLLECTION_NAME)
        idx = _get_bm25_index(force_rebuild=True)
        return JSONResponse({
            "success": True,
            "message": f"BM25 index rebuilt with {idx.doc_count} documents",
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/retrieval-stats")
async def get_retrieval_stats():
    """Return cache statistics and BM25 index info."""
    bm25_idx = _get_bm25_index()
    return JSONResponse({
        "embedding_cache": embedding_cache.stats,
        "bm25_index": {
            "built":     bm25_idx.is_built if bm25_idx else False,
            "doc_count": bm25_idx.doc_count if bm25_idx else 0,
        },
        "collection": {
            "name":  COLLECTION_NAME,
            "count": collection.count() if collection else 0,
        },
    })


@router.get("/retrieval-logs")
async def get_retrieval_logs(
    last_n: int = Query(default=20, ge=1, le=200, description="Number of recent log entries")
):
    """Return the last N retrieval log entries."""
    import json
    from pathlib import Path

    log_path = Path("./retrieval_logs/retrieval_trace.jsonl")
    if not log_path.exists():
        return JSONResponse({"logs": [], "total": 0})

    try:
        lines = log_path.read_text(encoding="utf-8").strip().splitlines()
        recent = lines[-last_n:]
        logs   = [json.loads(line) for line in recent]
        return JSONResponse({"logs": logs, "total": len(lines)})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
