"""
arabic_cleaner.py
==================
Advanced Arabic text cleaning and normalization for RAG pipelines.

Handles:
  - Arabic character normalization (hamza variants, alef, ya, ta marbuta)
  - Diacritics (tashkeel) removal
  - Tatweel (kashida) removal
  - Zero-width and directional Unicode control characters
  - Common OCR artefacts in Arabic text (broken words, spacing errors)
  - Mixed Arabic/English encoding problems
  - Punctuation normalization
  - Repeated character collapsing
  - Sentence boundary repair

No external Arabic NLP libraries required – pure regex + Unicode.
Optional: install `pyarabic` for deeper normalization (graceful fallback).
"""

from __future__ import annotations

import re
import unicodedata

# ---------------------------------------------------------------------------
# Optional: pyarabic for deeper normalization
# ---------------------------------------------------------------------------
try:
    import pyarabic.araby as araby
    PYARABIC_AVAILABLE = True
except ImportError:
    PYARABIC_AVAILABLE = False

# ---------------------------------------------------------------------------
# Unicode ranges
# ---------------------------------------------------------------------------

# Arabic Unicode blocks
ARABIC_BLOCK        = r"\u0600-\u06FF"
ARABIC_SUPPLEMENT   = r"\u0750-\u077F"
ARABIC_EXTENDED_A   = r"\u08A0-\u08FF"
ARABIC_PRESENTATION_A = r"\uFB50-\uFDFF"
ARABIC_PRESENTATION_B = r"\uFE70-\uFEFF"

ARABIC_PATTERN = re.compile(
    f"[{ARABIC_BLOCK}{ARABIC_SUPPLEMENT}{ARABIC_EXTENDED_A}"
    f"{ARABIC_PRESENTATION_A}{ARABIC_PRESENTATION_B}]"
)

# Arabic diacritics (tashkeel / harakat)
# U+064B–U+065F: fathatan, dammatan, kasratan, fatha, damma, kasra,
#                shadda, sukun, and extended marks
# U+0610–U+061A: additional Arabic signs
# U+06D6–U+06DC: Quranic annotation signs
# U+06DF–U+06E4: more Quranic marks
# U+06E7–U+06E8: Quranic marks
# U+06EA–U+06ED: Quranic marks
DIACRITICS_PATTERN = re.compile(
    r"[\u064B-\u065F\u0610-\u061A\u06D6-\u06DC\u06DF-\u06E4\u06E7\u06E8\u06EA-\u06ED]"
)

# Tatweel / Kashida (U+0640) – decorative elongation character
TATWEEL_PATTERN = re.compile(r"\u0640+")

# Zero-width and directional control characters
ZERO_WIDTH_CHARS = [
    "\u200b",  # Zero Width Space
    "\u200c",  # Zero Width Non-Joiner
    "\u200d",  # Zero Width Joiner
    "\u200e",  # Left-to-Right Mark
    "\u200f",  # Right-to-Left Mark
    "\u202a",  # Left-to-Right Embedding
    "\u202b",  # Right-to-Left Embedding
    "\u202c",  # Pop Directional Formatting
    "\u202d",  # Left-to-Right Override
    "\u202e",  # Right-to-Left Override
    "\u2066",  # Left-to-Right Isolate
    "\u2067",  # Right-to-Left Isolate
    "\u2068",  # First Strong Isolate
    "\u2069",  # Pop Directional Isolate
    "\ufeff",  # Byte Order Mark / Zero Width No-Break Space
]

# ---------------------------------------------------------------------------
# Character normalization maps
# ---------------------------------------------------------------------------

# Alef variants → plain alef (ا)
ALEF_VARIANTS = {
    "\u0622": "\u0627",  # آ → ا
    "\u0623": "\u0627",  # أ → ا
    "\u0625": "\u0627",  # إ → ا
    "\u0671": "\u0627",  # ٱ → ا (Alef Wasla)
    "\u0672": "\u0627",  # ٲ → ا
    "\u0673": "\u0627",  # ٳ → ا
}

# Ya variants → dotless ya (ي)
YA_VARIANTS = {
    "\u0649": "\u064A",  # ى → ي (Alef Maqsura)
}

