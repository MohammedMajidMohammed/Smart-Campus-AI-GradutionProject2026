# course_catalog.py  (v3 — indexed + debug)
# 4-layer architecture:
#   Layer 1 — Raw:        _parse_chunk()
#   Layer 2 — Normalized: _normalize()
#   Layer 3 — Indexed:    _build_indexes()
#   Layer 4 — Query:      query()

from __future__ import annotations

import re
import logging
from collections import defaultdict
from typing import Optional

logger = logging.getLogger(__name__)

# ─────────────────────────────────────────────────────────────────────────────
# Regex patterns
# ─────────────────────────────────────────────────────────────────────────────

_CODE_RE = re.compile(r"\b([A-Z]{2,4})[\s\-]?(\d{3,4})\b", re.IGNORECASE)

_ROW_RE = re.compile(
    r"(?:^\s*\d{1,2}\s+)?"
    r"([A-Z]{2,4})[\s\-]?(\d{3,4})\s+"
    r"([A-Za-z\u0600-\u06FF][^\n\r]{3,80})",
    re.MULTILINE | re.IGNORECASE,
)

_YEAR_RE = {
    1: re.compile(
        r"level\s*1|semester\s*[12]\s*(?:fall|spring)?|"
        r"\u0627\u0644\u0645\u0633\u062a\u0648\u0649\s*\u0627\u0644\u0623\u0648\u0644|"
        r"\u0627\u0644\u0641\u0631\u0642[\u0647\u0629]\s*\u0627\u0644\u0623\u0648\u0644[\u0647\u0649]?|"
        r"\u0641\u0631\u0642[\u0647\u0629]\s*\u0627\u0648\u0644[\u0647\u0649]?|"
        r"\u0627\u0644\u0633\u0646\u0629\s*\u0627\u0644\u0623\u0648\u0644\u0649|year\s*1|first\s*year",
        re.IGNORECASE | re.UNICODE),
    2: re.compile(
        r"level\s*2|"
        r"\u0627\u0644\u0645\u0633\u062a\u0648\u0649\s*\u0627\u0644\u062b\u0627\u0646\u064a|"
        r"\u0627\u0644\u0641\u0631\u0642[\u0647\u0629]\s*\u0627\u0644\u062b\u0627\u0646\u064a[\u0647\u0629]?|"
        r"\u0641\u0631\u0642[\u0647\u0629]\s*\u062a\u0627\u0646\u064a[\u0647\u0629]?|"
        r"\u0627\u0644\u0633\u0646\u0629\s*\u0627\u0644\u062b\u0627\u0646\u064a\u0629|year\s*2|second\s*year",
        re.IGNORECASE | re.UNICODE),
    3: re.compile(
        r"level\s*3|"
        r"\u0627\u0644\u0645\u0633\u062a\u0648\u0649\s*\u0627\u0644\u062b\u0627\u0644\u062b|"
        r"\u0627\u0644\u0641\u0631\u0642[\u0647\u0629]\s*\u0627\u0644\u062b\u0627\u0644\u062b[\u0647\u0629]?|"
        r"\u0641\u0631\u0642[\u0647\u0629]\s*\u062a\u0627\u0644\u062a[\u0647\u0629]?|"
        r"\u0627\u0644\u0633\u0646\u0629\s*\u0627\u0644\u062b\u0627\u0644\u062b\u0629|year\s*3|third\s*year",
        re.IGNORECASE | re.UNICODE),
    4: re.compile(
        r"level\s*4|"
        r"\u0627\u0644\u0645\u0633\u062a\u0648\u0649\s*\u0627\u0644\u0631\u0627\u0628\u0639|"
        r"\u0627\u0644\u0641\u0631\u0642[\u0647\u0629]\s*\u0627\u0644\u0631\u0627\u0628\u0639[\u0647\u0629]?|"
        r"\u0641\u0631\u0642[\u0647\u0629]\s*\u0631\u0627\u0628\u0639[\u0647\u0629]?|"
        r"\u0627\u0644\u0633\u0646\u0629\s*\u0627\u0644\u0631\u0627\u0628\u0639\u0629|year\s*4|fourth\s*year",
        re.IGNORECASE | re.UNICODE),
}

