"""
pdf_processor.py
=================
PDF extraction pipeline with OCR support + table extraction.

Three-pass extraction strategy:
  Pass 1 – Native text via PyMuPDF (fitz.page.get_text)
  Pass 2 – Table extraction via pdfplumber (converts tables to readable text)
            Tables are converted to "key: value" rows so the RAG can answer
            questions like "what courses are in year 1?"
  Pass 3 – Tesseract OCR on page images rendered by PyMuPDF
            (triggered automatically for sparse/image-heavy pages)

Text cleaning is delegated to arabic_cleaner.py.
Chunking is delegated to semantic_chunker.py.

System requirements
-------------------
  Tesseract OCR must be installed on the host OS:
    Windows : https://github.com/UB-Mannheim/tesseract/wiki
              (tick Arabic language data during install)
    Linux   : sudo apt-get install tesseract-ocr tesseract-ocr-ara
    macOS   : brew install tesseract tesseract-lang

Python packages (see requirements.txt):
    pymupdf pytesseract Pillow pdfplumber
"""

from __future__ import annotations

import io
import re
import unicodedata

from routes.arabic_cleaner import clean_arabic_text, detect_language

# ---------------------------------------------------------------------------
# Optional imports – graceful degradation
# ---------------------------------------------------------------------------
try:
    import fitz  # PyMuPDF
    PYMUPDF_AVAILABLE = True
except ImportError:
    PYMUPDF_AVAILABLE = False
    print("WARNING: PyMuPDF (fitz) not installed. Run: pip install pymupdf")

try:
    import pytesseract
    from PIL import Image
    TESSERACT_AVAILABLE = True
    # Windows: set Tesseract path if not on system PATH
    import os as _os
    _tesseract_paths = [
        r"C:\Program Files\Tesseract-OCR\tesseract.exe",
        r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe",
        r"C:\Users\Right Click\AppData\Local\Programs\Tesseract-OCR\tesseract.exe",
    ]
    for _tp in _tesseract_paths:
        if _os.path.exists(_tp):
            pytesseract.pytesseract.tesseract_cmd = _tp
            print(f"[pdf_processor] Tesseract found at: {_tp}")
            break
except ImportError:
    TESSERACT_AVAILABLE = False
    print("WARNING: pytesseract/Pillow not installed. OCR will be skipped.")

try:
    import pypdf
    PYPDF_AVAILABLE = True
except ImportError:
    PYPDF_AVAILABLE = False

try:
    import pdfplumber
    PDFPLUMBER_AVAILABLE = True
except ImportError:
    PDFPLUMBER_AVAILABLE = False
    print("WARNING: pdfplumber not installed. Table extraction will be skipped.")
    print("         Run: pip install pdfplumber>=0.10.3")

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# Pages with fewer native characters than this trigger OCR
NATIVE_TEXT_THRESHOLD = 200

# Tesseract: Arabic + English, LSTM engine, auto page segmentation
TESSERACT_LANG   = "ara+eng"
TESSERACT_CONFIG = "--oem 3 --psm 3"

# DPI for page-to-image rendering (300 is the OCR sweet spot)
OCR_DPI = 300


# ---------------------------------------------------------------------------
# Table extraction helpers
# ---------------------------------------------------------------------------

