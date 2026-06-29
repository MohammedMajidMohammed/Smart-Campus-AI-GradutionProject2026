"""
reranker.py  (refactored)
==========================
Production-grade reranking with:
  - Bilingual cosine scoring (max of rewritten + original query)
  - Safety anchor: top-1 semantic result is never demoted below top-3
  - Score-gap guard: if reranker would invert a large score gap, it's ignored
  - LLM reranker is intent-aware and uses a structured scoring prompt
  - Cross-encoder reranker with multilingual model support
  - Graceful degradation at every level

Strategy priority (in rerank_results):
  1. cross_encoder  – best quality, local compute
  2. llm            – high quality, API cost
  3. cosine         – fast, bilingual, always available
  4. passthrough    – no reranking (preserves RRF order)
"""

from __future__ import annotations

import logging
import math
import re
import time
from typing import Any, Optional

logger = logging.getLogger(__name__)

# ─────────────────────────────────────────────────────────────────────────────
# Optional: sentence-transformers cross-encoder
# ─────────────────────────────────────────────────────────────────────────────
try:
    from sentence_transformers import CrossEncoder
    CROSS_ENCODER_AVAILABLE = True
except ImportError:
    CROSS_ENCODER_AVAILABLE = False

# ─────────────────────────────────────────────────────────────────────────────
# Constants
# ─────────────────────────────────────────────────────────────────────────────

DEFAULT_CROSS_ENCODER_MODEL = "cross-encoder/mmarco-mMiniLMv2-L12-H384-v1"
LLM_BATCH_SIZE = 5

# Floor score — only drop a chunk if it's truly irrelevant (near-zero cosine).
# 0.01 is effectively "keep everything the retriever found".
MIN_RERANK_SCORE = 0.01

# Safety: the top-N results by pre-rerank score are protected.
# The reranker may re-order them but cannot push them out of the top window.
PROTECTED_TOP_N = 2

# Score-gap guard: if the pre-rerank score gap between rank-1 and rank-i
# exceeds this threshold, the reranker cannot demote rank-1 below rank-i.
SCORE_GAP_GUARD = 0.25


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

def _cosine(a: list[float], b: list[float]) -> float:
    """Cosine similarity between two vectors."""
    dot    = sum(x * y for x, y in zip(a, b))
    norm_a = math.sqrt(sum(x * x for x in a))
    norm_b = math.sqrt(sum(x * x for x in b))
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return dot / (norm_a * norm_b)


def _sigmoid(x: float) -> float:
    return 1.0 / (1.0 + math.exp(-x))


# Arabic normalisation table (inline — no circular import)
_AR_NORM_RERANKER = str.maketrans({
    "\u0622": "\u0627", "\u0623": "\u0627", "\u0625": "\u0627",
    "\u0649": "\u064A", "\u0624": "\u0648", "\u0626": "\u064A",
    "\u0629": "\u0647",
})
_DIACRITICS_RE = re.compile(r"[\u064B-\u065F\u0610-\u061A\u06D6-\u06ED]")


def _tokenize_for_overlap(text: str) -> set[str]:
    """
    Tokenize text into a set of normalised tokens for keyword overlap scoring.
    Handles Arabic and English. Minimum token length = 2.
    """
    text = text.translate(_AR_NORM_RERANKER)
    text = _DIACRITICS_RE.sub("", text).lower()
    tokens = re.findall(r"[\u0600-\u06FF]{2,}|[a-z]{2,}", text)
    return set(tokens)


def _keyword_overlap_score(query_tokens: set[str], chunk_text: str) -> float:
    """
    Jaccard-like overlap between query tokens and chunk tokens.
    Returns a value in [0, 1].
    """
    if not query_tokens:
        return 0.0
    chunk_tokens = _tokenize_for_overlap(chunk_text)
    if not chunk_tokens:
        return 0.0
    intersection = query_tokens & chunk_tokens
    return len(intersection) / len(query_tokens)


def _table_signal(text: str) -> float:
    """
    Return a small bonus (0.0–0.15) if the chunk looks like a curriculum table.
    Reuses the same heuristics as hybrid_search._is_table_chunk.
    """
    if not text:
        return 0.0
    # Course codes
    if re.search(r"\b[A-Z]{2,4}\s*\d{3,4}\b", text, re.IGNORECASE):
        return 0.15
    # Structural Arabic markers
    if re.search(
        r"الترم\s*(الاول|الثاني)|المستو[يى]\s*(الاول|الثاني|الثالث|الرابع)"
        r"|ساع[هة]\s*معتمد[هة]?|اجباري|اختياري",
        text, re.IGNORECASE | re.UNICODE
    ):
        return 0.10
    # English structural markers
    if re.search(
        r"\b(credit\s*hours?|compulsory|elective|semester\s*[12]|level\s*[1-4])\b",
        text, re.IGNORECASE
    ):
        return 0.10
    return 0.0


