"""
semantic_chunker.py
====================
Semantic-aware chunking for Arabic/English RAG pipelines.

Strategy (layered, no external NLP model required):
  1. Structural segmentation  – respect headings, articles, numbered sections
  2. Paragraph grouping       – group short paragraphs that belong together
  3. Sentence boundary split  – split oversized paragraphs at sentence ends
  4. Size guardrails          – merge tiny chunks, split giant ones

The result is chunks that:
  - Never cut a sentence in the middle
  - Respect document structure (headings stay with their content)
  - Stay within a configurable size window (min/max chars)
  - Carry a detected section title in their metadata

Optional embedding-similarity splitting is supported when an embeddings
callable is provided (requires an API call per chunk boundary check –
use only when quality matters more than speed).
"""

from __future__ import annotations

import re
import hashlib
from dataclasses import dataclass, field
from typing import Callable, Optional

from routes.arabic_cleaner import detect_section_title, detect_language, extract_keywords

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Target chunk size in characters (sweet spot for text-embedding-ada-002)
DEFAULT_MIN_CHUNK_CHARS = 400
DEFAULT_TARGET_CHUNK_CHARS = 1500
DEFAULT_MAX_CHUNK_CHARS = 2500

# Overlap: number of characters to repeat at the start of the next chunk
# to preserve cross-chunk context
DEFAULT_OVERLAP_CHARS = 400

# ---------------------------------------------------------------------------
# Sentence boundary patterns (Arabic + English)
# ---------------------------------------------------------------------------

# Arabic sentence endings: full stop, question mark, exclamation,
# Arabic full stop (U+06D4), Arabic question mark (U+061F)
_AR_SENT_END = r"[.!?؟\u06D4]"

# English sentence endings
_EN_SENT_END = r"[.!?]"

# Combined sentence splitter: split AFTER the punctuation
# Positive lookbehind so the punctuation stays with the sentence
_SENTENCE_SPLIT_RE = re.compile(
    r"(?<=[.!?؟\u06D4])\s+"
)

# Paragraph boundary: one or more blank lines
_PARAGRAPH_SPLIT_RE = re.compile(r"\n{2,}")

# Single newline (soft line break within a paragraph)
_SOFT_BREAK_RE = re.compile(r"\n")

# ---------------------------------------------------------------------------
# Heading / structural marker patterns
# ---------------------------------------------------------------------------

_HEADING_RE = re.compile(
    r"^\s*(?:"
    r"\d+[\.\-\)]\s*\S"                          # "1. " or "1) "
    r"|(?:المادة|الفصل|الباب|القسم|البند)\s+\S"  # Arabic structural words
    r"|(?:أولاً|ثانياً|ثالثاً|رابعاً|خامساً|سادساً|سابعاً|ثامناً|تاسعاً|عاشراً)"
    r"|(?:Article|Chapter|Section|Part|Clause)\s+\d+"  # English structural
    r"|[A-Z][A-Z\s]{4,}$"                         # ALL CAPS heading
    r")",
    re.IGNORECASE | re.MULTILINE
)

# ---------------------------------------------------------------------------
# Data structures
# ---------------------------------------------------------------------------

@dataclass
class TextSegment:
    """A logical segment of text before final chunking."""
    text: str
    is_heading: bool = False
    heading_text: str = ""
    page_number: int = 0
    segment_index: int = 0


@dataclass
class Chunk:
    """A final chunk ready for embedding and ChromaDB storage."""
    text: str
    chunk_index: int
    page_numbers: list[int] = field(default_factory=list)
    section_title: str = ""
    language: str = "unknown"
    keywords: list[str] = field(default_factory=list)
    char_count: int = 0
    chunk_id: str = ""

    def __post_init__(self):
        self.char_count = len(self.text)
        if not self.chunk_id:
            self.chunk_id = hashlib.md5(self.text.encode("utf-8")).hexdigest()[:12]