def _table_to_text(table: list[list]) -> str:
    """
    Convert a pdfplumber table (list of rows, each row is a list of cells)
    into readable Arabic-friendly text optimised for course/curriculum tables.

    Strategy:
      1. Clean and de-duplicate merged cells (pdfplumber repeats merged cell
         content across columns).
      2. Detect header row automatically.
      3. If a header is found → "الكود: Eng101 | المقرر: نظريات الترجمة | الساعات: 2"
         This lets the RAG answer "ما مقررات السنة الأولى؟" or "كم ساعة Eng101؟"
      4. If no header → emit clean pipe-separated rows (still readable).
      5. Always emit a structured summary line per data row so keyword search
         can find course codes, names, and credit hours together.
    """
    if not table:
        return ""

    # ── Step 1: clean cells ───────────────────────────────────────────────────
    cleaned: list[list[str]] = []
    for row in table:
        cleaned_row = []
        for cell in row:
            val = str(cell).strip() if cell is not None else ""
            # Collapse internal newlines (common in merged PDF cells)
            val = re.sub(r'\s*\n\s*', ' ', val).strip()
            cleaned_row.append(val)
        if any(c for c in cleaned_row):
            cleaned.append(cleaned_row)

    if not cleaned:
        return ""

    # ── Step 2: detect header ─────────────────────────────────────────────────
    # Known Arabic header keywords for course tables
    COURSE_HEADER_KEYWORDS = {
        "الكود", "كود", "code",
        "المقرر", "اسم المقرر", "المقرر #", "course", "course title",
        "الساعات", "ساعة", "ساعات", "ساعات معتمدة", "credit", "hours",
        "نظري", "عملي", "نظرى",
        "متطلب", "متطلب سابق", "prerequisite",
        "الفصل", "semester",
        "عدد", "عدد الساعات",
        "ملاحظات", "notes",
    }

    def _looks_like_header(row: list[str]) -> bool:
        non_empty = [c.lower() for c in row if c]
        if not non_empty:
            return False
        # Check for known course-table header keywords
        keyword_hits = sum(
            1 for c in non_empty
            if any(kw in c for kw in COURSE_HEADER_KEYWORDS)
        )
        if keyword_hits >= 1:
            return True
        # Fallback: short non-numeric cells dominate
        short_text = sum(1 for c in non_empty if len(c) < 40 and not c.isdigit())
        return short_text >= len(non_empty) * 0.6

    has_header = len(cleaned) > 1 and _looks_like_header(cleaned[0])
    headers = [h if h else f"col{i}" for i, h in enumerate(cleaned[0])] if has_header else []
    data_rows = cleaned[1:] if has_header else cleaned

    # ── Step 3: build output lines ────────────────────────────────────────────
    lines: list[str] = []

    # Emit header line so the chunk carries column context
    if headers:
        lines.append("جدول: " + " | ".join(h for h in headers if h and not h.startswith("col")))

    for row in data_rows:
        if not any(c for c in row):
            continue

        if headers:
            parts = []
            for h, v in zip(headers, row):
                if v:
                    label = h if not h.startswith("col") else "قيمة"
                    parts.append(f"{label}: {v}")
            if parts:
                lines.append(" | ".join(parts))
        else:
            # No header — join non-empty cells
            parts = [c for c in row if c]
            if parts:
                lines.append(" | ".join(parts))

    return "\n".join(lines)


def _extract_tables_with_pdfplumber(pdf_bytes: bytes) -> dict[int, str]:
    """
    Extract all tables from a PDF using pdfplumber.

    Returns a dict mapping page_number (1-based) → table text.
    Multiple tables on the same page are concatenated with a blank line.

    Uses a cascade of strategies (strict lines → relaxed lines → text-based)
    so borderless and partially-bordered tables are also caught.
    """
    if not PDFPLUMBER_AVAILABLE:
        return {}

    # Strategy cascade: try each set of settings in order, stop at first hit
    TABLE_STRATEGIES = [
        # 1. Strict: proper bordered tables (most reliable)
        {
            "vertical_strategy":   "lines_strict",
            "horizontal_strategy": "lines_strict",
            "snap_tolerance":      5,
            "join_tolerance":      3,
            "edge_min_length":     10,
            "min_words_vertical":  1,
            "min_words_horizontal": 1,
        },
        # 2. Relaxed lines: tables with faint or dashed borders
        {
            "vertical_strategy":   "lines",
            "horizontal_strategy": "lines",
            "snap_tolerance":      8,
            "join_tolerance":      5,
            "edge_min_length":     5,
            "min_words_vertical":  1,
            "min_words_horizontal": 1,
        },
        # 3. Text-based: completely borderless tables (alignment-only)
        {
            "vertical_strategy":   "text",
            "horizontal_strategy": "text",
            "snap_tolerance":      5,
        },
    ]

    page_tables: dict[int, str] = {}
    try:
        import io as _io
        with pdfplumber.open(_io.BytesIO(pdf_bytes)) as pdf:
            for page in pdf.pages:
                page_num = page.page_number  # 1-based
                tables = []

                for strategy in TABLE_STRATEGIES:
                    try:
                        tables = page.extract_tables(table_settings=strategy)
                        if tables:
                            break  # found tables with this strategy
                    except Exception as e:
                        print(f"  [pdf_processor] pdfplumber strategy error page {page_num}: {e}")
                        continue

                if tables:
                    table_texts = []
                    for tbl in tables:
                        txt = _table_to_text(tbl)
                        if txt.strip():
                            table_texts.append(txt)
                    if table_texts:
                        page_tables[page_num] = "\n\n".join(table_texts)
                        print(f"  [pdf_processor] Page {page_num}: extracted {len(tables)} table(s)")
    except Exception as e:
        print(f"  [pdf_processor] pdfplumber error: {e}")

    return page_tables


