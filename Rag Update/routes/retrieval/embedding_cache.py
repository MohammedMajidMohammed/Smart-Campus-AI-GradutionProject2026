"""
embedding_cache.py
===================
Thread-safe in-memory LRU cache for query embeddings.

Avoids redundant API calls when the same (or very similar) query is
asked multiple times within a session.

Features
--------
  - LRU eviction (configurable max size)
  - TTL expiry (configurable max age in seconds)
  - Thread-safe via threading.Lock
  - Cache-hit / miss logging
  - Optional disk persistence (pickle) for cross-restart caching

Usage
-----
    from routes.retrieval.embedding_cache import EmbeddingCache

    cache = EmbeddingCache(max_size=512, ttl_seconds=3600)

    # Wrap your embeddings object
    embedding = cache.get(query)
    if embedding is None:
        embedding = embeddings_client.embed_query(query)
        cache.set(query, embedding)
"""

from __future__ import annotations

import hashlib
import logging
import pickle
import threading
import time
from collections import OrderedDict
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
DEFAULT_MAX_SIZE    = 512          # max number of cached embeddings
DEFAULT_TTL_SECONDS = 3600        # 1 hour
CACHE_DIR           = Path("./embedding_cache")


# ---------------------------------------------------------------------------
# Cache entry
# ---------------------------------------------------------------------------

class _CacheEntry:
    __slots__ = ("embedding", "created_at")

    def __init__(self, embedding: list[float]) -> None:
        self.embedding  = embedding
        self.created_at = time.monotonic()


# ---------------------------------------------------------------------------
# EmbeddingCache
# ---------------------------------------------------------------------------

class EmbeddingCache:
    """
    LRU cache for query embeddings with TTL expiry.

    Parameters
    ----------
    max_size : int
        Maximum number of entries before LRU eviction.
    ttl_seconds : float
        Maximum age of a cache entry in seconds.
    persist_path : Path, optional
        If provided, the cache is saved to / loaded from this file.
    """

    def __init__(
        self,
        max_size: int = DEFAULT_MAX_SIZE,
        ttl_seconds: float = DEFAULT_TTL_SECONDS,
        persist_path: Optional[Path] = None,
    ) -> None:
        self._max_size    = max_size
        self._ttl         = ttl_seconds
        self._cache: OrderedDict[str, _CacheEntry] = OrderedDict()
        self._lock        = threading.Lock()
        self._hits        = 0
        self._misses      = 0
        self._persist_path = persist_path

        if persist_path and persist_path.exists():
            self._load(persist_path)

    # ── Public API ─────────────────────────────────────────────────────────

    def get(self, text: str) -> Optional[list[float]]:
        """Return cached embedding or None if not found / expired."""
        key = self._key(text)
        with self._lock:
            entry = self._cache.get(key)
            if entry is None:
                self._misses += 1
                return None
            # Check TTL
            if time.monotonic() - entry.created_at > self._ttl:
                del self._cache[key]
                self._misses += 1
                return None
            # Move to end (most recently used)
            self._cache.move_to_end(key)
            self._hits += 1
            return entry.embedding

    def set(self, text: str, embedding: list[float]) -> None:
        """Store an embedding in the cache."""
        key = self._key(text)
        with self._lock:
            if key in self._cache:
                self._cache.move_to_end(key)
            self._cache[key] = _CacheEntry(embedding)
            # Evict oldest entry if over capacity
            while len(self._cache) > self._max_size:
                self._cache.popitem(last=False)

    def embed_query_cached(self, text: str, embeddings_client) -> list[float]:
        """
        Convenience wrapper: return cached embedding or compute and cache it.

        Parameters
        ----------
        text : str
            Query text to embed.
        embeddings_client : OpenAIEmbeddings
            Embeddings client with .embed_query() method.
        """
        cached = self.get(text)
        if cached is not None:
            logger.debug(f"[cache] HIT  (hits={self._hits}, misses={self._misses})")
            return cached

        logger.debug(f"[cache] MISS (hits={self._hits}, misses={self._misses})")
        embedding = embeddings_client.embed_query(text)
        self.set(text, embedding)
        return embedding

    def invalidate(self, text: str) -> None:
        """Remove a specific entry from the cache."""
        key = self._key(text)
        with self._lock:
            self._cache.pop(key, None)

    def clear(self) -> None:
        """Clear all cache entries."""
        with self._lock:
            self._cache.clear()
            self._hits   = 0
            self._misses = 0

    def save(self, path: Optional[Path] = None) -> None:
        """Persist the cache to disk."""
        target = path or self._persist_path
        if target is None:
            return
        target.parent.mkdir(parents=True, exist_ok=True)
        with self._lock:
            data = {
                "cache": dict(self._cache),
                "hits":  self._hits,
                "misses": self._misses,
            }
        try:
            with open(target, "wb") as f:
                pickle.dump(data, f)
            logger.debug(f"[cache] Saved {len(data['cache'])} entries to {target}")
        except Exception as e:
            logger.warning(f"[cache] Failed to save: {e}")

    # ── Properties ─────────────────────────────────────────────────────────

    @property
    def stats(self) -> dict:
        with self._lock:
            total = self._hits + self._misses
            return {
                "size":      len(self._cache),
                "max_size":  self._max_size,
                "hits":      self._hits,
                "misses":    self._misses,
                "hit_rate":  round(self._hits / total, 3) if total else 0.0,
                "ttl_s":     self._ttl,
            }

    # ── Private helpers ────────────────────────────────────────────────────

    @staticmethod
    def _key(text: str) -> str:
        """Deterministic cache key from text content."""
        return hashlib.sha256(text.encode("utf-8")).hexdigest()

    def _load(self, path: Path) -> None:
        try:
            with open(path, "rb") as f:
                data = pickle.load(f)
            now = time.monotonic()
            loaded = 0
            for key, entry in data.get("cache", {}).items():
                # Skip expired entries
                if now - entry.created_at <= self._ttl:
                    self._cache[key] = entry
                    loaded += 1
            self._hits   = data.get("hits", 0)
            self._misses = data.get("misses", 0)
            logger.info(f"[cache] Loaded {loaded} valid entries from {path}")
        except Exception as e:
            logger.warning(f"[cache] Failed to load from {path}: {e}")


# ---------------------------------------------------------------------------
# Module-level singleton
# ---------------------------------------------------------------------------

CACHE_DIR.mkdir(exist_ok=True)

_default_cache = EmbeddingCache(
    max_size=DEFAULT_MAX_SIZE,
    ttl_seconds=DEFAULT_TTL_SECONDS,
    persist_path=CACHE_DIR / "query_embeddings.pkl",
)


def get_default_cache() -> EmbeddingCache:
    """Return the module-level singleton cache."""
    return _default_cache
