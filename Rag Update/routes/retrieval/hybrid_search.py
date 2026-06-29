"""
hybrid_search.py  (refactored)
================================
Production-grade hybrid retrieval with:
  - Adaptive RRF k based on score distribution
  - Enlarged + deduplicated multi-query dense pool
  - Dual BM25 search (clean + normalised query)
  - Score-gap adaptive fallback retrieval
  - Protected top-N semantic anchors (never filtered)
  - Dynamic distance threshold based on score distribution
  - Full stats for observability

Pipeline per query
------------------
  1. Query understanding  – program / year / semester / intent
  2. Multi-query dense    – embed all variants, deduplicate by best score
  3. Dual BM25 sparse     – clean query + normalised original
  4. Adaptive RRF fusion  – k tuned to score spread
  5. Legacy metadata filters (section / file / page)
  6. Section boosting     – metadata-aligned score bonus
  7. Intent filtering     – soft filter with protected anchors
  8. Fallback retrieval   – if pool is thin, widen distance and retry
  9. Return top-k
"""

from __future__ import annotations

import logging
import math
import re
import statistics
import sys
import time
from typing import Any, Optional

# Fix Windows encoding for debug output
if hasattr(sys.stderr, 'reconfigure'):
    try:
        sys.stderr.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass


def _stderr(msg: str) -> None:
    """Safe stderr write — silently ignores encoding errors on Windows."""
    try:
        if hasattr(sys.stderr, 'buffer'):
            sys.stderr.buffer.write(msg.encode('utf-8', errors='replace'))
        else:
            sys.stderr.write(msg.encode('utf-8', errors='replace').decode('utf-8', errors='replace'))
    except Exception:
        pass

from routes.arabic_cleaner import clean_arabic_text, detect_language
from routes.retrieval.bm25_index import BM25Index, get_or_build_index
from routes.retrieval.query_understanding import understand_query, RETRIEVAL_CONF_THRESHOLD, _INTENT_KEYWORDS
from routes.retrieval.section_booster import apply_section_boost, filter_by_intent
from sentence_transformers import CrossEncoder

# Load cross-encoder model once (cached in ./models)
_cross_encoder = CrossEncoder("cross-encoder/ms-marco-MiniLM-L-6-v2", cache_folder="models", device="cpu")

logger = logging.getLogger(__name__)

# ─────────────────────────────────────────────────────────────────────────────
# Tunable constants  (all documented with rationale)
# ─────────────────────────────────────────────────────────────────────────────

# RRF smoothing constant.
# Lower k → top ranks matter more (sharper discrimination).
# Higher k → more democratic (rare-but-correct chunks survive).
# 30 is better than 60 for short university regulation queries.
RRF_K = 30

# Candidate pool sizes — large enough to survive filtering stages
DEFAULT_DENSE_TOP_K  = 60
DEFAULT_SPARSE_TOP_K = 60
DEFAULT_FINAL_TOP_N  = 10

# Weighted fusion weights (used when BM25 is unavailable as RRF fallback)
DENSE_WEIGHT  = 0.65
SPARSE_WEIGHT = 0.35

# Issue 5/6: for curriculum queries, BM25 carries more signal because
# course names are exact keywords. Boost BM25 weight for these intents.
DENSE_WEIGHT_CURRICULUM  = 0.50
SPARSE_WEIGHT_CURRICULUM = 0.50
_CURRICULUM_INTENTS = {"subjects list", "schedule", "registration"}

# Primary L2 distance threshold.
# all-MiniLM-L6-v2 (384-dim, normalized): dist 1.0 ≈ cosine 0.50, dist 1.41 ≈ cosine 0.0
# 1.5 is permissive enough to catch Arabic chunks scored against English queries.
MAX_DISTANCE = 1.5

# Fallback distance threshold — used when the primary pool is too small.
# Wider net, applied only when fewer than FALLBACK_MIN_RESULTS survive.
MAX_DISTANCE_FALLBACK  = 1.8
FALLBACK_MIN_RESULTS   = 5   # trigger fallback if fewer results than this

# Section-boost filtering thresholds.
# Only apply strict filtering at very high confidence to avoid false negatives.
STRICT_FILTER_CONFIDENCE = 0.85
STRICT_FILTER_MIN_BOOST  = 0.05

# Safety: always keep at least this many top semantic results regardless of boost.
# Prevents the booster from discarding the best embedding match.
PROTECTED_TOP_N = 3

# Multi-query: max variants to embed (each costs one API call)
MAX_QUERY_VARIANTS = 3


# ─────────────────────────────────────────────────────────────────────────────
# Query normalization (backward-compat shim)
# ─────────────────────────────────────────────────────────────────────────────

def normalize_query(query: str) -> str:
    """Lightweight normalisation. Use understand_query() for full intent parsing."""
    cleaned = clean_arabic_text(
        query,
        remove_diacritics_flag=True,
        normalize_chars=True,
        fix_ocr=False,
        filter_noise=False,
        reset_seen_lines=True,
    )
    
    res = cleaned.strip() or query.strip()
    
    # Inject formal English terminology for dense embeddings on specific domains
    if any(k in res for k in ["سايبر", "سيبر", "هاكر", "هكر", "سيبراني", "امن معلومات"]):
        res += " cybersecurity information security cyber"

    # Arts / Translation — inject English so all-MiniLM finds the Eng1xx chunks
    if any(k in res for k in ["لغه انجليزيه", "لغة انجليزية", "لغة إنجليزية",
                               "ترجمه", "ترجمة", "مقررات اللغه", "مقررات اللغة",
                               "برنامج اللغه", "برنامج اللغة"]):
        res += " English translation courses Eng101 Eng102 program arts"

    # Prerequisites queries — inject course codes to find the right chunks
    if any(k in res for k in ["متطلب سابق", "متطلبات سابقة", "prerequisite",
                               "قبل ما اخد", "قبل ما اسجل", "شرط التسجيل",
                               "المتطلب", "متطلبه", "اتطلب"]):
        if any(k in res for k in ["ذكاء اصطناعي متقدم", "advanced artificial intelligence", "iot327"]):
            res += " IOT327 الذكاء الاصطناعي المتقدم Advanced Artificial Intelligence متطلب Introduction to Artificial Intelligence BCS322"
        else:
            res += " متطلب سابق prerequisite كود المقرر المتطلب السابق المصاحب"

    # GPA / CGPA calculation — inject formal terms so embeddings find the right chunks
    if any(k in res for k in ["احسب المعدل", "حساب المعدل", "بيتحسب المعدل",
                               "المعدل التراكمي", "gpa", "cgpa", "معدل تراكمي",
                               "ازاي المعدل", "كيف المعدل", "طريقة المعدل"]):
        res += " حساب المعدل التراكمي CGPA GPA نقاط ساعات معتمدة مجموع نقاط المقررات"

    return res