# Ta Marbuta → Ha (ة → ه)
# NOTE: Keeping ta marbuta as-is is often better for meaning preservation.
# Set NORMALIZE_TA_MARBUTA = True only if your retrieval benefits from it.
NORMALIZE_TA_MARBUTA = False
TA_MARBUTA_MAP = {
    "\u0629": "\u0647",  # ة → ه
}

# Waw variants
WAW_VARIANTS = {
    "\u0624": "\u0648",  # ؤ → و
}

# Ha variants (final ha with hamza above)
HA_VARIANTS = {
    "\u0626": "\u064A",  # ئ → ي (ya with hamza above → ya)
}

# Arabic-Indic digits → Western Arabic digits
ARABIC_INDIC_DIGITS = {
    "\u0660": "0", "\u0661": "1", "\u0662": "2", "\u0663": "3",
    "\u0664": "4", "\u0665": "5", "\u0666": "6", "\u0667": "7",
    "\u0668": "8", "\u0669": "9",
    # Extended Arabic-Indic (Farsi/Urdu)
    "\u06F0": "0", "\u06F1": "1", "\u06F2": "2", "\u06F3": "3",
    "\u06F4": "4", "\u06F5": "5", "\u06F6": "6", "\u06F7": "7",
    "\u06F8": "8", "\u06F9": "9",
}

# Arabic punctuation → standard equivalents
ARABIC_PUNCTUATION_MAP = {
    "\u060C": ",",   # Arabic comma → comma
    "\u061B": ";",   # Arabic semicolon → semicolon
    "\u061F": "?",   # Arabic question mark → question mark
    "\u066A": "%",   # Arabic percent sign
    "\u066B": ".",   # Arabic decimal separator
    "\u066C": ",",   # Arabic thousands separator
    "\u06D4": ".",   # Arabic full stop
    # Keep Arabic comma as-is for sentence splitting (handled separately)
}

# Build combined normalization table
_NORM_TABLE: dict[int, str] = {}
for src, dst in {
    **ALEF_VARIANTS,
    **YA_VARIANTS,
    **WAW_VARIANTS,
    **HA_VARIANTS,
    **ARABIC_INDIC_DIGITS,
    **ARABIC_PUNCTUATION_MAP,
    **(TA_MARBUTA_MAP if NORMALIZE_TA_MARBUTA else {}),
}.items():
    _NORM_TABLE[ord(src)] = dst


# ---------------------------------------------------------------------------
# OCR artefact patterns
# ---------------------------------------------------------------------------

# Broken words: single Arabic letter isolated by spaces that should be joined
# e.g. "ا ل ج ا م ع ة" → "الجامعة"
# Heuristic: 3+ consecutive single-char Arabic tokens separated by single spaces
_BROKEN_WORD_PATTERN = re.compile(
    r"(?<![^\s])([\u0600-\u06FF])\s([\u0600-\u06FF])(?:\s([\u0600-\u06FF]))+(?![^\s])"
)

# Repeated punctuation (OCR noise)
_REPEATED_PUNCT_PATTERN = re.compile(r"([.،,;:!?])\1{2,}")

# Multiple spaces → single space
_MULTI_SPACE_PATTERN = re.compile(r"[ \t]{2,}")

# Space before punctuation (common OCR error) — but not inside course codes
_SPACE_BEFORE_PUNCT_PATTERN = re.compile(r"(?<![A-Za-z\d])\s+([.،,;:!?])")

# Missing space after Arabic sentence-ending punctuation
# But NOT after a dot that's between letters/digits (e.g. "Eng101." or "1.5")
_MISSING_SPACE_AFTER_PUNCT = re.compile(r"([،,;:!?])([^\s\d\n])")

# Lines that are pure noise: only digits, punctuation, or very short
_NOISE_LINE_PATTERN = re.compile(r"^[\d\s\W]{0,4}$")

# Page number lines (common in PDFs): standalone number, possibly with dashes
_PAGE_NUMBER_PATTERN = re.compile(r"^\s*[-–—]?\s*\d{1,4}\s*[-–—]?\s*$")

# Header/footer repetition detector (tracks seen short lines)
_seen_short_lines: set[str] = set()


# ---------------------------------------------------------------------------
# Core normalization functions
# ---------------------------------------------------------------------------

# Pattern to find multi-digit Eastern Arabic (Arabic-Indic) numbers
# These are visually reversed by PyMuPDF when extracted from RTL PDFs
_ARABIC_INDIC_NUMBER_RE = re.compile(
    r"[\u0660-\u0669\u06F0-\u06F9]{2,}"  # 2+ consecutive Arabic-Indic digits
)