_SEM_RE = {
    1: re.compile(
        r"semester\s*1|fall|"
        r"\u0627\u0644\u062a\u0631\u0645\s*\u0627\u0644\u0623\u0648\u0644|"
        r"\u0627\u0644\u0641\u0635\u0644\s*\u0627\u0644\u0623\u0648\u0644|"
        r"\u062a\u0631\u0645\s*\u0627\u0648\u0644",
        re.IGNORECASE | re.UNICODE),
    2: re.compile(
        r"semester\s*2|spring|"
        r"\u0627\u0644\u062a\u0631\u0645\s*\u0627\u0644\u062b\u0627\u0646\u064a|"
        r"\u0627\u0644\u0641\u0635\u0644\s*\u0627\u0644\u062b\u0627\u0646\u064a|"
        r"\u062a\u0631\u0645\s*\u062a\u0627\u0646\u064a",
        re.IGNORECASE | re.UNICODE),
}

_PROG_RE: dict[str, re.Pattern] = {
    "computer science": re.compile(
        r"\u062d\u0627\u0633\u0628\u0627\u062a|\u062d\u0627\u0633\u0628|\u062d\u0627\u0633\u0648\u0628|"
        r"\u0643\u0645\u0628\u064a\u0648\u062a\u0631|computer\s*science|information\s*technology|"
        r"\u0646\u0638\u0645\s*\u0645\u0639\u0644\u0648\u0645\u0627\u062a|"
        r"\u062a\u0642\u0646\u064a\u0629\s*\u0645\u0639\u0644\u0648\u0645\u0627\u062a|"
        r"\u0630\u0643\u0627\u0621\s*\u0627\u0635\u0637\u0646\u0627\u0639\u064a|artificial\s*intelligence",
        re.IGNORECASE | re.UNICODE),
    "medicine": re.compile(
        r"\b\u0637\u0628\b(?!\s*\u0623\u0633\u0646\u0627\u0646)|medicine(?!\s*dentist)|"
        r"medical\s*school|\u0643\u0644\u064a\u0629\s*\u0627\u0644\u0637\u0628\b",
        re.IGNORECASE | re.UNICODE),
    "dentistry": re.compile(
        r"\u0637\u0628\s*\u0623\u0633\u0646\u0627\u0646|\u0623\u0633\u0646\u0627\u0646|"
        r"dentistry|dental|\u0643\u0644\u064a\u0629\s*\u0637\u0628\s*\u0627\u0644\u0623\u0633\u0646\u0627\u0646",
        re.IGNORECASE | re.UNICODE),
    "engineering": re.compile(
        r"\u0647\u0646\u062f\u0633\u0629|\u0647\u0646\u062f\u0633\u0647|"
        r"engineering(?!\s*chemistry)|\u0643\u0644\u064a\u0629\s*\u0627\u0644\u0647\u0646\u062f\u0633\u0629",
        re.IGNORECASE | re.UNICODE),
    "pharmacy": re.compile(
        r"\u0635\u064a\u062f\u0644\u0629|\u0635\u064a\u062f\u0644\u0647|"
        r"pharmacy|pharmaceutical|\u0643\u0644\u064a\u0629\s*\u0627\u0644\u0635\u064a\u062f\u0644\u0629",
        re.IGNORECASE | re.UNICODE),
    "law": re.compile(
        r"\u062d\u0642\u0648\u0642|\u0642\u0627\u0646\u0648\u0646|"
        r"law\s*faculty|\u0643\u0644\u064a\u0629\s*\u0627\u0644\u062d\u0642\u0648\u0642",
        re.IGNORECASE | re.UNICODE),
    "commerce": re.compile(
        r"\u062a\u062c\u0627\u0631\u0629|\u062a\u062c\u0627\u0631\u0647|"
        r"commerce|business\s*administration|\u0645\u062d\u0627\u0633\u0628\u0629|"
        r"\u0627\u0642\u062a\u0635\u0627\u062f|\u0643\u0644\u064a\u0629\s*\u0627\u0644\u062a\u062c\u0627\u0631\u0629",
        re.IGNORECASE | re.UNICODE),
    "arts": re.compile(
        r"\u0622\u062f\u0627\u0628|\u0627\u062f\u0627\u0628|arts|humanities|"
        r"\u0643\u0644\u064a\u0629\s*\u0627\u0644\u0622\u062f\u0627\u0628",
        re.IGNORECASE | re.UNICODE),
    "science": re.compile(
        r"\u0639\u0644\u0648\u0645(?!\s*\u062d\u0627\u0633\u0628)|"
        r"faculty\s*of\s*science|\u0643\u0644\u064a\u0629\s*\u0627\u0644\u0639\u0644\u0648\u0645",
        re.IGNORECASE | re.UNICODE),
    "education": re.compile(
        r"\u062a\u0631\u0628\u064a\u0629|\u062a\u0639\u0644\u064a\u0645|"
        r"education|\u0643\u0644\u064a\u0629\s*\u0627\u0644\u062a\u0631\u0628\u064a\u0629",
        re.IGNORECASE | re.UNICODE),
}

