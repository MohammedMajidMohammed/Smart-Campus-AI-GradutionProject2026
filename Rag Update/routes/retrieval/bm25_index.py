"""
bm25_index.py
==============
BM25 sparse-retrieval index for Arabic/English RAG pipelines.

Wraps rank_bm25.BM25Okapi with:
  - Arabic-aware tokenization (normalizes chars before tokenizing)
  - Persistent serialization (pickle) so the index survives server restarts
  - Thread-safe in-memory singleton per collection name
  - Graceful fallback to TF-IDF when rank_bm25 is not installed

Install:
    pip install rank-bm25
"""

from __future__ import annotations

import logging
import math
import os
import pickle
import re
import threading
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Optional imports
# ---------------------------------------------------------------------------
try:
    from rank_bm25 import BM25Okapi
    BM25_AVAILABLE = True
except ImportError:
    BM25_AVAILABLE = False
    logger.warning("rank_bm25 not installed – BM25 will fall back to TF-IDF. "
                   "Install with: pip install rank-bm25")

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
BM25_INDEX_DIR = Path("./bm25_indexes")
BM25_INDEX_DIR.mkdir(exist_ok=True)

# ---------------------------------------------------------------------------
# Tokenizer (Arabic + English aware)
# ---------------------------------------------------------------------------

# Arabic character normalization table (same as arabic_cleaner but inline
# so this module has no circular import)
_AR_NORM = str.maketrans({
    "\u0622": "\u0627",  # آ → ا
    "\u0623": "\u0627",  # أ → ا
    "\u0625": "\u0627",  # إ → ا
    "\u0671": "\u0627",  # ٱ → ا
    "\u0649": "\u064A",  # ى → ي
    "\u0624": "\u0648",  # ؤ → و
    "\u0626": "\u064A",  # ئ → ي
})

# Diacritics pattern
_DIACRITICS = re.compile(r"[\u064B-\u065F\u0610-\u061A\u06D6-\u06ED]")
_TATWEEL    = re.compile(r"\u0640+")

# Arabic stopwords (minimal set for BM25 – keep more than for embeddings)
_AR_STOP = {
    "في", "من", "إلى", "على", "عن", "مع", "هذا", "هذه", "ذلك", "تلك",
    "التي", "الذي", "الذين", "كان", "كانت", "هو", "هي", "هم", "هن",
    "أو", "و", "ثم", "لكن", "لأن", "حتى", "إذا", "قد", "لقد", "لم",
    "لن", "ما", "لا", "إن", "أن", "كل", "بعض", "أي", "كما", "مما",
    "عند", "بين", "خلال", "حول", "بعد", "قبل", "منذ", "حيث",
}

_EN_STOP = {
    "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
    "of", "with", "by", "from", "is", "are", "was", "were", "be", "been",
    "have", "has", "had", "do", "does", "did", "will", "would", "could",
    "should", "this", "that", "these", "those", "it", "its", "they",
    "them", "their", "we", "our", "you", "your", "he", "she", "his", "her",
}


def tokenize(text: str) -> list[str]:
    """
    Tokenize Arabic/English text for BM25.
    Steps:
      1. Normalize Arabic characters
      2. Remove diacritics and tatweel
      3. Lowercase
      4. Extract Arabic words (≥2 chars) and English words (≥2 chars)
      5. Remove stopwords
    """
    # Normalize
    text = text.translate(_AR_NORM)
    text = _DIACRITICS.sub("", text)
    text = _TATWEEL.sub("", text)
    text = text.lower()

    # Extract tokens
    tokens = re.findall(r"[\u0600-\u06FF]{2,}|[a-z]{2,}", text)

    # Remove stopwords
    return [t for t in tokens if t not in _AR_STOP and t not in _EN_STOP]


# ---------------------------------------------------------------------------
# BM25Index class
# ---------------------------------------------------------------------------