# ---------------------------------------------------------------------------
# Extraction backends
# ---------------------------------------------------------------------------

def _extract_with_pymupdf(pdf_bytes: bytes) -> list[dict]:
    """Native text extraction via PyMuPDF with RTL-aware ordering for Arabic."""
    pages = []
    try:
        doc = fitz.open(stream=pdf_bytes, filetype="pdf")
        for i in range(len(doc)):
            try:
                page = doc[i]
                # Use "dict" mode to get blocks with position info,
                # then sort RTL-aware (top-to-bottom, right-to-left)
                blocks = page.get_text("dict", flags=fitz.TEXT_PRESERVE_WHITESPACE).get("blocks", [])
                # Sort blocks: top-to-bottom primarily, right-to-left for same row
                blocks_sorted = sorted(blocks, key=lambda b: (round(b["bbox"][1] / 10), -b["bbox"][0]))
                lines_text = []
                for block in blocks_sorted:
                    if block.get("type") != 0:  # 0 = text block
                        continue
                    for line in block.get("lines", []):
                        line_text = " ".join(
                            span.get("text", "") for span in line.get("spans", [])
                        ).strip()
                        if line_text:
                            lines_text.append(line_text)
                raw = "\n".join(lines_text)
            except Exception:
                # Fallback to plain text mode
                try:
                    raw = page.get_text("text") or ""
                except Exception:
                    raw = ""
            pages.append({"page_number": i + 1, "text": raw, "method": "native_pymupdf"})
        doc.close()
    except Exception as e:
        print(f"  [pdf_processor] PyMuPDF error: {e}")
    return pages


def _extract_with_pypdf(pdf_bytes: bytes) -> list[dict]:
    """Fallback native text extraction via pypdf."""
    pages = []
    try:
        reader = pypdf.PdfReader(io.BytesIO(pdf_bytes))
        for i, page in enumerate(reader.pages):
            try:
                raw = page.extract_text() or ""
            except Exception:
                raw = ""
            pages.append({"page_number": i + 1, "text": raw, "method": "native_pypdf"})
    except Exception as e:
        print(f"  [pdf_processor] pypdf error: {e}")
    return pages


def _ocr_pages(pdf_bytes: bytes, total_pages: int) -> list[dict]:
    """Render pages to images and run Tesseract OCR."""
    if not PYMUPDF_AVAILABLE or not TESSERACT_AVAILABLE:
        return [{"page_number": i, "text": "", "method": "ocr_skipped"}
                for i in range(1, total_pages + 1)]
    pages = []
    try:
        doc  = fitz.open(stream=pdf_bytes, filetype="pdf")
        zoom = OCR_DPI / 72
        mat  = fitz.Matrix(zoom, zoom)
        for i in range(len(doc)):
            try:
                pix = doc[i].get_pixmap(matrix=mat, alpha=False)
                img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
                ocr_text = pytesseract.image_to_string(
                    img, lang=TESSERACT_LANG, config=TESSERACT_CONFIG
                )
            except Exception as e:
                print(f"  [pdf_processor] OCR error page {i+1}: {e}")
                ocr_text = ""
            pages.append({"page_number": i + 1, "text": ocr_text, "method": "ocr_tesseract"})
        doc.close()
    except Exception as e:
        print(f"  [pdf_processor] render error: {e}")
        pages = [{"page_number": i, "text": "", "method": "ocr_failed"}
                 for i in range(1, total_pages + 1)]
    return pages