_FNAME_PROG: list[tuple[re.Pattern, str]] = [
    (re.compile(r"\u062d\u0627\u0633\u0628|\u062d\u0627\u0633\u0648\u0628|computer|cs|it|\u0630\u0643\u0627\u0621", re.IGNORECASE), "computer science"),
    (re.compile(r"\u0623\u0633\u0646\u0627\u0646|\u0627\u0633\u0646\u0627\u0646|dent", re.IGNORECASE | re.UNICODE), "dentistry"),
    (re.compile(r"\b\u0637\u0628\b(?!.*\u0623\u0633\u0646\u0627\u0646)|medicine", re.IGNORECASE | re.UNICODE), "medicine"),
    (re.compile(r"\u0647\u0646\u062f\u0633|engineer", re.IGNORECASE | re.UNICODE), "engineering"),
    (re.compile(r"\u0635\u064a\u062f\u0644|pharmac", re.IGNORECASE | re.UNICODE), "pharmacy"),
    (re.compile(r"\u062d\u0642\u0648\u0642|\u0642\u0627\u0646\u0648\u0646|\blaw\b", re.IGNORECASE | re.UNICODE), "law"),
    (re.compile(r"\u062a\u062c\u0627\u0631|commerce|business", re.IGNORECASE | re.UNICODE), "commerce"),
    (re.compile(r"\u0622\u062f\u0627\u0628|\u0627\u062f\u0627\u0628|\barts\b", re.IGNORECASE | re.UNICODE), "arts"),
    (re.compile(r"\u0639\u0644\u0648\u0645|science", re.IGNORECASE | re.UNICODE), "science"),
    (re.compile(r"\u062a\u0631\u0628\u064a|educat", re.IGNORECASE | re.UNICODE), "education"),
]

# Unambiguous prefix -> program (hard override, always wins)
_PREFIX_PROG_HARD: dict[str, str] = {
    # Computer science
    "BCS": "computer science", "MBS": "computer science",
    "ICI": "computer science", "SWE": "computer science",
    "CIS": "computer science", "CSC": "computer science",
    "INF": "computer science", "BIS": "computer science",
    "AIS": "computer science",
    # COM / CS / DS / MA / HU / PH / ENG — shared across programs,
    # resolved from filename at build time (NOT hard-coded here)
    # Medicine
    "MED": "medicine",         "NUR": "medicine",
    "OPH": "medicine",         "ENT": "medicine",
    # Dentistry
    "DBM": "dentistry",        "MGP": "dentistry",
    # Engineering
    "CVE": "engineering",      "MEC": "engineering",
    "ARE": "engineering",      "ELE": "engineering",
    # Pharmacy
    "PHR": "pharmacy",
    # Law
    "LAW": "law",
    # Commerce
    "ACC": "commerce",         "ECO": "commerce",
    "MGT": "commerce",
}