class BM25Index:
    """
    Thread-safe BM25 index over a list of text documents.

    Attributes
    ----------
    corpus_ids : list[str]
        ChromaDB document IDs in the same order as the corpus.
    corpus_texts : list[str]
        Raw text of each document (for snippet display).
    """

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._bm25: Optional[BM25Okapi] = None
        self._tfidf = None          # sklearn fallback
        self._tfidf_matrix = None
        self.corpus_ids: list[str] = []
        self.corpus_texts: list[str] = []
        self.corpus_metadatas: list[dict] = []
        self._tokenized_corpus: list[list[str]] = []
        self._built = False

    # ── Build ──────────────────────────────────────────────────────────────

    def build(
        self,
        texts: list[str],
        ids: list[str],
        metadatas: list[dict],
    ) -> None:
        """
        Build the BM25 index from a list of texts.

        Parameters
        ----------
        texts : list[str]
            Document texts (same order as ids).
        ids : list[str]
            ChromaDB document IDs.
        metadatas : list[dict]
            Metadata dicts (same order as texts).
        """
        with self._lock:
            logger.info(f"[BM25] Building index over {len(texts)} documents ...")
            self.corpus_texts = texts
            self.corpus_ids = ids
            self.corpus_metadatas = metadatas
            self._tokenized_corpus = [tokenize(t) for t in texts]

            if BM25_AVAILABLE:
                self._bm25 = BM25Okapi(self._tokenized_corpus)
                logger.info("[BM25] BM25Okapi index built successfully")
            else:
                self._build_tfidf_fallback(texts)

            self._built = True

    def _build_tfidf_fallback(self, texts: list[str]) -> None:
        """Build a TF-IDF index as fallback when rank_bm25 is unavailable."""
        try:
            from sklearn.feature_extraction.text import TfidfVectorizer
            self._tfidf = TfidfVectorizer(
                analyzer="word",
                tokenizer=lambda t: tokenize(t),
                lowercase=False,
                min_df=1,
            )
            self._tfidf_matrix = self._tfidf.fit_transform(texts)
            logger.info("[BM25] TF-IDF fallback index built successfully")
        except ImportError:
            logger.warning("[BM25] Neither rank_bm25 nor scikit-learn available. "
                           "Keyword search will be disabled.")

    # ── Query ──────────────────────────────────────────────────────────────

    def query(self, query_text: str, top_k: int = 20) -> list[dict]:
        """
        Search the index and return top_k results.

        Returns
        -------
        list[dict] with keys: id, text, metadata, score, rank
        """
        if not self._built:
            logger.warning("[BM25] Index not built yet – returning empty results")
            return []

        with self._lock:
            query_tokens = tokenize(query_text)
            if not query_tokens:
                return []

            if BM25_AVAILABLE and self._bm25 is not None:
                scores = self._bm25.get_scores(query_tokens)
            elif self._tfidf is not None:
                scores = self._tfidf_query(query_tokens)
            else:
                return []

        # Build ranked results
        indexed = sorted(enumerate(scores), key=lambda x: x[1], reverse=True)
        results = []
        for rank, (idx, score) in enumerate(indexed[:top_k]):
            if score <= 0:
                break
            results.append({
                "id":       self.corpus_ids[idx],
                "text":     self.corpus_texts[idx],
                "metadata": self.corpus_metadatas[idx],
                "score":    float(score),
                "rank":     rank + 1,
            })
        return results

    def _tfidf_query(self, tokens: list[str]) -> list[float]:
        """TF-IDF cosine similarity scores."""
        import numpy as np
        from sklearn.metrics.pairwise import cosine_similarity

        query_str = " ".join(tokens)
        q_vec = self._tfidf.transform([query_str])
        sims = cosine_similarity(q_vec, self._tfidf_matrix).flatten()
        return sims.tolist()

    # ── Persistence ────────────────────────────────────────────────────────

    def save(self, name: str) -> Path:
        """Serialize the index to disk."""
        path = BM25_INDEX_DIR / f"{name}.pkl"
        with self._lock:
            with open(path, "wb") as f:
                pickle.dump({
                    "corpus_ids":        self.corpus_ids,
                    "corpus_texts":      self.corpus_texts,
                    "corpus_metadatas":  self.corpus_metadatas,
                    "tokenized_corpus":  self._tokenized_corpus,
                    "bm25":              self._bm25,
                    "tfidf":             self._tfidf,
                    "tfidf_matrix":      self._tfidf_matrix,
                }, f)
        logger.info(f"[BM25] Index saved to {path}")
        return path

    @classmethod
    def load(cls, name: str) -> Optional["BM25Index"]:
        """Load a previously saved index from disk."""
        path = BM25_INDEX_DIR / f"{name}.pkl"
        if not path.exists():
            return None
        try:
            with open(path, "rb") as f:
                data = pickle.load(f)
            idx = cls()
            idx.corpus_ids       = data["corpus_ids"]
            idx.corpus_texts     = data["corpus_texts"]
            idx.corpus_metadatas = data["corpus_metadatas"]
            idx._tokenized_corpus = data["tokenized_corpus"]
            idx._bm25            = data.get("bm25")
            idx._tfidf           = data.get("tfidf")
            idx._tfidf_matrix    = data.get("tfidf_matrix")
            idx._built           = True
            logger.info(f"[BM25] Index loaded from {path} "
                        f"({len(idx.corpus_ids)} documents)")
            return idx
        except Exception as e:
            logger.error(f"[BM25] Failed to load index from {path}: {e}")
            return None

    # ── Properties ─────────────────────────────────────────────────────────

    @property
    def is_built(self) -> bool:
        return self._built

    @property
    def doc_count(self) -> int:
        return len(self.corpus_ids)