# ─────────────────────────────────────────────────────────────────────────────
# Program isolation  —  the 3-layer domain filter
# ─────────────────────────────────────────────────────────────────────────────

# Maps each canonical program to filename keywords that identify its PDFs.
# Used for pre-filter (ChromaDB where) and score boost.
_PROG_FILE_KEYWORDS: dict[str, list[str]] = {
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

# Course-code prefixes that HARD-BELONG to a specific program.
# A chunk containing these prefixes is ONLY valid for that program.
_PROG_HARD_PREFIXES: dict[str, set[str]] = {
    "computer science":  {"BCS", "MBS", "ICI", "SWE", "CIS", "CSC", "INF", "BIS", "AIS"},
    "medicine":          {"MED", "OPH", "ENT"},
    "dentistry":         {"DBM", "MGP", "DEN", "ORG", "DOP", "DOD", "DRP", "DFP", "DOS", "DPP", "DDE", "DD"},
    "engineering":       {"CVE", "MEC", "ELE", "CIV", "ARC", "ENG"},
    "pharmacy":          {"PHR", "PHA"},
    "law":               {"LAW"},
    "commerce":          {"ACC", "ECO", "MGT"},
    "nursing":           {"NUR", "NSG"},
    "veterinary":        {"VET", "VTR"},
    "physical therapy":  {"PHT", "PTH"},
}

# Prefixes that NEVER belong to CS — used for hard exclusion
_NON_CS_HARD = {"MED", "OPH", "ENT", "DBM", "MGP", "DEN", "ORG", "DOP", "DOD", "DRP", "DFP", "DOS", "DPP", "DDE", "DD",
                "CVE", "MEC", "ELE", "CIV", "ARC", "ENG",
                "PHR", "PHA", "LAW", "ACC", "ECO", "MGT",
                "NUR", "NSG", "VET", "VTR", "PHT", "PTH"}

_CODE_PREFIX_RE = re.compile(r"\b([A-Z]{2,4})\s*\d{3,4}\b", re.IGNORECASE)


def _chunk_program_score_single(chunk_text: str, chunk_meta: dict, program: str) -> float:
    """
    Return a score in [-1.0, +1.0] indicating how well a chunk belongs
    to the requested program.
    """
    fname        = (chunk_meta.get("fileName") or "").lower()
    section      = (chunk_meta.get("sectionTitle") or "").lower()
    meta_program = (chunk_meta.get("program") or "").lower().strip()
    content_ctx  = (fname + " " + section + " " + chunk_text[:300]).lower()
    
    # Normalize Arabic for robust matching
    _AR_NORM = str.maketrans({"\u0622": "\u0627", "\u0623": "\u0627", "\u0625": "\u0627", "\u0629": "\u0647"})
    content_ctx_norm = content_ctx.translate(_AR_NORM)

    prefixes_in_chunk = {
        m.group(1).upper() for m in _CODE_PREFIX_RE.finditer(chunk_text)
    }

    # ── Layer 1: Hard prefix (code-based) — highest priority ─────────────
    own_prefixes = _PROG_HARD_PREFIXES.get(program, set())
    if prefixes_in_chunk & own_prefixes:
        return 1.0

    for other_prog, other_prefixes in _PROG_HARD_PREFIXES.items():
        if other_prog == program:
            continue
        if prefixes_in_chunk & other_prefixes:
            return -1.0

    # ── Layer 2: Metadata 'program' field ────────────────────────────────
    if meta_program:
        # "general" = university-wide regulation → always neutral (never excluded)
        if meta_program == "general":
            return 0.0
        if meta_program == program:
            return 0.7
        # Check if meta_program matches any OTHER known program
        known_programs = set(_PROG_FILE_KEYWORDS.keys())
        if meta_program in known_programs and meta_program != program:
            return -0.7

    # ── Layer 3: Filename keywords ────────────────────────────────────────
    own_keywords   = _PROG_FILE_KEYWORDS.get(program, [])
    other_keywords = [
        kw for p, kws in _PROG_FILE_KEYWORDS.items()
        if p != program for kw in kws
    ]

    if any(kw in fname for kw in own_keywords):
        return 0.5
    if any(kw in fname for kw in other_keywords):
        return -0.5

    # ── Layer 4: Content-based (section title + first 300 chars of text) ─
    if any(kw in content_ctx or kw.translate(_AR_NORM) in content_ctx_norm for kw in own_keywords):
        return 0.3
    if any(kw in content_ctx or kw.translate(_AR_NORM) in content_ctx_norm for kw in other_keywords):
        return -0.3

    return 0.0


def _chunk_program_score(chunk_text: str, chunk_meta: dict, program: str | list[str]) -> float:
    """
    Wrap _chunk_program_score_single to support a list of programs.
    If multiple programs are queried, it will return the maximum score (best match).
    """
    if isinstance(program, list):
        if not program:
            return 0.0
        scores = [_chunk_program_score_single(chunk_text, chunk_meta, p) for p in program]
        return max(scores)
    return _chunk_program_score_single(chunk_text, chunk_meta, program)



def _apply_program_isolation(
    results: list[dict],
    program: str,
    boost_value: float = 0.4,
) -> list[dict]:
    """
    Layer 2 + 3: post-retrieval program filter + score boost.

    - Hard exclusion  (score == -1.0): remove chunk entirely
    - Negative score  (score == -0.5): remove chunk (wrong faculty file)
    - Neutral         (score ==  0.0): keep, no boost (shared courses)
    - Positive        (score >= +0.5): keep + boost score
    """
    # If the query is general, don't exclude anything, just boost 'general' metadata slightly
    if program == "general" or not program:
        for r in results:
            meta_program = (r.get("metadata", {}).get("program") or "").lower()
            if meta_program == "general":
                current = r.get("boosted_score", r.get("rrf_score", 0.0))
                r["boosted_score"] = current + boost_value * 0.5
                r["program_boosted"] = True
            else:
                r["program_boosted"] = False
        results.sort(key=lambda x: x.get("boosted_score", x.get("rrf_score", 0.0)), reverse=True)
        return results

    kept = []
    for r in results:
        ps = _chunk_program_score(r.get("text", ""), r.get("metadata", {}), program)
        r["program_score"] = ps

        # Updated isolation: exclude neutral chunks unless they belong to 'general' or no specific program
        # Positive scores (>=0.5) are boosted; negative scores are excluded.
        # Neutral (0.0) chunks are kept only if they are from a general document or if no program is detected.
        if ps < 0:
            # Wrong program — exclude
            continue
        if ps > 0:
            # Boost score for in-program chunks
            current = r.get("boosted_score", r.get("rrf_score", 0.0))
            r["boosted_score"] = current + boost_value * ps
            r["program_boosted"] = True
        else:
            # ps == 0: keep if from target program, general, or no program
            meta_program = (r.get("metadata", {}).get("program") or "").lower()
            _prog_str = program if isinstance(program, str) else ""
            if meta_program == "general" or not meta_program or meta_program == _prog_str:
                r["program_boosted"] = False
            else:
                # Exclude neutral chunks from other specific programs
                continue
        kept.append(r)

    try:
        _stderr(f"DEBUG ISOLATION: program={program} input={len(results)} kept={len(kept)}\n")
    except Exception:
        pass

    # If filtering removed everything, return top-K least-negative chunks
    # instead of the full original list to avoid cross-program leakage.
    # "least negative" = closest to 0 (neutral/shared) rather than -1 (hard wrong).
    if not kept:
        logger.warning(
            "[program_filter] All chunks excluded for program=%s — "
            "returning top-%d least-negative as safe fallback",
            program, FALLBACK_MIN_RESULTS,
        )
        # Sort by program_score descending (least negative first), then by rrf_score
        fallback = sorted(
            results,
            key=lambda x: (x.get("program_score", -1.0), x.get("rrf_score", 0.0)),
            reverse=True,
        )[:FALLBACK_MIN_RESULTS]
        for r in fallback:
            r.setdefault("program_boosted", False)
            r["fallback_isolation"] = True
        return fallback

    kept.sort(
        key=lambda x: x.get("boosted_score", x.get("rrf_score", 0.0)),
        reverse=True,
    )
    return kept


# ─────────────────────────────────────────────────────────────────────────────
# ChromaDB where-clause builder
# ─────────────────────────────────────────────────────────────────────────────

def _build_chroma_where(
    intent: QueryIntent,
    language_filter: Optional[str],
) -> Optional[dict]:
    """
    Build a ChromaDB metadata where-clause.
    """
    conditions = []
    
    # 1. Language filter
    if language_filter:
        conditions.append({"language": {"$eq": language_filter}})
    
    # 2. Program isolation filter
    if intent.program:
        if isinstance(intent.program, list):
            # If a list of programs is provided, we can't easily allow "general" intent without checking the list
            # But query_understanding currently only returns a string for intent.program or 'general'
            if intent.intent == "subjects list":
                conditions.append({"program": {"$in": intent.program + ["general"]}})
            elif "general" in intent.program:
                pass # Allow all programs if general is among the requested
            else:
                conditions.append({"program": {"$in": intent.program + ["general"]}})
        else:
            if intent.program == "general":
                pass # Do not filter by program if the query is general (search everywhere)
            elif intent.intent == "subjects list":
                conditions.append({"program": {"$in": [intent.program, "general"]}})
            else:
                conditions.append({"program": {"$in": [intent.program, "general"]}})
    
    if not conditions:
        _stderr("DEBUG WHERE: NO CONDITIONS\n")
        return None
    if len(conditions) == 1:
        _stderr(f"DEBUG WHERE: {conditions[0]}\n")
        return conditions[0]
    _stderr(f"DEBUG WHERE: AND {conditions}\n")
    return {"$and": conditions}


# ─────────────────────────────────────────────────────────────────────────────
# Adaptive RRF k
# ─────────────────────────────────────────────────────────────────────────────

def _adaptive_rrf_k(scores: list[float]) -> int:
    """
    Choose RRF k based on the score distribution of the top list.

    When scores are tightly clustered (low std-dev), use a smaller k so
    rank differences matter more. When scores are spread out, use a larger
    k to be more democratic and avoid over-penalising lower-ranked items.

    Returns a value in [20, 80].
    """
    if len(scores) < 2:
        return RRF_K
    try:
        std = statistics.stdev(scores)
        # High spread → larger k (more democratic)
        # Low spread  → smaller k (sharper discrimination)
        if std > 0.15:
            return 50
        elif std > 0.08:
            return 35
        else:
            return 20
    except Exception:
        return RRF_K


# ─────────────────────────────────────────────────────────────────────────────
# Dense retrieval
# ─────────────────────────────────────────────────────────────────────────────

def _generate_hyde_document(query: str, llm) -> str:
    """
    Generate a hypothetical document answering the query using the LLM.
    """
    prompt = (
        "اكتب إجابة تخيلية نموذجية على السؤال التالي لتساعد في البحث الدلالي داخل لوائح الجامعة الأهلية.\n"
        "القواعد:\n"
        "- اكتب فقرة واحدة قصيرة ومباشرة (لا تزيد عن 3 جمل).\n"
        "- استخدم صياغة رسمية باللغة العربية.\n"
        "- لا تذكر أن هذه إجابة تخيلية أو أنك نموذج ذكاء اصطناعي.\n"
        f"السؤال: {query}\n"
        "الإجابة النموذجية:"
    )
    try:
        resp = llm.invoke(prompt)
        content = resp.content if hasattr(resp, "content") else str(resp)
        return content.strip()
    except Exception as e:
        logger.warning(f"[hyde] Failed to generate HyDE document: {e}")
        return ""


# ─────────────────────────────────────────────────────────────────────────────
# Dense retrieval
# ─────────────────────────────────────────────────────────────────────────────

def dense_retrieve(
    query: str,
    collection,
    embeddings,
    top_k: int = DEFAULT_DENSE_TOP_K,
    where_filter: Optional[dict] = None,
    max_distance: float = MAX_DISTANCE,
    hyde_query: Optional[str] = None,
) -> list[dict]:
    """
    Embed the query and search ChromaDB.
    Falls back to local sentence-transformers if the API embedding fails.
    """
    try:
        query_embedding = embeddings.embed_query(query)
        if hyde_query:
            try:
                hyde_embedding = embeddings.embed_query(hyde_query)
                # Combine embeddings (average) and normalize
                combined = [0.5 * q + 0.5 * h for q, h in zip(query_embedding, hyde_embedding)]
                mag = math.sqrt(sum(x*x for x in combined))
                if mag > 0:
                    query_embedding = [x / mag for x in combined]
                logger.info("[dense] Combined query embedding with HyDE embedding")
            except Exception as hyde_err:
                logger.warning(f"[dense] Failed to embed/combine HyDE: {hyde_err}")
    except Exception as e:
        logger.warning(f"[dense] API embedding failed ({e}), trying local fallback...")
        try:
            from sentence_transformers import SentenceTransformer
            _local_model = getattr(dense_retrieve, "_local_model", None)
            if _local_model is None:
                logger.info("[dense] Loading local embedding model (paraphrase-multilingual-MiniLM-L12-v2)...")
                dense_retrieve._local_model = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")
                _local_model = dense_retrieve._local_model
            query_embedding = _local_model.encode(query, normalize_embeddings=True).tolist()
            if hyde_query:
                try:
                    hyde_embedding = _local_model.encode(hyde_query, normalize_embeddings=True).tolist()
                    combined = [0.5 * q + 0.5 * h for q, h in zip(query_embedding, hyde_embedding)]
                    mag = math.sqrt(sum(x*x for x in combined))
                    if mag > 0:
                        query_embedding = [x / mag for x in combined]
                    logger.info("[dense] Combined local query embedding with local HyDE embedding")
                except Exception as hyde_err:
                    logger.warning(f"[dense] Failed to local-embed/combine HyDE: {hyde_err}")
            logger.info("[dense] Local embedding fallback succeeded")
        except Exception as e2:
            logger.error(f"[dense] Local embedding fallback also failed: {e2}")
            return []

    n = min(top_k, max(collection.count(), 1))
    query_kwargs: dict[str, Any] = {
        "query_embeddings": [query_embedding],
        "n_results":        n,
        "include":          ["documents", "metadatas", "distances"],
    }
    if where_filter:
        query_kwargs["where"] = where_filter
        _stderr(f"DEBUG DENSE FILTER: {where_filter}\n")

    try:
        results = collection.query(**query_kwargs)
    except Exception as e:
        logger.warning(f"[dense] Query with filter failed ({e}), retrying without filter")
        query_kwargs.pop("where", None)
        try:
            results = collection.query(**query_kwargs)
        except Exception as e2:
            logger.error(f"[dense] ChromaDB query failed: {e2}")
            return []

    docs      = results.get("documents", [[]])[0]
    metas     = results.get("metadatas", [[]])[0]
    distances = results.get("distances", [[]])[0]
    ids       = results.get("ids", [[]])[0]
    _stderr(f"DEBUG DENSE RAW: found {len(ids)} chunks before max_distance filtering\n")

    output = []
    for rank, (doc, meta, dist, doc_id) in enumerate(
        zip(docs, metas, distances, ids), start=1
    ):
        if dist > max_distance:
            continue
        score = 1.0 / (1.0 + dist)
        output.append({
            "id":       doc_id,
            "text":     doc,
            "metadata": meta or {},
            "distance": dist,
            "score":    score,
            "rank":     rank,
        })

    logger.debug(f"[dense] {len(output)} results (top_k={top_k}, max_dist={max_distance})")
    return output


# ─────────────────────────────────────────────────────────────────────────────
# Multi-query dense retrieval
# ─────────────────────────────────────────────────────────────────────────────

def multi_query_dense_retrieve(
    variants: list[str],
    collection,
    embeddings,
    top_k_per_variant: int,
    where_filter: Optional[dict] = None,
    max_distance: float = MAX_DISTANCE,
    hyde_query: Optional[str] = None,
) -> list[dict]:
    """
    Run dense retrieval for each query variant and merge by best score.

    Key fix: top_k_per_variant is now the FULL top_k (not halved), so the
    union pool is at least as large as a single-query retrieval.
    """
    seen: dict[str, dict] = {}
    for i, variant in enumerate(variants[:MAX_QUERY_VARIANTS]):
        h_q = hyde_query if i == 0 else None
        results = dense_retrieve(
            query        = variant,
            collection   = collection,
            embeddings   = embeddings,
            top_k        = top_k_per_variant,
            where_filter = where_filter,
            max_distance = max_distance,
            hyde_query   = h_q,
        )
        for r in results:
            doc_id = r["id"]
            if doc_id not in seen or r["score"] > seen[doc_id]["score"]:
                seen[doc_id] = r

    return sorted(seen.values(), key=lambda x: x["score"], reverse=True)


# ─────────────────────────────────────────────────────────────────────────────
# Sparse retrieval
# ─────────────────────────────────────────────────────────────────────────────

def sparse_retrieve(
    query: str,
    bm25_index: BM25Index,
    top_k: int = DEFAULT_SPARSE_TOP_K,
) -> list[dict]:
    """BM25 keyword search over the indexed corpus."""
    if not bm25_index.is_built:
        logger.warning("[sparse] BM25 index not built – skipping keyword search")
        return []
    results = bm25_index.query(query, top_k=top_k)
    logger.debug(f"[sparse] {len(results)} results (top_k={top_k})")
    return results


def _dual_bm25_retrieve(
    clean_query: str,
    normalized_query: str,
    bm25_index: BM25Index,
    top_k: int,
) -> list[dict]:
    """
    Run BM25 on both the clean (English) query and the normalised original.
    Merge by best score per document.

    This ensures Arabic keyword matches (from the original) and English
    keyword matches (from the rewrite) both contribute to the sparse signal.
    """
    main = sparse_retrieve(clean_query,      bm25_index, top_k)
    orig = sparse_retrieve(normalized_query, bm25_index, top_k)

    merged: dict[str, dict] = {}
    for r in main + orig:
        doc_id = r["id"]
        if doc_id not in merged or r["score"] > merged[doc_id]["score"]:
            merged[doc_id] = r

    return sorted(merged.values(), key=lambda x: x["score"], reverse=True)


# ─────────────────────────────────────────────────────────────────────────────
# RRF fusion
# ─────────────────────────────────────────────────────────────────────────────

def reciprocal_rank_fusion(
    ranked_lists: list[list[dict]],
    k: int = RRF_K,
) -> list[dict]:
    """
    Merge multiple ranked lists using Reciprocal Rank Fusion.
    k is now passed explicitly so callers can use adaptive k.
    """
    rrf_scores: dict[str, float] = {}
    doc_store:  dict[str, dict]  = {}

    for ranked_list in ranked_lists:
        for rank, doc in enumerate(ranked_list, start=1):
            doc_id = doc["id"]
            rrf_scores[doc_id] = rrf_scores.get(doc_id, 0.0) + 1.0 / (k + rank)
            if doc_id not in doc_store:
                doc_store[doc_id] = doc

    merged = []
    for doc_id, rrf_score in sorted(
        rrf_scores.items(), key=lambda x: x[1], reverse=True
    ):
        entry = dict(doc_store[doc_id])
        entry["rrf_score"] = rrf_score
        merged.append(entry)

    return merged


# ─────────────────────────────────────────────────────────────────────────────
# Weighted-score fusion (fallback when BM25 unavailable)
# ─────────────────────────────────────────────────────────────────────────────

def _weighted_score_fusion(
    dense: list[dict],
    sparse: list[dict],
    dense_weight: float = DENSE_WEIGHT,
    sparse_weight: float = SPARSE_WEIGHT,
) -> list[dict]:
    def _norm(results: list[dict], key: str) -> dict[str, float]:
        scores = [r.get(key, 0.0) for r in results]
        lo, hi = min(scores, default=0.0), max(scores, default=1.0)
        span = hi - lo or 1.0
        return {r["id"]: (r.get(key, 0.0) - lo) / span for r in results}

    dn = _norm(dense,  "score")
    sn = _norm(sparse, "score")
    all_ids   = set(dn) | set(sn)
    doc_store = {r["id"]: r for r in dense + sparse}

    combined = []
    for doc_id in all_ids:
        score = dense_weight * dn.get(doc_id, 0.0) + sparse_weight * sn.get(doc_id, 0.0)
        entry = dict(doc_store[doc_id])
        entry["rrf_score"] = score
        combined.append(entry)

    return sorted(combined, key=lambda x: x["rrf_score"], reverse=True)


# ─────────────────────────────────────────────────────────────────────────────
# Legacy metadata filter (backward-compat)
# ─────────────────────────────────────────────────────────────────────────────

def apply_metadata_filters(
    results: list[dict],
    language_filter: Optional[str] = None,
    section_filter: Optional[str] = None,
    file_filter: Optional[str] = None,
    page_range: Optional[tuple[int, int]] = None,
) -> list[dict]:
    """Post-retrieval metadata filtering (legacy interface)."""
    filtered = []
    for doc in results:
        meta = doc.get("metadata", {})
        if language_filter:
            if meta.get("language") and meta.get("language") != language_filter:
                continue
        if section_filter:
            if section_filter.lower() not in (meta.get("sectionTitle") or "").lower():
                continue
        if file_filter:
            if file_filter.lower() not in (meta.get("fileName") or "").lower():
                continue
        if page_range:
            page = meta.get("page", 0)
            if not (page_range[0] <= page <= page_range[1]):
                continue
        filtered.append(doc)
    return filtered


# ─────────────────────────────────────────────────────────────────────────────
# Table / structured-content detection  (Req 6)
# ─────────────────────────────────────────────────────────────────────────────

# Course-code prefixes common in Egyptian university PDFs
_COURSE_CODE_RE = re.compile(
    r"\b[A-Z]{2,4}\s*\d{3,4}\b"          # e.g. BCS101, GEN 201, BAS 110
    r"|\b(?:BCS|GEN|BAS|CS|IT|ENG|MED|PHR|LAW|COM|SCI|EDU)\d*\b",
    re.IGNORECASE,
)

# Structural markers that indicate a curriculum table
_TABLE_MARKERS_AR = re.compile(
    r"الترم\s*(الاول|الثاني|الاول|الثاني)"
    r"|المستو[يى]\s*(الاول|الثاني|الثالث|الرابع)"
    r"|الفرق[هة]\s*(الاول[هى]?|التاني[هة]?|التالت[هة]?|الرابع[هة]?)"
    r"|ساع[هة]\s*معتمد[هة]?"
    r"|وحد[هة]\s*دراسي[هة]?"
    r"|اجباري|اختياري",
    re.IGNORECASE | re.UNICODE,
)
_TABLE_MARKERS_EN = re.compile(
    r"\b(?:credit\s*hours?|credit\s*units?|compulsory|elective|"
    r"semester\s*[12]|level\s*[1-4]|year\s*[1-4]|"
    r"course\s*code|course\s*title|prerequisites?)\b",
    re.IGNORECASE,
)


def _is_table_chunk(text: str) -> bool:
    """
    Return True if the chunk looks like a curriculum table or structured
    course list. These chunks should be strongly boosted.

    Heuristics:
      - Contains course codes (BCS101, GEN201, …)
      - Contains Arabic/English table markers
      - Has many numbers relative to text length (column data)
    """
    if not text:
        return False

    # Course codes are the strongest signal
    if _COURSE_CODE_RE.search(text):
        return True

    # Arabic or English structural markers
    if _TABLE_MARKERS_AR.search(text) or _TABLE_MARKERS_EN.search(text):
        return True

    # High digit density (tables have lots of numbers: credit hours, codes)
    digits = sum(1 for c in text if c.isdigit())
    if len(text) > 50 and digits / len(text) > 0.08:
        return True

    return False


def _table_boost(fused: list[dict], boost_value: float = 0.25) -> list[dict]:
    """
    Apply a score bonus to chunks that look like curriculum tables.
    Re-sorts by boosted_score after applying.
    """
    for r in fused:
        if _is_table_chunk(r.get("text", "")):
            current = r.get("boosted_score", r.get("rrf_score", 0.0))
            r["boosted_score"]   = current + boost_value
            r["table_boosted"]   = True
        else:
            r.setdefault("table_boosted", False)
    fused.sort(
        key=lambda x: x.get("boosted_score", x.get("rrf_score", 0.0)),
        reverse=True,
    )
    return fused

def _boost_and_filter(
    fused: list[dict],
    query_intent: QueryIntent,
) -> list[dict]:
    """
    Apply section boosting and intent filtering with protected top-N anchors.

    Protection rule: the top PROTECTED_TOP_N results by raw rrf_score are
    NEVER removed by the intent filter, even if they have zero boost.
    This prevents the booster from discarding the best semantic match.
    """
    # Identify protected anchors (top semantic results before boosting)
    protected_ids = {r["id"] for r in fused[:PROTECTED_TOP_N]}

    # Apply boost
    boosted = apply_section_boost(fused, query_intent)

    # Apply intent filter only at high confidence
    if query_intent.confidence >= STRICT_FILTER_CONFIDENCE:
        filtered = filter_by_intent(
            boosted,
            query_intent,
            min_boost=STRICT_FILTER_MIN_BOOST,
            fallback_if_empty=True,
        )
        # Re-inject any protected anchors that were filtered out
        filtered_ids = {r["id"] for r in filtered}
        for r in boosted:
            if r["id"] in protected_ids and r["id"] not in filtered_ids:
                filtered.append(r)
                logger.debug(f"[boost] Re-injected protected anchor: {r['id'][:20]}")
        boosted = filtered

    # Final sort by boosted_score
    boosted.sort(
        key=lambda x: x.get("boosted_score", x.get("rrf_score", 0.0)),
        reverse=True,
    )
    return boosted


# ─────────────────────────────────────────────────────────────────────────────
# Fallback retrieval
# ─────────────────────────────────────────────────────────────────────────────

def _fallback_retrieve(
    search_query: str,
    query_intent: QueryIntent,
    collection,
    embeddings,
    bm25_index: Optional[BM25Index],
    top_k: int,
) -> list[dict]:
    """
    Widen the distance threshold and retry retrieval when the primary pool
    is too small. Uses the original query (not the rewrite) to maximise recall.
    """
    logger.info("[hybrid] Fallback retrieval triggered (widening distance threshold)")

    # Use the raw original query for maximum recall
    fallback_query = query_intent.raw_query

    dense = dense_retrieve(
        query        = fallback_query,
        collection   = collection,
        embeddings   = embeddings,
        top_k        = top_k * 2,
        max_distance = MAX_DISTANCE_FALLBACK,
    )

    sparse: list[dict] = []
    if bm25_index and bm25_index.is_built:
        sparse = sparse_retrieve(fallback_query, bm25_index, top_k * 2)

    if sparse:
        fused = reciprocal_rank_fusion([dense, sparse], k=RRF_K)
    else:
        fused = dense

    for r in fused:
        r.setdefault("rrf_score", r.get("score", 0.0))
        r["boosted_score"] = r["rrf_score"]
        r["boost_applied"] = 0.0
        r["fallback"] = True

    return fused


# ─────────────────────────────────────────────────────────────────────────────
# Main hybrid search
# ─────────────────────────────────────────────────────────────────────────────

def hybrid_search(
    query: str,
    collection,
    embeddings,
    bm25_index: Optional[BM25Index] = None,
    top_k: int = DEFAULT_FINAL_TOP_N,
    dense_candidates: int = DEFAULT_DENSE_TOP_K,
    sparse_candidates: int = DEFAULT_SPARSE_TOP_K,
    use_rrf: bool = True,
    language_filter: Optional[str] = None,
    section_filter: Optional[str] = None,
    file_filter: Optional[str] = None,
    page_range: Optional[tuple[int, int]] = None,
    use_query_understanding: bool = True,
    use_multi_query: bool = True,
    use_section_boost: bool = True,
    query_intent: Optional[QueryIntent] = None,
    llm: Optional[Any] = None,
    use_hyde: bool = True,
) -> dict:
    """
    Full hybrid retrieval pipeline.

    Returns
    -------
    dict with keys:
        query_original, query_normalized, query_language,
        query_intent, results, retrieval_stats
    """
    t_start = time.perf_counter()
    _stderr(f"DEBUG HYBRID ARGS: top_k={top_k} dense_cand={dense_candidates} sparse_cand={sparse_candidates} use_rrf={use_rrf} lang={language_filter}\n")
    _stderr(f"DEBUG HYBRID: Starting search for '{query[:40]}...'\n")

    # ── 1. Query understanding ────────────────────────────────────────────
    if query_intent is None and use_query_understanding:
        query_intent = understand_query(query)
    elif query_intent is None:
        from routes.retrieval.query_understanding import QueryIntent as QI
        norm = normalize_query(query)
        query_intent = QI(raw_query=query, normalized_query=norm, clean_query=norm)

    search_query   = query_intent.clean_query
    query_language = detect_language(query_intent.normalized_query)

    logger.info(
        f"[hybrid] '{query[:60]}' → '{search_query[:60]}' | "
        f"program={query_intent.program} year={query_intent.year} "
        f"intent={query_intent.intent} conf={query_intent.confidence:.2f}"
    )

    # ── 2. ChromaDB pre-filter ────────────────────────────────────────────
    chroma_where = _build_chroma_where(query_intent, language_filter)

    # ── 3. Dense retrieval ────────────────────────────────────────────────
    t_dense = time.perf_counter()

    hyde_doc = None
    if use_hyde and llm:
        hyde_doc = _generate_hyde_document(search_query, llm)
        if hyde_doc:
            logger.info(f"[hybrid] Generated HyDE document: '{hyde_doc[:120]}...'")

    if use_multi_query and len(query_intent.query_variants) > 1:
        # Fix: use full dense_candidates per variant (not halved)
        dense_results = multi_query_dense_retrieve(
            variants           = query_intent.query_variants,
            collection         = collection,
            embeddings         = embeddings,
            top_k_per_variant  = dense_candidates,   # ← was dense_candidates // 2
            where_filter       = chroma_where,
            hyde_query         = hyde_doc,
        )
    else:
        dense_results = dense_retrieve(
            query        = search_query,
            collection   = collection,
            embeddings   = embeddings,
            top_k        = dense_candidates,
            where_filter = chroma_where,
            hyde_query         = hyde_doc,
        )

    t_dense_ms = (time.perf_counter() - t_dense) * 1000

    # ── 4. Sparse retrieval (dual BM25) ───────────────────────────────────
    t_sparse = time.perf_counter()
    sparse_results: list[dict] = []

    if bm25_index is not None and bm25_index.is_built:
        norm_query_expanded = query_intent.normalized_query
        if query_intent.intent in _INTENT_KEYWORDS:
            # Append intent-specific Arabic keywords to catch relevant chunks even if the exact query terms are missing
            norm_query_expanded += " " + " ".join(_INTENT_KEYWORDS[query_intent.intent])
            
        # General Query Expansion for missing intents or general questions
        general_expansions = {
            "رئيس الجامعة": ["تاسيس", "رئيس", "جامعة المنوفية", "منصب"],
            "شروط القبول": ["التقديم", "تنسيق", "التحاق", "قبول الطلاب"],
            "رسوم": ["مصاريف", "مصروفات", "دفع", "تكلفة", "الرسوم الدراسية"],
        }
        for k, v in general_expansions.items():
            if k in query_intent.raw_query:
                norm_query_expanded += " " + " ".join(v)
            
        sparse_results = _dual_bm25_retrieve(
            clean_query      = search_query,
            normalized_query = norm_query_expanded,
            bm25_index       = bm25_index,
            top_k            = sparse_candidates,
        )
    else:
        logger.debug("[hybrid] BM25 unavailable – dense-only retrieval")

    t_sparse_ms = (time.perf_counter() - t_sparse) * 1000

    # ── 5. Adaptive RRF fusion ────────────────────────────────────────────
    t_fusion = time.perf_counter()

    if sparse_results and use_rrf:
        # Compute adaptive k from the dense score distribution
        dense_scores = [r["score"] for r in dense_results]
        adaptive_k   = _adaptive_rrf_k(dense_scores)
        fused = reciprocal_rank_fusion([dense_results, sparse_results], k=adaptive_k)
        _stderr(f"DEBUG FUSION: rrf_adaptive input={[len(dense_results), len(sparse_results)]} fused={len(fused)}\n")
        logger.debug(f"[hybrid] Adaptive RRF k={adaptive_k}")
    elif sparse_results:
        # Issue 5/6: use curriculum-aware weights for weighted fusion
        is_curriculum = query_intent.intent in _CURRICULUM_INTENTS
        fused = _weighted_score_fusion(
            dense_results,
            sparse_results,
            dense_weight  = DENSE_WEIGHT_CURRICULUM  if is_curriculum else DENSE_WEIGHT,
            sparse_weight = SPARSE_WEIGHT_CURRICULUM if is_curriculum else SPARSE_WEIGHT,
        )
    else:
        fused = list(dense_results)

    # Ensure rrf_score exists on all items (dense-only path)
    for r in fused:
        r.setdefault("rrf_score", r.get("score", 0.0))

    t_fusion_ms = (time.perf_counter() - t_fusion) * 1000

    # ── 6. Legacy metadata filters ────────────────────────────────────────
    if any([section_filter, file_filter, page_range]):
        fused = apply_metadata_filters(
            fused,
            section_filter=section_filter,
            file_filter=file_filter,
            page_range=page_range,
        )

    # ── 7. Section boosting + protected filtering ─────────────────────────
    t_boost = time.perf_counter()

    if use_section_boost:
        fused = _boost_and_filter(fused, query_intent)
    else:
        for r in fused:
            r["boosted_score"] = r.get("rrf_score", 0.0)
            r["boost_applied"] = 0.0

    # ── 7a. Program isolation (Strengthened Metadata Filtering) ───────
    if query_intent.program:
        fused = _apply_program_isolation(fused, query_intent.program, boost_value=0.5)

    # ── 7b. Table / structured-content boost (Req 6) ─────────────────────
    # Curriculum table chunks get an extra +0.25 regardless of metadata.
    # This fires for all queries — table chunks are almost always relevant.
    fused = _table_boost(fused, boost_value=0.25)

    # ── 7c. Keyword anchor boost ──────────────────────────────────────────
    # For queries with specific keywords (e.g. named entities, titles),
    # exact BM25 term matches may be buried by OCR noise in the chunk.
    # Boost any chunk that contains NORMALIZED query terms as exact substrings.
    # This is especially useful for "من هو رئيس الجامعة" type queries.
    _norm_q_terms = set(re.findall(r"[\u0600-\u06FF]{3,}", query_intent.normalized_query))
    # Remove very common stopwords
    _STOPWORDS_AR = {"من", "هو", "هي", "ما", "هي", "في", "على", "عن", "مع", "كم", "هل",
                     "اي", "أي", "كيف", "متى", "الي", "إلى", "الى", "عند", "لكل",
                     "يمكن", "كان", "يكون", "تكون", "الذي", "التي", "الجامعة"}
    _norm_q_terms -= _STOPWORDS_AR
    if _norm_q_terms:
        for r in fused:
            chunk_text_norm = r.get("text", "").lower()
            matched = sum(1 for t in _norm_q_terms if t in chunk_text_norm)
            if matched >= 2:  # at least 2 key terms must match
                current = r.get("boosted_score", r.get("rrf_score", 0.0))
                boost = 0.6 * (matched / len(_norm_q_terms))
                r["boosted_score"] = current + boost
                r["keyword_anchor_boosted"] = True
        # Re-sort after keyword boost
        fused.sort(key=lambda x: x.get("boosted_score", x.get("rrf_score", 0.0)), reverse=True)

    # ── 7d. Manual-correction boost ───────────────────────────────────────
    # Chunks from manually corrected pages (e.g. arts course tables) always
    # rank highly for subjects-list queries on the same program.
    if query_intent.intent in ("subjects list", "schedule") and query_intent.program:
        for r in fused:
            meta = r.get("metadata", {})
            if (meta.get("extraction_method") == "manual_correction"
                    and meta.get("program") == query_intent.program):
                current = r.get("boosted_score", r.get("rrf_score", 0.0))
                r["boosted_score"] = current + 1.5
                r["manual_correction_boosted"] = True
        fused.sort(key=lambda x: x.get("boosted_score", x.get("rrf_score", 0.0)), reverse=True)
    def cross_encoder_rerank(query: str, results: list[dict], top_n: int = 20) -> list[dict]:
        """Re‑rank top results using a cross‑encoder model for relevance scoring.

        The cross‑encoder takes a (query, candidate) pair and returns a relevance score.
        Only the top_n candidates are re‑scored for efficiency.
        """
        try:
            # Encode query‑candidate pairs
            pairs = [(query, r.get("text", "")) for r in results[:top_n]]
            scores = _cross_encoder.predict(pairs)
        except Exception as e:
            logger.warning(f"[cross‑encoder] Scoring failed: {e}")
            return results
        import math
        # Attach scores and re‑sort
        for r, sc in zip(results[:top_n], scores):
            r["cross_score"] = float(sc)
            # Adjust fusion logic: Increase cross-encoder weight
            current_score = r.get("boosted_score", r.get("rrf_score", 0.0))
            try:
                sig_sc = 1 / (1 + math.exp(-float(sc)))
            except OverflowError:
                sig_sc = 0.0 if float(sc) < 0 else 1.0
            # Fusion: heavily boost relevant documents per cross-encoder
            r["boosted_score"] = current_score + (sig_sc * 2.5)
            
        # Sort the top_n by boosted_score descending
        results[:top_n] = sorted(results[:top_n], key=lambda r: r.get("boosted_score", 0.0), reverse=True)
        return results

    # Always apply cross‑encoder re‑ranking to improve relevance overall
    fused = cross_encoder_rerank(search_query, fused, top_n=20)


    t_boost_ms = (time.perf_counter() - t_boost) * 1000

    # ── 8. Fallback retrieval (if pool is too thin) ───────────────────────
    used_fallback = False
    if len(fused) < FALLBACK_MIN_RESULTS:
        fallback = _fallback_retrieve(
            search_query = search_query,
            query_intent = query_intent,
            collection   = collection,
            embeddings   = embeddings,
            bm25_index   = bm25_index,
            top_k        = top_k,
        )
        # Merge fallback results, keeping existing items at their positions
        existing_ids = {r["id"] for r in fused}
        for r in fallback:
            if r["id"] not in existing_ids:
                fused.append(r)
        fused.sort(
            key=lambda x: x.get("boosted_score", x.get("rrf_score", 0.0)),
            reverse=True,
        )
        used_fallback = True
        logger.info(f"[hybrid] Fallback added {len(fused)} total results")

    # ── 9. Force-include highly relevant chunks (Req 9) ───────────────────
    # If any chunk in the full fused pool is a table chunk AND matches the
    # query year/semester, guarantee it appears in the final top_k.
    # This prevents a table chunk ranked at position top_k+1 from being cut.
    final_results = fused[:top_k]
    if query_intent.year or query_intent.semester:
        final_ids = {r["id"] for r in final_results}
        for r in fused[top_k:top_k + 10]:   # check next 10 beyond the cut
            if r.get("table_boosted") and r["id"] not in final_ids:
                # Replace the lowest-scoring non-table chunk
                non_table = [
                    i for i, x in enumerate(final_results)
                    if not x.get("table_boosted")
                ]
                if non_table:
                    replace_idx = non_table[-1]
                    logger.info(
                        f"[hybrid] Force-including table chunk {r['id'][:20]} "
                        f"(displaced rank-{replace_idx + 1} non-table chunk)"
                    )
                    final_results[replace_idx] = r
                    break

    # ── 9b. Force-include GPA-based registration-limit chunks ─────────────
    # Queries about GPA/CGPA often need the university-wide rule on max/min
    # credit-hour load for students with low GPA (e.g. "حتى 8 ساعات معتمدة
    # للطالب الحاصل على معدل تراكمي..."). These live in the general
    # regulations doc and can be outranked by program-specific course
    # tables. Guarantee at least one such chunk survives into top_k.
    _gpa_query = any(
        k in query_intent.normalized_query or k in query_intent.raw_query.lower()
        for k in ["gpa", "cgpa", "معدل", "تراكمي"]
    )
    if _gpa_query:
        final_ids = {r["id"] for r in final_results}
        _gpa_rule_re = re.compile(r"معدل\s*تراكم.{0,30}ساع|ساع.{0,30}معدل\s*تراكم")
        for r in fused:
            if r["id"] in final_ids:
                continue
            if _gpa_rule_re.search(r.get("text", "")):
                non_table = [
                    i for i, x in enumerate(final_results)
                    if not x.get("table_boosted") and not x.get("manual_correction_boosted")
                ]
                if non_table:
                    replace_idx = non_table[-1]
                    logger.info(
                        f"[hybrid] Force-including GPA-rule chunk {r['id'][:20]} "
                        f"(displaced rank-{replace_idx + 1})"
                    )
                    final_results[replace_idx] = r
                break

    t_total_ms = (time.perf_counter() - t_start) * 1000

    table_chunks = sum(1 for r in final_results if r.get("table_boosted"))
    prog_boosted = sum(1 for r in final_results if r.get("program_boosted"))

    # ── Confidence gating ─────────────────────────────────────────────────
    # Compute the max retrieval score across final results.
    # If it's below the threshold, flag the response as low-confidence so
    # the caller can ask for clarification instead of returning a weak answer.
    max_retrieval_score = max(
        (r.get("boosted_score", r.get("rrf_score", 0.0)) for r in final_results),
        default=0.0,
    )
    low_retrieval_confidence = (
        max_retrieval_score < RETRIEVAL_CONF_THRESHOLD
        or len(final_results) == 0
    )
    if low_retrieval_confidence:
        logger.info(
            "[hybrid] Low retrieval confidence: max_score=%.3f threshold=%.3f results=%d",
            max_retrieval_score, RETRIEVAL_CONF_THRESHOLD, len(final_results),
        )

    stats = {
        "dense_candidates":        len(dense_results),
        "sparse_candidates":       len(sparse_results),
        "fused_candidates":        len(fused),
        "final_results":           len(final_results),
        "table_chunks":            table_chunks,
        "program_boosted":         prog_boosted,
        "program_filter":          query_intent.program,
        "used_fallback":           used_fallback,
        "max_retrieval_score":     round(max_retrieval_score, 4),
        "low_retrieval_confidence": low_retrieval_confidence,
        "timing_ms": {
            "dense":  round(t_dense_ms, 1),
            "sparse": round(t_sparse_ms, 1),
            "fusion": round(t_fusion_ms, 1),
            "boost":  round(t_boost_ms, 1),
            "total":  round(t_total_ms, 1),
        },
        "fusion_method": (
            "rrf_adaptive" if (sparse_results and use_rrf) else
            "weighted"     if sparse_results else
            "dense_only"
        ),
        "query_understanding": {
            "program":          query_intent.program,
            "year":             query_intent.year,
            "semester":         query_intent.semester,
            "intent":           query_intent.intent,
            "confidence":       round(query_intent.confidence, 2),
            "clean_query":      query_intent.clean_query,
            "classifier_tier":  getattr(query_intent, "classifier_tier", "rule_based"),
        },
    }

    logger.info(
        f"[hybrid] Done: dense={len(dense_results)}, sparse={len(sparse_results)}, "
        f"final={len(final_results)}, fallback={used_fallback}, total={t_total_ms:.0f}ms"
    )

    return {
        "query_original":   query,
        "query_normalized": query_intent.normalized_query,
        "query_language":   query_language,
        "query_intent":     query_intent,
        "results":          final_results,
        "retrieval_stats":  stats,
    }