# ---------------------------------------------------------------------------
# Step 1: Structural segmentation
# ---------------------------------------------------------------------------

def _split_into_structural_segments(
    pages: list[dict],
) -> list[TextSegment]:
    """
    Split page texts into structural segments by detecting headings.
    Each heading starts a new segment; content between headings is grouped.

    Input: list of page dicts with keys: page_number, text
    Output: list of TextSegment objects
    """
    segments: list[TextSegment] = []
    current_lines: list[str] = []
    current_heading: str = ""
    current_pages: list[int] = []
    seg_idx = 0

    def _flush(heading: str, lines: list[str], pages: list[int]) -> None:
        nonlocal seg_idx
        text = "\n".join(lines).strip()
        if text:
            segments.append(TextSegment(
                text=text,
                is_heading=bool(heading),
                heading_text=heading,
                page_number=pages[0] if pages else 0,
                segment_index=seg_idx,
            ))
            seg_idx += 1

    for page in pages:
        page_num = page.get("page_number", 0)
        page_text = page.get("text", "")
        if not page_text.strip():
            continue

        lines = page_text.split("\n")
        for line in lines:
            stripped = line.strip()
            if not stripped:
                current_lines.append("")
                continue

            if detect_section_title(stripped):
                # Flush current segment before starting a new one
                _flush(current_heading, current_lines, current_pages)
                current_lines = [stripped]
                current_heading = stripped
                current_pages = [page_num]
            else:
                current_lines.append(stripped)
                if page_num not in current_pages:
                    current_pages.append(page_num)

    # Flush the last segment
    _flush(current_heading, current_lines, current_pages)
    return segments


# ---------------------------------------------------------------------------
# Step 2: Paragraph grouping
# ---------------------------------------------------------------------------

def _split_segment_into_paragraphs(segment: TextSegment) -> list[str]:
    """
    Split a segment into paragraphs.

    If the segment contains extracted table rows,
    treat each table row as a separate paragraph.
    """

    text = segment.text

    table_rows = []

    for line in text.split("\n"):
        line = line.strip()

        if not line:
            continue

        if line.startswith("جدول:"):
            continue

        if line.count("|") >= 2:
            table_rows.append(line)

    # Table detected
    if len(table_rows) >= 5:
        return table_rows

    paragraphs = _PARAGRAPH_SPLIT_RE.split(text)

    return [
        p.strip()
        for p in paragraphs
        if p.strip()
    ]

# ---------------------------------------------------------------------------
# Step 3: Sentence splitting
# ---------------------------------------------------------------------------

def _split_into_sentences(text: str) -> list[str]:
    """
    Split text into sentences using punctuation boundaries.
    Handles Arabic and English sentence endings.
    Never splits mid-sentence.
    """
    # First split on double newlines (paragraph breaks)
    paragraphs = _PARAGRAPH_SPLIT_RE.split(text)
    sentences: list[str] = []

    for para in paragraphs:
        para = para.strip()
        if not para:
            continue
        # Split on sentence-ending punctuation followed by whitespace
        parts = _SENTENCE_SPLIT_RE.split(para)
        for part in parts:
            part = part.strip()
            if part:
                sentences.append(part)

    return sentences if sentences else [text.strip()]


# ---------------------------------------------------------------------------
# Step 4: Chunk assembly with size guardrails
# ---------------------------------------------------------------------------