def _reverse_arabic_indic_numbers(text: str) -> str:
    """
    Reverse multi-digit Eastern Arabic (Arabic-Indic) number strings.

    PyMuPDF extracts RTL numbers in visual order, so the number 82 written
    in Eastern Arabic as \u0668\u0662 (٨٢) is extracted as \u0662\u0668 (٢٨).
    This function reverses each multi-digit sequence back to logical order
    BEFORE converting to Western digits, ensuring 82 stays 82 (not 28).

    Single-digit numbers are unaffected.
    """
    def _rev(m: re.Match) -> str:
        return m.group(0)[::-1]   # reverse the captured digit string
    return _ARABIC_INDIC_NUMBER_RE.sub(_rev, text)


def normalize_arabic_chars(text: str) -> str:
    """
    Apply character-level normalization:
      - Fix reversed Eastern Arabic multi-digit numbers (PyMuPDF RTL bug)
      - Alef variants → ا
      - Ya variants → ي
      - Waw variants → و
      - Arabic-Indic digits → Western digits
      - Arabic punctuation → standard equivalents
    """
    # Must reverse BEFORE converting digits to avoid ٢٨ → 28 instead of 82
    text = _reverse_arabic_indic_numbers(text)
    return text.translate(_NORM_TABLE)


def remove_diacritics(text: str) -> str:
    """Remove all Arabic diacritical marks (tashkeel/harakat)."""
    return DIACRITICS_PATTERN.sub("", text)


def remove_tatweel(text: str) -> str:
    """Remove tatweel/kashida elongation characters."""
    return TATWEEL_PATTERN.sub("", text)


def remove_zero_width_chars(text: str) -> str:
    """Remove zero-width and directional Unicode control characters."""
    for ch in ZERO_WIDTH_CHARS:
        text = text.replace(ch, "")
    return text


def fix_ocr_broken_words(text: str) -> str:
    """
    Attempt to repair broken Arabic words produced by OCR.
    Heuristic: sequences of single Arabic characters separated by spaces
    are likely one word that was split character-by-character.

    NOTE: Skip lines that look like table rows (contain | or "label: value")
    to avoid merging table cell content accidentally.
    """
    def _join_match(m: re.Match) -> str:
        return m.group(0).replace(" ", "")

    lines = text.split("\n")
    result = []
    for line in lines:
        # Don't touch table rows — pipe separator or "Arabic: value" pattern
        if "|" in line or re.search(r"[\u0600-\u06FF]{2,}\s*:", line):
            result.append(line)
            continue
        # Iteratively join broken sequences (up to 3 passes for long words)
        for _ in range(3):
            new_line = _BROKEN_WORD_PATTERN.sub(_join_match, line)
            if new_line == line:
                break
            line = new_line
        result.append(line)
    return "\n".join(result)


def fix_punctuation_spacing(text: str) -> str:
    """Fix common spacing issues around punctuation."""
    # Remove space before punctuation
    text = _SPACE_BEFORE_PUNCT_PATTERN.sub(r"\1", text)
    # Ensure space after punctuation (not before digit or newline)
    text = _MISSING_SPACE_AFTER_PUNCT.sub(r"\1 \2", text)
    # Collapse repeated punctuation
    text = _REPEATED_PUNCT_PATTERN.sub(r"\1", text)
    return text