# ---------------------------------------------------------------------------
# Module-level singleton registry (one index per collection name)
# ---------------------------------------------------------------------------

_registry: dict[str, BM25Index] = {}
_registry_lock = threading.Lock()


def get_or_build_index(
    collection_name: str,
    collection=None,          # chromadb Collection object
    force_rebuild: bool = False,
) -> BM25Index:
    """
    Return the BM25Index for a collection, building/loading it if needed.

    Parameters
    ----------
    collection_name : str
        ChromaDB collection name (used as the index file name).
    collection : chromadb.Collection, optional
        If provided and the index is not cached, fetch all documents
        from ChromaDB and build the index.
    force_rebuild : bool
        If True, always rebuild from ChromaDB even if a cached index exists.
    """
    with _registry_lock:
        if not force_rebuild and collection_name in _registry:
            return _registry[collection_name]

        # Try loading from disk first
        if not force_rebuild:
            idx = BM25Index.load(collection_name)
            if idx is not None:
                _registry[collection_name] = idx
                return idx

        # Build from ChromaDB
        if collection is None:
            logger.warning(f"[BM25] No collection provided for '{collection_name}' "
                           "– returning empty index")
            idx = BM25Index()
            _registry[collection_name] = idx
            return idx

        logger.info(f"[BM25] Building index from ChromaDB collection '{collection_name}' ...")
        try:
            all_data = collection.get(include=["documents", "metadatas"])
            texts     = all_data.get("documents") or []
            ids       = all_data.get("ids") or []
            metadatas = all_data.get("metadatas") or []

            # Filter out None/empty documents
            valid = [
                (t, i, m) for t, i, m in zip(texts, ids, metadatas)
                if t and t.strip()
            ]
            if valid:
                texts, ids, metadatas = zip(*valid)
                texts     = list(texts)
                ids       = list(ids)
                metadatas = list(metadatas)
            else:
                texts = ids = metadatas = []

            idx = BM25Index()
            if texts:
                idx.build(texts, ids, metadatas)
                idx.save(collection_name)
            _registry[collection_name] = idx
            return idx

        except Exception as e:
            logger.error(f"[BM25] Failed to build index: {e}")
            idx = BM25Index()
            _registry[collection_name] = idx
            return idx


def invalidate_index(collection_name: str) -> None:
    """Remove a cached index (call after new documents are added)."""
    with _registry_lock:
        _registry.pop(collection_name, None)
        path = BM25_INDEX_DIR / f"{collection_name}.pkl"
        if path.exists():
            path.unlink()
    logger.info(f"[BM25] Index invalidated for '{collection_name}'")