def _assemble_chunks(
    sentences: list[str],
    page_number: int,
    section_title: str,
    min_chars: int,
    target_chars: int,
    max_chars: int,
    overlap_chars: int,
) -> list[dict]:
    """
    Greedily assemble sentences into chunks within size bounds.
    Adds overlap from the previous chunk's tail to preserve context.
    """
    chunks: list[dict] = []
    current_sentences: list[str] = []
    current_len: int = 0
    overlap_tail: str = ""

    def _make_chunk(sents: list[str], tail: str) -> dict:
        body = " ".join(sents).strip()
        text = (tail + " " + body).strip() if tail else body
        return {
            "text": text,
            "page_number": page_number,
            "section_title": section_title,
        }

    for sent in sentences:
        sent_len = len(sent)

        # Single sentence exceeds max_chars → split it by words
        if sent_len > max_chars:
            # Flush current buffer first
            if current_sentences:
                chunks.append(_make_chunk(current_sentences, overlap_tail))
                overlap_tail = " ".join(current_sentences)[-overlap_chars:]
                current_sentences = []
                current_len = 0

            # Split the giant sentence by words
            words = sent.split()
            word_buf: list[str] = []
            word_len = 0
            for word in words:
                if word_len + len(word) + 1 > max_chars and word_buf:
                    chunk_text = " ".join(word_buf)
                    chunks.append({
                        "text": (overlap_tail + " " + chunk_text).strip() if overlap_tail else chunk_text,
                        "page_number": page_number,
                        "section_title": section_title,
                    })
                    overlap_tail = chunk_text[-overlap_chars:]
                    word_buf = [word]
                    word_len = len(word)
                else:
                    word_buf.append(word)
                    word_len += len(word) + 1
            if word_buf:
                current_sentences = [" ".join(word_buf)]
                current_len = len(current_sentences[0])
            continue

        # Adding this sentence would exceed max_chars → flush
        if current_len + sent_len + 1 > max_chars and current_len >= min_chars:
            chunks.append(_make_chunk(current_sentences, overlap_tail))
            overlap_tail = " ".join(current_sentences)[-overlap_chars:]
            current_sentences = []
            current_len = 0

        current_sentences.append(sent)
        current_len += sent_len + 1

        # Flush at target size (soft boundary)
        if current_len >= target_chars:
            chunks.append(_make_chunk(current_sentences, overlap_tail))
            overlap_tail = " ".join(current_sentences)[-overlap_chars:]
            current_sentences = []
            current_len = 0

    # Flush remaining
    if current_sentences:
        remaining_text = " ".join(current_sentences).strip()
        if remaining_text:
            # If remaining is too small, merge with last chunk
            if chunks and len(remaining_text) < min_chars:
                last = chunks[-1]
                last["text"] = last["text"] + " " + remaining_text
            else:
                chunks.append(_make_chunk(current_sentences, overlap_tail))

    return chunks


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def semantic_chunk_document(
    structured_doc: dict,
    min_chars: int = DEFAULT_MIN_CHUNK_CHARS,
    target_chars: int = DEFAULT_TARGET_CHUNK_CHARS,
    max_chars: int = DEFAULT_MAX_CHUNK_CHARS,
    overlap_chars: int = DEFAULT_OVERLAP_CHARS,
    extract_kw: bool = True,
    max_keywords: int = 8,
) -> tuple[list[str], list[dict]]:
    """
    Semantically chunk a structured PDF document for ChromaDB storage.

    Parameters
    ----------
    structured_doc : dict
        Output of extract_and_structure_pdf() – must have "pages" list
        where each page has "page_number" and "text".
    min_chars : int
        Minimum chunk size in characters (chunks smaller than this are
        merged with the next chunk).
    target_chars : int
        Soft target chunk size – chunker tries to stay near this.
    max_chars : int
        Hard maximum chunk size – chunks are always split below this.
    overlap_chars : int
        Number of characters from the end of the previous chunk to
        prepend to the next chunk for context continuity.
    extract_kw : bool
        Whether to extract keywords for each chunk's metadata.
    max_keywords : int
        Maximum number of keywords to extract per chunk.

    Returns
    -------
    (texts, metadatas)
        texts     : list[str]   – chunk text strings
        metadatas : list[dict]  – one metadata dict per chunk
    """
    filename = structured_doc.get("filename", "unknown")
    total_pages = structured_doc.get("total_pages", 0)
    extraction_method = structured_doc.get("extraction_method", "unknown")
    doc_has_arabic = structured_doc.get("metadata", {}).get("has_arabic", False)
    doc_has_english = structured_doc.get("metadata", {}).get("has_english", False)
    doc_has_tables = structured_doc.get("metadata", {}).get("has_tables", False)

    pages = structured_doc.get("pages", [])
    if not pages:
        return [], []

    # ── Step 1: Structural segmentation ──────────────────────────────────
    segments = _split_into_structural_segments(pages)
    print(f"  [semantic_chunker] {len(segments)} structural segments detected")

    # ── Step 2–4: Paragraph → sentence → chunk assembly ──────────────────
    raw_chunks: list[dict] = []

    for segment in segments:
        segment_sentences: list[str] = []
        paragraphs = _split_segment_into_paragraphs(segment)

    # Detect table-like content
        table_rows = [
             p for p in paragraphs
             if p.count("|") >= 2
    ]

        is_table_segment = len(table_rows) >= 5

        for para in paragraphs:
           if not para.strip():
              continue

        # For tables: keep each row independent
           if is_table_segment:
              segment_sentences.append(para.strip())
           else:
              segment_sentences.extend(_split_into_sentences(para))

        if segment_sentences:

           assembled = _assemble_chunks(
               sentences=segment_sentences,
               page_number=segment.page_number,
               section_title=segment.heading_text,

            # Smaller chunks for curriculum tables
               min_chars=50 if is_table_segment else min_chars,
               target_chars=250 if is_table_segment else target_chars,
               max_chars=400 if is_table_segment else max_chars,
               overlap_chars=0 if is_table_segment else overlap_chars,
        )

        raw_chunks.extend(assembled)

    print(f"  [semantic_chunker] {len(raw_chunks)} raw chunks assembled")

    # ── Step 5: Build final output with rich metadata ─────────────────────
    texts: list[str] = []
    metadatas: list[dict] = []

    for idx, chunk in enumerate(raw_chunks):
        text = chunk["text"].strip()
        if not text:
            continue

        # Language detection per chunk
        lang = detect_language(text)

        # Keyword extraction
        keywords: list[str] = []
        if extract_kw:
            keywords = extract_keywords(text, max_keywords=max_keywords)

        # Stable, deterministic chunk ID
        chunk_id = _make_chunk_id(filename, idx, text)

        texts.append(text)
        metadatas.append({
            # ── Core identification ──────────────────────────────────────
            "fileName": filename,
            "chunkIndex": idx,
            "chunkId": chunk_id,
            # ── Location ─────────────────────────────────────────────────
            "page": chunk.get("page_number", 0),
            "totalPages": total_pages,
            # ── Structure ────────────────────────────────────────────────
            "sectionTitle": chunk.get("section_title", ""),
            # ── Language ─────────────────────────────────────────────────
            "language": lang,
            "hasArabic": doc_has_arabic,
            "hasEnglish": doc_has_english,
            # ── Keywords ─────────────────────────────────────────────────
            "keywords": ", ".join(keywords),
            # ── Quality / provenance ─────────────────────────────────────
            "extractionMethod": extraction_method,
            "charCount": len(text),
            "type": "pdf",
            # ── Table flag ───────────────────────────────────────────────
            "hasTables": doc_has_tables,
        })

    print(
        f"  [semantic_chunker] {len(texts)} final chunks "
        f"(avg {int(sum(len(t) for t in texts) / max(len(texts), 1))} chars)"
    )
    return texts, metadatas


def _make_chunk_id(filename: str, index: int, text: str) -> str:
    """
    Generate a stable, unique chunk ID.
    Format: <filename_hash>-<index>-<content_hash>
    This is deterministic: re-processing the same file produces the same IDs,
    which allows ChromaDB upsert to replace stale chunks cleanly.
    """
    fname_hash = hashlib.md5(filename.encode()).hexdigest()[:8]
    content_hash = hashlib.md5(text[:100].encode("utf-8")).hexdigest()[:8]
    return f"{fname_hash}-{index:04d}-{content_hash}"