# Prefixes that are shared across programs — resolved from source filename
_SHARED_PREFIXES = {
    "GEN", "BAS",
    # These appear in multiple faculties — let filename decide
    "COM", "CS", "DS", "MA", "HU", "PH", "ENG",
    "IT", "SE", "AI", "IS",
}

# Shared prefixes — program resolved from source filename at build time
_SHARED_PREFIXES = {"GEN", "BAS"}

_SEED_AR: dict[str, str] = {
    "GEN001": "\u0627\u0644\u0644\u063a\u0629 \u0627\u0644\u0625\u0646\u062c\u0644\u064a\u0632\u064a\u0629 1",
    "GEN002": "\u0627\u0644\u0644\u063a\u0629 \u0627\u0644\u0625\u0646\u062c\u0644\u064a\u0632\u064a\u0629 2",
    "GEN003": "\u0627\u0644\u0644\u063a\u0629 \u0627\u0644\u0639\u0631\u0628\u064a\u0629",
    "GEN004": "\u0645\u0642\u062f\u0645\u0629 \u0641\u064a \u0627\u0644\u062d\u0627\u0633\u0628\u0627\u062a",
    "GEN101": "\u062a\u0642\u0631\u064a\u0631 \u0641\u0646\u064a",
    "GEN102": "\u0627\u0644\u0642\u0636\u0627\u064a\u0627 \u0627\u0644\u0645\u062c\u062a\u0645\u0639\u064a\u0629",
    "GEN103": "\u0635\u064a\u0627\u063a\u0629 \u0627\u0644\u062a\u0642\u0627\u0631\u064a\u0631 \u0627\u0644\u0641\u0646\u064a\u0629",
    "GEN104": "\u0645\u0628\u0627\u062f\u0626 \u0627\u0644\u0625\u062f\u0627\u0631\u0629",
    "BAS001": "\u0631\u064a\u0627\u0636\u064a\u0627\u062a 1",
    "BAS002": "\u0641\u064a\u0632\u064a\u0627\u0621 1",
    "BAS003": "\u0643\u064a\u0645\u064a\u0627\u0621 \u0639\u0627\u0645\u0629",
    "BAS004": "\u0631\u064a\u0627\u0636\u064a\u0627\u062a 2",
    "BAS005": "\u0641\u064a\u0632\u064a\u0627\u0621 2",
    "BAS006": "\u0643\u064a\u0645\u064a\u0627\u0621 \u0647\u0646\u062f\u0633\u064a\u0629",
    "BAS007": "\u062f\u064a\u0646\u0627\u0645\u064a\u0643\u0627",
    "BAS008": "\u0625\u062d\u0635\u0627\u0621 \u0648\u0627\u062d\u062a\u0645\u0627\u0644\u0627\u062a",
    "BAS108": "\u0645\u0639\u0627\u062f\u0644\u0627\u062a \u062a\u0641\u0627\u0636\u0644\u064a\u0629",
    "BCS111": "\u0628\u0631\u0645\u062c\u0629 \u062d\u0627\u0633\u0628\u0627\u062a 1",
    "BCS112": "\u0628\u0631\u0645\u062c\u0629 \u062d\u0627\u0633\u0628\u0627\u062a 2",
    "BCS113": "\u0627\u0644\u062a\u0635\u0645\u064a\u0645 \u0627\u0644\u0645\u0646\u0637\u0642\u064a",
    "BCS114": "\u0647\u064a\u0627\u0643\u0644 \u0627\u0644\u0628\u064a\u0627\u0646\u0627\u062a",
    "BCS211": "\u0642\u0648\u0627\u0639\u062f \u0627\u0644\u0628\u064a\u0627\u0646\u0627\u062a",
    "BCS212": "\u0634\u0628\u0643\u0627\u062a \u0627\u0644\u062d\u0627\u0633\u0628",
    "BCS213": "\u0623\u0646\u0638\u0645\u0629 \u0627\u0644\u062a\u0634\u063a\u064a\u0644",
    "BCS214": "\u0647\u0646\u062f\u0633\u0629 \u0627\u0644\u0628\u0631\u0645\u062c\u064a\u0627\u062a",
    "MBS106": "\u0631\u064a\u0627\u0636\u064a\u0627\u062a \u062a\u0642\u0633\u064a\u0645\u064a\u0629",
    "MBS108": "\u0645\u0628\u0627\u062f\u0626 \u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a\u0627\u062a",
    "MBS143": "\u0645\u0642\u062f\u0645\u0629 \u0641\u064a \u0627\u0644\u0630\u0643\u0627\u0621 \u0627\u0644\u0627\u0635\u0637\u0646\u0627\u0639\u064a",
    "ICI115": "\u0645\u0642\u062f\u0645\u0629 \u0641\u064a \u0639\u0644\u0648\u0645 \u0627\u0644\u0628\u064a\u0627\u0646\u0627\u062a",
}