# ---------------------------------------------------------------------------
# Merge helpers
# ---------------------------------------------------------------------------

def _merge_texts(native: str, ocr: str) -> str:
    """
    Merge native and OCR text with a strong preference for native text.

    Rules (in order):
      1. If native is empty  → use OCR (image-only page)
      2. If OCR is empty     → use native (no OCR ran / sparse page)
      3. If native >= NATIVE_TEXT_THRESHOLD chars → use native ONLY
         (sufficient native text: OCR would only add watermark noise)
      4. If OCR is much richer than native (ratio <= 0.3) → use OCR only
      5. Otherwise (both thin) → concatenate with separator
    """
    n, o = len(native.strip()), len(ocr.strip())
    if n == 0 and o == 0:
        return ""
    if n == 0:
        return ocr.strip()
    if o == 0:
        return native.strip()
    # Sufficient native text → prefer it exclusively (avoid OCR noise)
    if n >= NATIVE_TEXT_THRESHOLD:
        return native.strip()
    # OCR is dramatically richer → use OCR only
    ratio = n / max(o, 1)
    if ratio <= 0.3:
        return ocr.strip()
    # Both thin → concatenate (rare case: heavily image-mixed pages)
    return native.strip() + "\n\n" + ocr.strip()


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def extract_and_structure_pdf(
    pdf_bytes: bytes,
    filename: str,
    force_ocr: bool = False,
) -> dict:
    """
    Full extraction + cleaning pipeline for a single PDF.

    Returns a JSON-serialisable dict:
    {
        "filename": str,
        "total_pages": int,
        "extraction_method": "native" | "ocr" | "hybrid",
        "pages": [
            {
                "page_number": int,
                "text": str,          # cleaned text
                "raw_text": str,      # pre-cleaning text (for debugging)
                "char_count": int,
                "extraction_method": str,
                "language": str
            },
            ...
        ],
        "full_text": str,
        "metadata": {
            "has_arabic": bool,
            "has_english": bool,
            "total_chars": int
        }
    }
    """
    print(f"  [pdf_processor] Processing '{filename}' ...")

    # ── Pass 1: Native extraction ─────────────────────────────────────────
    if PYMUPDF_AVAILABLE:
        native_pages = _extract_with_pymupdf(pdf_bytes)
    elif PYPDF_AVAILABLE:
        print("  [pdf_processor] PyMuPDF unavailable, falling back to pypdf")
        native_pages = _extract_with_pypdf(pdf_bytes)
    else:
        print("  [pdf_processor] ERROR: no PDF library available")
        return {
            "filename": filename, "total_pages": 0,
            "extraction_method": "none", "pages": [], "full_text": "",
            "metadata": {"has_arabic": False, "has_english": False, "total_chars": 0}
        }

    total_pages = len(native_pages)
    print(f"  [pdf_processor] {total_pages} pages found")

    # ── Pass 2: Table extraction via pdfplumber ───────────────────────────
    print(f"  [pdf_processor] Extracting tables with pdfplumber ...")
    page_tables = _extract_tables_with_pdfplumber(pdf_bytes)
    if page_tables:
        print(f"  [pdf_processor] Tables found on {len(page_tables)} page(s)")
    else:
        print(f"  [pdf_processor] No tables detected")

    # ── Pass 3: OCR (only for sparse pages) ──────────────────────────────
    sparse = [p for p in native_pages if len(p["text"].strip()) < NATIVE_TEXT_THRESHOLD]
    run_ocr = force_ocr or (sparse and TESSERACT_AVAILABLE and PYMUPDF_AVAILABLE)

    if run_ocr:
        print(f"  [pdf_processor] {len(sparse)} sparse page(s) → running OCR ...")
        ocr_pages = _ocr_pages(pdf_bytes, total_pages)
    else:
        if sparse and not TESSERACT_AVAILABLE:
            print("  [pdf_processor] Sparse pages found but Tesseract not available – OCR skipped")
        ocr_pages = [{"page_number": p["page_number"], "text": "", "method": "ocr_skipped"}
                     for p in native_pages]

    # ── Merge, clean, annotate ────────────────────────────────────────────
    structured_pages = []
    methods_used: set[str] = set()

    for page_idx, (native, ocr) in enumerate(zip(native_pages, ocr_pages)):
        page_num = native["page_number"]
        raw_merged = _merge_texts(native["text"], ocr["text"])

        # Inject table text for this page (appended after prose text)
        table_text = page_tables.get(page_num, "")
        if table_text:
            # Separate table content clearly so the chunker keeps it together
            raw_merged = raw_merged + "\n\n" + table_text if raw_merged.strip() else table_text

        # Advanced Arabic cleaning (also handles English text gracefully)
        cleaned = clean_arabic_text(
            raw_merged,
            remove_diacritics_flag=True,
            normalize_chars=True,
            fix_ocr=True,
            filter_noise=True,
            reset_seen_lines=(page_idx == 0),
        )

        n_len = len(native["text"].strip())
        o_len = len(ocr["text"].strip())

        if n_len >= NATIVE_TEXT_THRESHOLD and o_len < NATIVE_TEXT_THRESHOLD:
            method = "native"
        elif o_len >= NATIVE_TEXT_THRESHOLD and n_len < NATIVE_TEXT_THRESHOLD:
            method = "ocr"
        elif n_len >= NATIVE_TEXT_THRESHOLD and o_len >= NATIVE_TEXT_THRESHOLD:
            method = "hybrid"
        else:
            method = "native"

        if table_text:
            method = method + "+tables"

        methods_used.add(method)
        lang = detect_language(cleaned)

        structured_pages.append({
            "page_number": page_num,
            "text": cleaned,
            "raw_text": raw_merged,   # kept for debugging / audit
            "char_count": len(cleaned),
            "extraction_method": method,
            "language": lang,
            "has_tables": bool(table_text),
        })

    # ── Build full text and document-level metadata ───────────────────────
    full_text = "\n\n".join(
        f"[Page {p['page_number']}]\n{p['text']}"
        for p in structured_pages if p["text"]
    )

    arabic_re = re.compile(r"[\u0600-\u06FF]+")
    latin_re  = re.compile(r"[A-Za-z]+")
    has_arabic  = bool(arabic_re.search(full_text))
    has_english = bool(latin_re.search(full_text))
    total_chars = sum(p["char_count"] for p in structured_pages)
    has_tables  = any(p.get("has_tables", False) for p in structured_pages)
    tables_pages = [p["page_number"] for p in structured_pages if p.get("has_tables")]

    if "hybrid" in methods_used:
        overall_method = "hybrid"
    elif methods_used == {"ocr"}:
        overall_method = "ocr"
    else:
        overall_method = "native"

    if page_tables:
        overall_method = overall_method + "+tables"

    result = {
        "filename": filename,
        "total_pages": total_pages,
        "extraction_method": overall_method,
        "pages": structured_pages,
        "full_text": full_text,
        "metadata": {
            "has_arabic": has_arabic,
            "has_english": has_english,
            "total_chars": total_chars,
            "has_tables": has_tables,
            "tables_on_pages": tables_pages,
        },
    }

    print(
        f"  [pdf_processor] Done: {total_pages} pages, {total_chars} chars, "
        f"method={overall_method}, arabic={has_arabic}, english={has_english}, "
        f"tables={has_tables} (pages: {tables_pages})"
    )
    return result


def structured_doc_to_chunks(
    structured_doc: dict,
    # kept for backward-compat; semantic chunker uses its own defaults
    chunk_size: int = 800,
    chunk_overlap: int = 150,
) -> tuple[list[str], list[dict]]:
    """
    Convert a structured document to ChromaDB-ready chunks.

    Delegates to semantic_chunker.semantic_chunk_document() which performs:
      - Structural segmentation (headings, articles, sections)
      - Paragraph grouping
      - Sentence-boundary splitting
      - Size guardrails (min/target/max chars)
      - Rich metadata: section title, language, keywords, chunk ID

    Returns
    -------
    (texts, metadatas)
    """
    from routes.semantic_chunker import semantic_chunk_document

    return semantic_chunk_document(
        structured_doc=structured_doc,
        target_chars=chunk_size,
        max_chars=int(chunk_size * 1.5),
        overlap_chars=chunk_overlap,
        extract_kw=True,
        max_keywords=8,
    )