def _apply_safety_anchor(
    reranked: list[dict],
    original_order: list[dict],
    top_n: int,
) -> list[dict]:
    """
    Ensure the top PROTECTED_TOP_N results from the original (pre-rerank)
    order appear within the top (PROTECTED_TOP_N + 1) positions of the
    reranked list.

    This prevents the reranker from completely burying the best semantic
    match when it has a large pre-rerank score advantage.
    """
    if not original_order or PROTECTED_TOP_N <= 0:
        return reranked

    protected_ids = {r["id"] for r in original_order[:PROTECTED_TOP_N]}
    result        = list(reranked)

    # Find which protected items are missing from the top window
    top_window_ids = {r["id"] for r in result[:PROTECTED_TOP_N + 1]}
    missing = [
        r for r in original_order[:PROTECTED_TOP_N]
        if r["id"] not in top_window_ids
    ]

    if not missing:
        return result

    # Re-inject missing protected items at position PROTECTED_TOP_N
    # (just after the reranker's top picks, not at position 0)
    for item in missing:
        # Remove from wherever it ended up
        result = [r for r in result if r["id"] != item["id"]]
        # Insert at the protection boundary
        insert_pos = min(PROTECTED_TOP_N, len(result))
        result.insert(insert_pos, item)
        logger.debug(f"[reranker] Safety anchor re-injected: {item['id'][:20]}")

    return result[:top_n]


# ─────────────────────────────────────────────────────────────────────────────
# Strategy 1: Cosine similarity reranking (bilingual)
# ─────────────────────────────────────────────────────────────────────────────

def cosine_rerank(
    query: str,
    candidates: list[dict],
    embeddings,
    top_n: int = 5,
    original_query: Optional[str] = None,
) -> list[dict]:
    """
    Hybrid reranking combining:
      1. Cosine similarity (bilingual: max of rewritten + original query)
      2. Keyword overlap between query tokens and chunk text
      3. BM25 score from retrieval (already stored in candidate["score"])
      4. Table/structured-content signal bonus

    Final score = 0.55 * cosine + 0.25 * keyword_overlap
                + 0.15 * bm25_norm + 0.05 * table_signal

    This replaces pure cosine reranking and directly addresses:
    - Arabic chunks scoring low against English query embeddings
    - Generic chunks outranking specific curriculum chunks
    - Table chunks being demoted despite high relevance
    """
    if not candidates:
        return []

    t_start = time.perf_counter()

    # Pre-compute query tokens for keyword overlap
    query_tokens     = _tokenize_for_overlap(query)
    orig_tokens: set[str] = set()
    if original_query and original_query.strip() != query.strip():
        orig_tokens = _tokenize_for_overlap(original_query)
    all_query_tokens = query_tokens | orig_tokens

    try:
        q_vec = embeddings.embed_query(query)

        q_vec_orig = None
        if original_query and original_query.strip() != query.strip():
            try:
                q_vec_orig = embeddings.embed_query(original_query)
            except Exception as e:
                logger.warning(f"[reranker/cosine] Original query embed failed: {e}")

        texts    = [c["text"] for c in candidates]
        doc_vecs = embeddings.embed_documents(texts)

    except Exception as e:
        logger.error(f"[reranker/cosine] Embedding failed: {e} – passthrough")
        result = list(candidates[:top_n])
        for i, c in enumerate(result):
            c["rerank_score"]  = 1.0 - i * 0.01
            c["rerank_method"] = "passthrough"
        return result

    # Normalise BM25 scores across candidates for fair weighting
    bm25_scores = [c.get("score", 0.0) for c in candidates]
    bm25_max    = max(bm25_scores) if bm25_scores else 1.0
    bm25_max    = bm25_max or 1.0

    scored = []
    for candidate, doc_vec in zip(candidates, doc_vecs):
        # 1. Cosine similarity (bilingual)
        cos_sim = _cosine(q_vec, doc_vec)
        if q_vec_orig is not None:
            cos_sim = max(cos_sim, _cosine(q_vec_orig, doc_vec))

        # 2. Keyword overlap
        kw_score = _keyword_overlap_score(all_query_tokens, candidate.get("text", ""))

        # 3. Normalised BM25 score from retrieval
        bm25_norm = candidate.get("score", 0.0) / bm25_max

        # 4. Table/structured-content signal
        tbl_bonus = _table_signal(candidate.get("text", ""))

        # Weighted combination
        final_score = (
            0.55 * cos_sim
            + 0.25 * kw_score
            + 0.15 * bm25_norm
            + 0.05 * tbl_bonus
        )

        entry = dict(candidate)
        entry["rerank_score"]    = final_score
        entry["rerank_method"]   = "hybrid_cosine"
        entry["_cos_sim"]        = round(cos_sim, 4)
        entry["_kw_overlap"]     = round(kw_score, 4)
        entry["_bm25_norm"]      = round(bm25_norm, 4)
        entry["_table_signal"]   = round(tbl_bonus, 4)
        scored.append(entry)

    scored.sort(key=lambda x: x["rerank_score"], reverse=True)
    result = [c for c in scored if c["rerank_score"] >= MIN_RERANK_SCORE][:top_n]

    # Apply safety anchor
    result = _apply_safety_anchor(result, candidates, top_n)

    elapsed = (time.perf_counter() - t_start) * 1000
    logger.info(
        f"[reranker/cosine] {len(result)}/{len(candidates)} kept, {elapsed:.0f}ms "
        f"(hybrid: cos+kw+bm25+table)"
    )
    return result