# ─────────────────────────────────────────────────────────────────────────────
# Helper functions
# ─────────────────────────────────────────────────────────────────────────────

def _year_from_code_number(number: str) -> Optional[int]:
    try:
        n = int(number)
        if n < 200: return 1
        if n < 300: return 2
        if n < 400: return 3
        return 4
    except ValueError:
        return None


def _sem_from_code_number(number: str) -> Optional[int]:
    try:
        n = int(number)
        last = n % 10
        if last == 0:
            return None
        return 1 if last % 2 == 1 else 2
    except ValueError:
        return None


def _clean_title(raw: str) -> str:
    t = re.sub(r"[\u0640]+", " ", raw)
    t = re.sub(r"(\s+\d+){1,8}\s*$", "", t)
    t = re.sub(r"\s+[A-Z]{2,4}\s*\d{3,4}\s*$", "", t)
    t = re.sub(r"\s{2,}", " ", t).strip()
    t = re.sub(r"^[\d\W]+", "", t).strip()
    return t


def _detect_year(text: str) -> Optional[int]:
    for yr, pat in _YEAR_RE.items():
        if pat.search(text):
            return yr
    return None


def _detect_semester(text: str) -> Optional[int]:
    for sem, pat in _SEM_RE.items():
        if pat.search(text):
            return sem
    return None


def _detect_program_from_text(text: str) -> Optional[str]:
    for prog, pat in _PROG_RE.items():
        if pat.search(text):
            return prog
    return None


def _detect_program_from_fname(fname: str) -> Optional[str]:
    for pat, prog in _FNAME_PROG:
        if pat.search(fname):
            return prog
    return None


def _detect_credit_hours(row_text: str) -> Optional[int]:
    nums = re.findall(r"\b([1-6])\b", row_text)
    return int(nums[-1]) if nums else None


def _entry_priority(entry: dict) -> int:
    score = 0
    if entry.get("year"):         score += 4
    if entry.get("semester"):     score += 3
    if entry.get("program"):      score += 2
    if entry.get("title_ar"):     score += 2
    if entry.get("title_en"):     score += 1
    if entry.get("credit_hours"): score += 1
    if entry.get("prerequisite"): score += 1
    fname = (entry.get("source_file") or "").lower()
    if any(w in fname for w in [
        "\u062d\u0627\u0633\u0628", "computer",
        "\u0623\u0633\u0646\u0627\u0646", "dent",
        "\u0637\u0628", "med"
    ]):
        score += 3
    return score


# ─────────────────────────────────────────────────────────────────────────────
# CourseCatalog  (4-layer architecture)
# ─────────────────────────────────────────────────────────────────────────────

