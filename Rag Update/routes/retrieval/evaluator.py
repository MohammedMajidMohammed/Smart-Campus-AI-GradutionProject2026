"""
evaluator.py
=============
Retrieval quality evaluation utilities for the RAG pipeline.

Metrics implemented
-------------------
  - Precision@k   : fraction of top-k results that are relevant
  - Recall@k      : fraction of relevant docs found in top-k
  - MRR           : Mean Reciprocal Rank
  - NDCG@k        : Normalized Discounted Cumulative Gain
  - Hit Rate@k    : whether at least one relevant doc is in top-k

Usage
-----
    from routes.retrieval.evaluator import evaluate_retrieval, log_retrieval_result

    # Offline evaluation with ground-truth labels
    metrics = evaluate_retrieval(
        retrieved_ids=["doc-1", "doc-3", "doc-7"],
        relevant_ids={"doc-1", "doc-5"},
        k=3,
    )
    # → {"precision@3": 0.33, "recall@3": 0.5, "mrr": 1.0, ...}

    # Online logging (no ground truth needed)
    log_retrieval_result(query="...", results=[...], query_language="arabic")
"""

from __future__ import annotations

import json
import logging
import math
import time
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Log file for online retrieval traces
# ---------------------------------------------------------------------------
RETRIEVAL_LOG_PATH = Path("./retrieval_logs/retrieval_trace.jsonl")
RETRIEVAL_LOG_PATH.parent.mkdir(exist_ok=True)


# ---------------------------------------------------------------------------
# Offline evaluation metrics
# ---------------------------------------------------------------------------

def precision_at_k(retrieved_ids: list[str], relevant_ids: set[str], k: int) -> float:
    """Fraction of top-k retrieved documents that are relevant."""
    top_k = retrieved_ids[:k]
    if not top_k:
        return 0.0
    hits = sum(1 for doc_id in top_k if doc_id in relevant_ids)
    return hits / len(top_k)


def recall_at_k(retrieved_ids: list[str], relevant_ids: set[str], k: int) -> float:
    """Fraction of relevant documents found in top-k retrieved."""
    if not relevant_ids:
        return 0.0
    top_k = retrieved_ids[:k]
    hits = sum(1 for doc_id in top_k if doc_id in relevant_ids)
    return hits / len(relevant_ids)


def mean_reciprocal_rank(retrieved_ids: list[str], relevant_ids: set[str]) -> float:
    """
    Reciprocal rank of the first relevant document.
    Returns 0 if no relevant document is found.
    """
    for rank, doc_id in enumerate(retrieved_ids, start=1):
        if doc_id in relevant_ids:
            return 1.0 / rank
    return 0.0


def ndcg_at_k(
    retrieved_ids: list[str],
    relevant_ids: set[str],
    k: int,
    relevance_scores: Optional[dict[str, float]] = None,
) -> float:
    """
    Normalized Discounted Cumulative Gain at k.

    Parameters
    ----------
    retrieved_ids : list[str]
        Ordered list of retrieved document IDs.
    relevant_ids : set[str]
        Set of relevant document IDs.
    k : int
        Cutoff rank.
    relevance_scores : dict[str, float], optional
        Graded relevance scores (default: binary 0/1).
    """
    def _rel(doc_id: str) -> float:
        if relevance_scores:
            return relevance_scores.get(doc_id, 0.0)
        return 1.0 if doc_id in relevant_ids else 0.0

    top_k = retrieved_ids[:k]

    # DCG
    dcg = sum(
        _rel(doc_id) / math.log2(rank + 1)
        for rank, doc_id in enumerate(top_k, start=1)
    )

    # Ideal DCG (best possible ordering)
    ideal_rels = sorted(
        [_rel(doc_id) for doc_id in relevant_ids],
        reverse=True
    )[:k]
    idcg = sum(
        rel / math.log2(rank + 1)
        for rank, rel in enumerate(ideal_rels, start=1)
    )

    return dcg / idcg if idcg > 0 else 0.0


def hit_rate_at_k(retrieved_ids: list[str], relevant_ids: set[str], k: int) -> float:
    """1.0 if at least one relevant document is in top-k, else 0.0."""
    top_k = set(retrieved_ids[:k])
    return 1.0 if top_k & relevant_ids else 0.0