def normalize_whitespace(text: str) -> str:
    """Normalize whitespace: collapse multiple spaces, fix line endings."""
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = _MULTI_SPACE_PATTERN.sub(" ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text


def filter_noise_lines(text: str, reset_seen: bool = True) -> str:
    """
    Remove lines that are pure noise:
      - Standalone page numbers
      - Lines with only punctuation/digits (< 5 chars)
      - Repeated header/footer lines (detected by frequency)

    NOTE: Lines that are part of table rows (contain |) are never dropped,
    even if they are short or numeric — table cells like "2" or "Eng101"
    are meaningful content.
    """
    if reset_seen:
        _seen_short_lines.clear()

    lines = text.split("\n")
    line_freq: dict[str, int] = {}
    for line in lines:
        stripped = line.strip()
        if stripped:
            line_freq[stripped] = line_freq.get(stripped, 0) + 1

    cleaned = []
    for line in lines:
        stripped = line.strip()

        # Drop empty lines (will be re-added as paragraph breaks)
        if not stripped:
            cleaned.append("")
            continue

        # NEVER drop table rows — they contain course codes, hours, names
        if "|" in stripped or stripped.startswith("جدول:"):
            cleaned.append(stripped)
            continue

        # Drop standalone page numbers
        if _PAGE_NUMBER_PATTERN.match(stripped):
            continue

        # Drop pure noise lines
        if _NOISE_LINE_PATTERN.match(stripped) and len(stripped) < 5:
            continue

        # Drop lines that appear 4+ times (likely headers/footers)
        if line_freq.get(stripped, 0) >= 4 and len(stripped) < 80:
            continue

        # Drop lines with no letters at all (only symbols/numbers)
        if not any(unicodedata.category(ch).startswith("L") for ch in stripped):
            if len(stripped) <= 6:
                continue

        cleaned.append(stripped)

    # Collapse multiple blank lines
    result = "\n".join(cleaned)
    result = re.sub(r"\n{3,}", "\n\n", result)
    return result.strip()


# ---------------------------------------------------------------------------
# Language detection helpers
# ---------------------------------------------------------------------------

def detect_language(text: str) -> str:
    """
    Detect the dominant language of a text segment.
    Returns: "arabic" | "english" | "mixed" | "unknown"
    """
    arabic_chars = len(ARABIC_PATTERN.findall(text))
    latin_chars = len(re.findall(r"[A-Za-z]", text))
    total = arabic_chars + latin_chars

    if total == 0:
        return "unknown"

    arabic_ratio = arabic_chars / total
    if arabic_ratio >= 0.75:
        return "arabic"
    elif arabic_ratio <= 0.25:
        return "english"
    else:
        return "mixed"


# ---------------------------------------------------------------------------
# Keyword extraction (lightweight, no external NLP)
# ---------------------------------------------------------------------------

# Arabic stopwords (common function words to exclude from keywords)
ARABIC_STOPWORDS = {
    "في", "من", "إلى", "على", "عن", "مع", "هذا", "هذه", "ذلك", "تلك",
    "التي", "الذي", "الذين", "اللواتي", "اللاتي", "كان", "كانت", "يكون",
    "تكون", "هو", "هي", "هم", "هن", "أنا", "أنت", "أنتم", "نحن",
    "وهو", "وهي", "وهم", "أو", "و", "ثم", "لكن", "لأن", "حتى",
    "إذا", "إذ", "قد", "لقد", "لم", "لن", "ما", "لا", "إن", "أن",
    "كل", "بعض", "أي", "أيضا", "فقط", "جدا", "كما", "مما", "عند",
    "بين", "خلال", "حول", "بعد", "قبل", "منذ", "حيث", "كيف", "متى",
    "أين", "لماذا", "ماذا", "الذي", "التي", "الذين", "ال", "به", "بها",
    "له", "لها", "لهم", "عليه", "عليها", "عليهم", "فيه", "فيها", "فيهم",
    "منه", "منها", "منهم", "إليه", "إليها", "إليهم", "عنه", "عنها",
}

ENGLISH_STOPWORDS = {
    "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
    "of", "with", "by", "from", "is", "are", "was", "were", "be", "been",
    "being", "have", "has", "had", "do", "does", "did", "will", "would",
    "could", "should", "may", "might", "shall", "can", "this", "that",
    "these", "those", "it", "its", "they", "them", "their", "we", "our",
    "you", "your", "he", "she", "his", "her", "i", "my", "me", "us",
    "as", "if", "so", "not", "no", "nor", "yet", "both", "either",
    "each", "all", "any", "few", "more", "most", "other", "such",
    "than", "then", "when", "where", "which", "who", "whom", "how",
    "what", "why", "also", "just", "only", "very", "too", "about",
}


def extract_keywords(text: str, max_keywords: int = 10) -> list[str]:
    """
    Extract the most significant words from a text segment as keywords.
    Uses TF-based scoring (no external NLP library needed).
    Returns a list of up to max_keywords keyword strings.
    """
    # Tokenize: split on whitespace and punctuation
    tokens = re.findall(r"[\u0600-\u06FF]{3,}|[A-Za-z]{4,}", text)

    # Lowercase for English, keep Arabic as-is
    normalized_tokens = []
    for tok in tokens:
        if re.match(r"[A-Za-z]+", tok):
            normalized_tokens.append(tok.lower())
        else:
            normalized_tokens.append(tok)

    # Filter stopwords
    filtered = [
        t for t in normalized_tokens
        if t not in ARABIC_STOPWORDS and t not in ENGLISH_STOPWORDS
    ]

    # Count frequency
    freq: dict[str, int] = {}
    for tok in filtered:
        freq[tok] = freq.get(tok, 0) + 1

    # Sort by frequency, take top N
    sorted_tokens = sorted(freq.items(), key=lambda x: x[1], reverse=True)
    return [tok for tok, _ in sorted_tokens[:max_keywords]]


# ---------------------------------------------------------------------------
# Section title detection
# ---------------------------------------------------------------------------

# Patterns that suggest a line is a section heading
_HEADING_PATTERNS = [
    # Numbered headings: "1.", "1.1", "أولاً:", "المادة 5"
    re.compile(r"^\s*(?:\d+[\.\-\)]\s*)+\S"),
    re.compile(r"^\s*(?:المادة|الفصل|الباب|القسم|البند|أولاً|ثانياً|ثالثاً|رابعاً|خامساً)\b"),
    re.compile(r"^\s*(?:Article|Chapter|Section|Part|Clause)\s+\d+", re.IGNORECASE),
    # All-caps English heading
    re.compile(r"^\s*[A-Z][A-Z\s]{4,}$"),
    # Short line ending with colon
    re.compile(r"^.{3,60}:\s*$"),
]


def detect_section_title(line: str) -> bool:
    """Return True if the line looks like a section heading."""
    stripped = line.strip()
    if not stripped or len(stripped) > 120:
        return False
    return any(p.search(stripped) for p in _HEADING_PATTERNS)


# ---------------------------------------------------------------------------
# Master cleaning function
# ---------------------------------------------------------------------------

def clean_arabic_text(
    text: str,
    remove_diacritics_flag: bool = True,
    normalize_chars: bool = True,
    fix_ocr: bool = True,
    filter_noise: bool = True,
    reset_seen_lines: bool = True,
) -> str:
    """
    Full Arabic text cleaning pipeline.

    Steps (in order):
      1. Remove zero-width / directional control characters
      2. Unicode NFC normalization
      3. Arabic character normalization (alef, ya, waw variants)
      4. Remove diacritics (tashkeel)
      5. Remove tatweel (kashida)
      6. Fix OCR broken words
      7. Fix punctuation spacing
      8. Normalize whitespace
      9. Filter noise lines (page numbers, headers/footers)

    Parameters
    ----------
    text : str
        Raw input text (may be Arabic, English, or mixed).
    remove_diacritics_flag : bool
        Whether to strip diacritical marks.
    normalize_chars : bool
        Whether to normalize alef/ya/waw variants.
    fix_ocr : bool
        Whether to attempt OCR broken-word repair.
    filter_noise : bool
        Whether to remove noise lines (page numbers, repeated headers).
    reset_seen_lines : bool
        Reset the repeated-line tracker (set False when processing
        multiple pages of the same document in sequence).

    Returns
    -------
    str
        Cleaned, normalized text.
    """
    if not text:
        return ""

    # Step 1: Remove zero-width / directional chars
    text = remove_zero_width_chars(text)

    # Step 2: Unicode NFC normalization + strip control chars
    text = unicodedata.normalize("NFC", text)
    text = "".join(
        ch for ch in text
        if unicodedata.category(ch)[0] != "C" or ch in ("\n", "\t")
    )

    # Step 3: Arabic character normalization
    if normalize_chars:
        text = normalize_arabic_chars(text)

    # Step 4: Remove diacritics
    if remove_diacritics_flag:
        text = remove_diacritics(text)

    # Step 5: Remove tatweel
    text = remove_tatweel(text)

    # Step 6: Fix OCR broken words
    if fix_ocr:
        text = fix_ocr_broken_words(text)

    # Step 7: Fix punctuation spacing
    text = fix_punctuation_spacing(text)

    # Step 8: Normalize whitespace
    text = normalize_whitespace(text)

    # Step 9: Filter noise lines
    if filter_noise:
        text = filter_noise_lines(text, reset_seen=reset_seen_lines)

    return text.strip()