class CourseCatalog:
    """
    Layer 1 — Raw:        _parse_chunk()   -> self.courses (raw entries)
    Layer 2 — Normalized: _normalize()     -> fills None, enforces hard rules,
                                              pre-resolves GEN/BAS programs
    Layer 3 — Indexed:    _build_indexes() -> program_index, year_index,
                                              semester_index
    Layer 4 — Query:      query()          -> O(1) set intersection via indexes
    """

    def __init__(self, collection=None) -> None:
        self.collection = collection
        self.courses: dict[str, dict] = {}
        self._built = False
        self._normalized = False

        # Inverted indexes (Layer 3)
        self.program_index:  dict[str, set] = defaultdict(set)
        self.year_index:     dict[int, set] = defaultdict(set)
        self.semester_index: dict[int, set] = defaultdict(set)

    # ── Layer 1: Parse ────────────────────────────────────────────────────

    def _parse_chunk(self, text: str, meta: dict) -> None:
        fname = meta.get("fileName", "")
        page  = meta.get("page", 0)

        chunk_program = (
            _detect_program_from_fname(fname)
            or _detect_program_from_text(text)
        )
        chunk_year = _detect_year(text)
        chunk_sem  = _detect_semester(text)

        for m in _ROW_RE.finditer(text):
            prefix    = m.group(1).upper()
            number    = m.group(2)
            title_raw = m.group(3)
            code      = f"{prefix} {number}"
            code_key  = f"{prefix}{number}"
            title_en  = _clean_title(title_raw)

            if not title_en or len(title_en) < 3:
                continue

            after_title = text[m.end():][:60]
            prereq_m    = _CODE_RE.search(after_title)
            prereq      = (
                f"{prereq_m.group(1).upper()} {prereq_m.group(2)}"
                if prereq_m else None
            )
            credit = _detect_credit_hours(m.group(0))

            title_ar = _SEED_AR.get(code_key, "")
            if not title_ar:
                ar_chars = len(re.findall(r"[\u0600-\u06FF]", title_en))
                if ar_chars > len(title_en) * 0.3:
                    title_ar, title_en = title_en, ""

            # Hard prefix wins; shared prefix uses chunk context
            hard_prog = _PREFIX_PROG_HARD.get(prefix)
            if hard_prog:
                prog = hard_prog
            elif prefix in _SHARED_PREFIXES:
                prog = chunk_program   # resolved from filename/text
            else:
                prog = chunk_program

            # Year: code-number is authoritative (1xx=yr1, 2xx=yr2, …)
            # chunk_year is only used as fallback when code number is ambiguous
            code_yr = _year_from_code_number(number)
            yr = code_yr if code_yr is not None else chunk_year

            # Semester: code-number last digit is authoritative
            code_sem = _sem_from_code_number(number)
            sem = code_sem if code_sem is not None else chunk_sem

            entry = {
                "code":         code,
                "title_en":     title_en,
                "title_ar":     title_ar,
                "prerequisite": prereq,
                "credit_hours": credit,
                "year":         yr,
                "semester":     sem,
                "program":      prog,
                "source_file":  fname,
                "source_page":  page,
            }

            if code not in self.courses:
                self.courses[code] = entry
            elif _entry_priority(entry) > _entry_priority(self.courses[code]):
                self.courses[code] = entry

    # ── Layer 2: Normalize ────────────────────────────────────────────────

    def _normalize(self) -> None:
        """
        Fill remaining None fields, enforce hard rules, pre-resolve shared
        courses. After this pass every entry has a non-None program.
        """
        for code, entry in self.courses.items():
            parts        = code.split()
            prefix_upper = parts[0].upper() if parts else code[:3].upper()
            number       = parts[1] if len(parts) > 1 else code[len(prefix_upper):]

            # Hard override — always wins
            hard = _PREFIX_PROG_HARD.get(prefix_upper)
            if hard:
                entry["program"] = hard

            # Shared prefix (GEN/BAS) — resolve from source file
            elif prefix_upper in _SHARED_PREFIXES:
                if not entry.get("program"):
                    fname_prog = _detect_program_from_fname(
                        (entry.get("source_file") or "").lower()
                    )
                    entry["program"] = fname_prog or "computer science"

            # Unknown prefix with no program
            elif not entry.get("program"):
                fname_prog = _detect_program_from_fname(
                    (entry.get("source_file") or "").lower()
                )
                entry["program"] = fname_prog or "computer science"

            # Fix "science" false positive
            if entry.get("program") == "science":
                fname_prog = _detect_program_from_fname(
                    (entry.get("source_file") or "").lower()
                )
                if fname_prog:
                    entry["program"] = fname_prog
                elif prefix_upper in {"GEN", "BAS", "BCS", "MBS", "ICI"}:
                    entry["program"] = "computer science"

            # Fill year — code number is authoritative
            if not entry.get("year"):
                entry["year"] = _year_from_code_number(number)

            # Fill semester — code number last digit is authoritative
            if not entry.get("semester"):
                entry["semester"] = _sem_from_code_number(number)

            # Fill Arabic title from seed dict
            if not entry.get("title_ar"):
                entry["title_ar"] = _SEED_AR.get(f"{prefix_upper}{number}", "")

        logger.info(
            "[catalog] Normalized. Programs: %s",
            {e.get("program") for e in self.courses.values()},
        )

    # ── Layer 3: Build indexes ────────────────────────────────────────────

    def _build_indexes(self) -> None:
        """
        Build inverted indexes from the normalized courses dict.
        Called once after _normalize(). query() uses these for O(1) lookup.
        """
        self.program_index.clear()
        self.year_index.clear()
        self.semester_index.clear()

        for code, entry in self.courses.items():
            prog = entry.get("program")
            yr   = entry.get("year")
            sem  = entry.get("semester")

            if prog: self.program_index[prog].add(code)
            if yr:   self.year_index[yr].add(code)
            if sem:  self.semester_index[sem].add(code)

        logger.info(
            "[catalog] Indexes built. Programs=%s | Years=%s | Sems=%s",
            {k: len(v) for k, v in self.program_index.items()},
            {k: len(v) for k, v in self.year_index.items()},
            {k: len(v) for k, v in self.semester_index.items()},
        )

    # ── Build pipeline ────────────────────────────────────────────────────

    def build(self) -> int:
        """
        Guaranteed order:
          1. Reset
          2. Load from ChromaDB
          3. _parse_chunk() x N  (Layer 1)
          4. _normalize()        (Layer 2)
          5. _build_indexes()    (Layer 3)
          6. _validate()
          7. Mark ready
        """
        # Step 1: Reset
        self.courses = {}
        self._built = False
        self._normalized = False
        self.program_index.clear()
        self.year_index.clear()
        self.semester_index.clear()

        if self.collection is None:
            logger.warning("[catalog] No collection provided")
            return 0

        # Step 2: Load
        try:
            data      = self.collection.get(include=["documents", "metadatas"])
            texts     = data.get("documents") or []
            metadatas = data.get("metadatas") or []
        except Exception as e:
            logger.error("[catalog] ChromaDB fetch failed: %s", e)
            return 0

        # Step 3: Parse
        for text, meta in zip(texts, metadatas):
            if text:
                self._parse_chunk(text, meta)

        # Step 4: Normalize
        self._normalize()

        # Step 5: Build indexes
        self._build_indexes()
        self._normalized = True

        # Step 6: Validate
        issues = self._validate()
        if issues:
            logger.warning("[catalog] Validation issues: %s", issues)

        # Step 7: Mark ready
        self._built = True
        logger.info(
            "[catalog] Ready: %d courses | years=%s | sems=%s",
            len(self.courses),
            sorted(self.year_index.keys()),
            sorted(self.semester_index.keys()),
        )
        return len(self.courses)

    def _validate(self) -> list:
        issues = []
        total     = len(self.courses)
        none_year = sum(1 for e in self.courses.values() if not e.get("year"))
        none_prog = sum(1 for e in self.courses.values() if not e.get("program"))

        if total > 0 and none_year > total * 0.5:
            issues.append(f"{none_year}/{total} entries have year=None (>50%)")
        if none_prog > 0:
            issues.append(f"{none_prog}/{total} entries have program=None")

        for code, e in self.courses.items():
            prefix = code.split()[0].upper() if " " in code else code[:3].upper()
            hard   = _PREFIX_PROG_HARD.get(prefix)
            prog   = e.get("program")
            if hard and prog and hard != prog:
                issues.append(
                    f"Cross-contamination: {code} prog={prog} should={hard}"
                )
        return issues

    def _is_fully_normalized(self) -> bool:
        return self._built and self._normalized

    # ── Layer 4: Query ────────────────────────────────────────────────────

    def query(
        self,
        year:     Optional[int] = None,
        semester: Optional[int] = None,
        program:  Optional[str] = None,
        file:     Optional[str] = None,
        debug:    bool = False,
    ) -> list:
        """
        Query using inverted indexes (O(1) set intersection).

        Parameters
        ----------
        debug : bool
            If True, returns dict {"results": [...], "excluded": [...]}
            where each excluded entry explains why it was dropped.
        """
        if not self._is_fully_normalized():
            raise RuntimeError(
                "query() called before build(). Call catalog.build() first."
            )

        # Set intersection using indexes
        candidate_codes: Optional[set] = None

        if program is not None:
            prog_codes = self.program_index.get(program, set())
            candidate_codes = (
                prog_codes if candidate_codes is None
                else candidate_codes & prog_codes
            )

        if year is not None:
            yr_codes = self.year_index.get(year, set())
            candidate_codes = (
                yr_codes if candidate_codes is None
                else candidate_codes & yr_codes
            )

        if semester is not None:
            sem_codes = self.semester_index.get(semester, set())
            candidate_codes = (
                sem_codes if candidate_codes is None
                else candidate_codes & sem_codes
            )

        # No filter applied -> use all codes
        if candidate_codes is None:
            candidate_codes = set(self.courses.keys())

        # File filter (not indexed — substring scan on candidates only)
        results:  list = []
        excluded: list = []

        for code in candidate_codes:
            entry = self.courses.get(code)
            if not entry:
                continue

            if file is not None:
                if file.lower() not in (entry.get("source_file") or "").lower():
                    if debug:
                        excluded.append({**entry, "_reason": f"file filter: {file}"})
                    continue

            results.append(entry)

        logger.debug(
            "[catalog] query(year=%s, sem=%s, prog=%s) -> %d results from %d candidates",
            year, semester, program, len(results), len(candidate_codes),
        )

        sorted_results = sorted(results, key=lambda e: (
            e.get("year")     or 99,
            e.get("semester") or 99,
            e.get("code")     or "",
        ))

        if debug:
            all_codes     = set(self.courses.keys())
            non_candidates = all_codes - candidate_codes
            for code in list(non_candidates)[:50]:
                entry   = self.courses.get(code, {})
                reasons = []
                if program and entry.get("program") != program:
                    reasons.append(f"program={entry.get('program')} != {program}")
                if year and entry.get("year") != year:
                    reasons.append(f"year={entry.get('year')} != {year}")
                if semester and entry.get("semester") != semester:
                    reasons.append(f"semester={entry.get('semester')} != {semester}")
                excluded.append({**entry, "_reason": " | ".join(reasons)})
            return {"results": sorted_results, "excluded": excluded}

        return sorted_results

    # ── Convenience API ───────────────────────────────────────────────────

    def get(self, code: str) -> Optional[dict]:
        key = code.upper().replace("-", " ")
        m = re.match(r"([A-Z]{2,4})(\d{3,4})", key)
        if m:
            key = f"{m.group(1)} {m.group(2)}"
        return self.courses.get(key)

    def get_title(self, code: str, prefer_arabic: bool = True) -> str:
        entry = self.get(code)
        if not entry:
            return code
        if prefer_arabic and entry.get("title_ar"):
            return entry["title_ar"]
        return entry.get("title_en") or entry.get("title_ar") or code

    def summary(self) -> dict:
        return {
            "total_courses": len(self.courses),
            "by_program":    {k: len(v) for k, v in self.program_index.items()},
            "by_year":       {k: len(v) for k, v in self.year_index.items()},
            "by_semester":   {k: len(v) for k, v in self.semester_index.items()},
        }

    @property
    def is_built(self) -> bool:
        return self._is_fully_normalized()


# ─────────────────────────────────────────────────────────────────────────────
# Module-level singleton
# ─────────────────────────────────────────────────────────────────────────────

_catalog_instance: Optional[CourseCatalog] = None


def get_catalog(collection=None, force_rebuild: bool = False) -> CourseCatalog:
    global _catalog_instance
    if _catalog_instance is None or force_rebuild:
        _catalog_instance = CourseCatalog(collection)
        if collection is not None:
            _catalog_instance.build()
    return _catalog_instance