def evaluate_retrieval(
    retrieved_ids: list[str],
    relevant_ids: set[str],
    k: int = 5,
    relevance_scores: Optional[dict[str, float]] = None,
) -> dict:
    """
    Compute all retrieval metrics for a single query.

    Parameters
    ----------
    retrieved_ids : list[str]
        Ordered list of retrieved document IDs (best first).
    relevant_ids : set[str]
        Ground-truth set of relevant document IDs.
    k : int
        Evaluation cutoff.
    relevance_scores : dict[str, float], optional
        Graded relevance for NDCG (default: binary).

    Returns
    -------
    dict with keys: precision@k, recall@k, mrr, ndcg@k, hit_rate@k
    """
    return {
        f"precision@{k}": round(precision_at_k(retrieved_ids, relevant_ids, k), 4),
        f"recall@{k}":    round(recall_at_k(retrieved_ids, relevant_ids, k), 4),
        "mrr":            round(mean_reciprocal_rank(retrieved_ids, relevant_ids), 4),
        f"ndcg@{k}":      round(ndcg_at_k(retrieved_ids, relevant_ids, k, relevance_scores), 4),
        f"hit_rate@{k}":  round(hit_rate_at_k(retrieved_ids, relevant_ids, k), 4),
    }


def evaluate_batch(
    queries: list[dict],
    k: int = 5,
) -> dict:
    """
    Evaluate retrieval over a batch of queries.

    Parameters
    ----------
    queries : list[dict]
        Each dict must have:
          - "retrieved_ids": list[str]
          - "relevant_ids":  set[str] or list[str]
          - "query":         str (optional, for logging)
    k : int
        Evaluation cutoff.

    Returns
    -------
    dict with averaged metrics and per-query breakdown.
    """
    per_query = []
    for q in queries:
        retrieved = q.get("retrieved_ids", [])
        relevant  = set(q.get("relevant_ids", []))
        metrics   = evaluate_retrieval(retrieved, relevant, k)
        metrics["query"] = q.get("query", "")
        per_query.append(metrics)

    if not per_query:
        return {}

    # Average across queries
    metric_keys = [f"precision@{k}", f"recall@{k}", "mrr", f"ndcg@{k}", f"hit_rate@{k}"]
    averaged = {
        key: round(sum(q[key] for q in per_query) / len(per_query), 4)
        for key in metric_keys
    }
    averaged["num_queries"] = len(per_query)
    averaged["per_query"]   = per_query

    return averaged


# ---------------------------------------------------------------------------
# Online retrieval logging (no ground truth needed)
# ---------------------------------------------------------------------------

def log_retrieval_result(
    query: str,
    results: list[dict],
    query_language: str = "unknown",
    retrieval_stats: Optional[dict] = None,
    session_id: Optional[str] = None,
) -> None:
    """
    Append a retrieval trace to the JSONL log file.
    Useful for offline analysis and future evaluation dataset creation.

    Parameters
    ----------
    query : str
        The user query.
    results : list[dict]
        Final reranked results (each with "id", "metadata", "rerank_score").
    query_language : str
        Detected language of the query.
    retrieval_stats : dict, optional
        Timing and count stats from hybrid_search.
    session_id : str, optional
        Optional session identifier for grouping queries.
    """
    record = {
        "timestamp":       time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "session_id":      session_id,
        "query":           query,
        "query_language":  query_language,
        "num_results":     len(results),
        "retrieval_stats": retrieval_stats or {},
        "results_summary": [
            {
                "id":            r.get("id", ""),
                "fileName":      r.get("metadata", {}).get("fileName", ""),
                "page":          r.get("metadata", {}).get("page", ""),
                "sectionTitle":  r.get("metadata", {}).get("sectionTitle", ""),
                "language":      r.get("metadata", {}).get("language", ""),
                "rerank_score":  round(r.get("rerank_score", 0.0), 4),
                "rerank_method": r.get("rerank_method", ""),
                "rrf_score":     round(r.get("rrf_score", 0.0), 4),
                "snippet":       r.get("text", "")[:150],
            }
            for r in results
        ],
    }

    try:
        with open(RETRIEVAL_LOG_PATH, "a", encoding="utf-8") as f:
            f.write(json.dumps(record, ensure_ascii=False) + "\n")
    except Exception as e:
        logger.warning(f"[evaluator] Failed to write retrieval log: {e}")