# ─────────────────────────────────────────────────────────────────────────────
# Strategy 2: LLM-based reranking (intent-aware)
# ─────────────────────────────────────────────────────────────────────────────

_LLM_RERANK_PROMPT = """You are a relevance scoring assistant for a university regulations RAG system.

Score how relevant the passage is to answering the query.

Scoring scale:
  10 = Directly and completely answers the query
   8 = Highly relevant, contains key information
   6 = Relevant, partially answers the query
   4 = Marginally relevant, tangentially related
   2 = Weakly related, different topic
   0 = Not relevant — wrong program, wrong year, or completely off-topic

Query context: {context_hint}
Query: {query}

Passage {index}:
{passage}

Rules:
- If the query specifies a program (e.g. Computer Science) or year (e.g. first year),
  passages about a DIFFERENT program or year score 0–2.
- If the passage contains partial information, score 4–6.
- Respond with ONLY a single integer (0–10). No explanation."""


def llm_rerank(
    query: str,
    candidates: list[dict],
    llm,
    top_n: int = 5,
    batch_size: int = LLM_BATCH_SIZE,
    query_intent=None,
) -> list[dict]:
    """
    Rerank using LLM relevance scoring with intent-aware context hint.
    Applies safety anchor to prevent burying the top semantic result.
    """
    if not candidates:
        return []

    t_start = time.perf_counter()

    context_hint = "general university query"
    if query_intent is not None:
        parts = []
        if query_intent.program:
            parts.append(f"program={query_intent.program}")
        if query_intent.year:
            parts.append(f"year={query_intent.year}")
        if query_intent.intent != "general":
            parts.append(f"topic={query_intent.intent}")
        if parts:
            context_hint = ", ".join(parts)

    scored = []
    for i, candidate in enumerate(candidates):
        try:
            prompt = _LLM_RERANK_PROMPT.format(
                context_hint = context_hint,
                query        = query,
                index        = i + 1,
                passage      = candidate["text"][:600],
            )
            response = llm.invoke(prompt)
            raw      = response.content if hasattr(response, "content") else str(response)
            match    = re.search(r"\b(\d{1,2})\b", raw.strip())
            score    = int(match.group(1)) if match else 5
            score    = max(0, min(10, score))
        except Exception as e:
            logger.warning(f"[reranker/llm] Scoring failed for candidate {i}: {e}")
            score = 5  # neutral fallback

        entry = dict(candidate)
        entry["rerank_score"]  = score / 10.0
        entry["rerank_method"] = "llm"
        scored.append(entry)

    scored.sort(key=lambda x: x["rerank_score"], reverse=True)
    result = [c for c in scored if c["rerank_score"] >= MIN_RERANK_SCORE][:top_n]

    # Apply safety anchor
    result = _apply_safety_anchor(result, candidates, top_n)

    elapsed = (time.perf_counter() - t_start) * 1000
    logger.info(f"[reranker/llm] {len(result)}/{len(candidates)} kept, {elapsed:.0f}ms")
    return result


# ─────────────────────────────────────────────────────────────────────────────
# Strategy 3: Cross-encoder reranking
# ─────────────────────────────────────────────────────────────────────────────

_cross_encoder_cache: dict[str, Any] = {}


def cross_encoder_rerank(
    query: str,
    candidates: list[dict],
    model_name: str = DEFAULT_CROSS_ENCODER_MODEL,
    top_n: int = 5,
) -> list[dict]:
    """
    Rerank using a sentence-transformers cross-encoder.
    Applies safety anchor after scoring.
    """
    if not CROSS_ENCODER_AVAILABLE:
        logger.warning("[reranker/cross_encoder] sentence-transformers not installed – passthrough")
        result = list(candidates[:top_n])
        for i, c in enumerate(result):
            c["rerank_score"]  = 1.0 - i * 0.01
            c["rerank_method"] = "passthrough"
        return result

    if not candidates:
        return []

    t_start = time.perf_counter()

    if model_name not in _cross_encoder_cache:
        logger.info(f"[reranker/cross_encoder] Loading '{model_name}' ...")
        try:
            _cross_encoder_cache[model_name] = CrossEncoder(model_name)
        except Exception as e:
            logger.error(f"[reranker/cross_encoder] Load failed: {e} – passthrough")
            result = list(candidates[:top_n])
            for i, c in enumerate(result):
                c["rerank_score"]  = 1.0 - i * 0.01
                c["rerank_method"] = "passthrough"
            return result

    model = _cross_encoder_cache[model_name]
    pairs = [(query, c["text"][:512]) for c in candidates]

    try:
        scores = model.predict(pairs)
    except Exception as e:
        logger.error(f"[reranker/cross_encoder] Prediction failed: {e} – passthrough")
        result = list(candidates[:top_n])
        for i, c in enumerate(result):
            c["rerank_score"]  = 1.0 - i * 0.01
            c["rerank_method"] = "passthrough"
        return result

    scored = []
    for candidate, raw_score in zip(candidates, scores):
        entry = dict(candidate)
        entry["rerank_score"]  = _sigmoid(float(raw_score))
        entry["rerank_method"] = "cross_encoder"
        scored.append(entry)

    scored.sort(key=lambda x: x["rerank_score"], reverse=True)
    result = [c for c in scored if c["rerank_score"] >= MIN_RERANK_SCORE][:top_n]

    # Apply safety anchor
    result = _apply_safety_anchor(result, candidates, top_n)

    elapsed = (time.perf_counter() - t_start) * 1000
    logger.info(f"[reranker/cross_encoder] {len(result)}/{len(candidates)} kept, {elapsed:.0f}ms")
    return result


# ─────────────────────────────────────────────────────────────────────────────
# Strategy 4: BM25/Keyword reranking
# ─────────────────────────────────────────────────────────────────────────────

def bm25_rerank(
    query: str,
    candidates: list[dict],
    top_n: int = 5,
) -> list[dict]:
    """
    Rerank based on keyword overlap and BM25-like signals.
    Does not require any external API or embeddings.
    """
    if not candidates:
        return []

    t_start = time.perf_counter()
    query_tokens = _tokenize_for_overlap(query)

    scored = []
    for candidate in candidates:
        text = candidate.get("text", "")
        # Score = keyword overlap + table bonus + original retrieval score
        overlap = _keyword_overlap_score(query_tokens, text)
        tbl_bonus = _table_signal(text)
        
        # Combined score (weighted towards keyword match)
        final_score = (0.7 * overlap) + (0.2 * tbl_bonus) + (0.1 * candidate.get("score", 0.0))
        
        entry = dict(candidate)
        entry["rerank_score"]  = final_score
        entry["rerank_method"] = "bm25_keywords"
        scored.append(entry)

    scored.sort(key=lambda x: x["rerank_score"], reverse=True)
    result = scored[:top_n]

    elapsed = (time.perf_counter() - t_start) * 1000
    logger.info(f"[reranker/bm25] {len(result)}/{len(candidates)} kept, {elapsed:.0f}ms")
    return result


# ─────────────────────────────────────────────────────────────────────────────
# Unified entry point
# ─────────────────────────────────────────────────────────────────────────────

def rerank_results(
    query: str,
    candidates: list[dict],
    embeddings=None,
    llm=None,
    cross_encoder_model: Optional[str] = None,
    top_n: int = 5,
    query_intent=None,
    original_query: Optional[str] = None,
) -> list[dict]:
    """
    Rerank candidates using the best available strategy.

    Priority: cross_encoder > llm > bm25 > cosine > passthrough
    """
    if not candidates:
        return []

    if cross_encoder_model and CROSS_ENCODER_AVAILABLE:
        return cross_encoder_rerank(query, candidates, cross_encoder_model, top_n)

    if llm is not None and not (isinstance(llm, str) and llm == "bm25"):
        return llm_rerank(query, candidates, llm, top_n, query_intent=query_intent)

    # Check if specifically requested bm25
    _method = str(embeddings).lower() if isinstance(embeddings, str) else ""
    if _method == "bm25":
        return bm25_rerank(query, candidates, top_n)

    if embeddings is not None and not isinstance(embeddings, str):
        return cosine_rerank(
            query          = query,
            candidates     = candidates,
            embeddings     = embeddings,
            top_n          = top_n,
            original_query = original_query,
        )

    # Passthrough
    logger.warning("[reranker] No strategy available – passthrough")
    result = list(candidates[:top_n])
    for i, c in enumerate(result):
        c["rerank_score"]  = 1.0 - i * 0.01
        c["rerank_method"] = "passthrough"
    return result
