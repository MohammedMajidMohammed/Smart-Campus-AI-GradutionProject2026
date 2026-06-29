"""Quick smoke-test for the clean v3 CourseCatalog."""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))

from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))

import chromadb
from chromadb.config import Settings
from routes.course_catalog import CourseCatalog

chroma = chromadb.PersistentClient(
    path="chroma_db",
    settings=Settings(anonymized_telemetry=False),
)
try:
    col = chroma.get_collection("university_regulations")
    print(f"Collection count: {col.count()}")
except Exception as e:
    print(f"Collection error: {e}")
    sys.exit(1)

cat = CourseCatalog(col)
n = cat.build()
print(f"Built: {n} courses")
print("Summary:", cat.summary())

# ── Test 1: guard before build ────────────────────────────────────────────────
cat2 = CourseCatalog()
try:
    cat2.query()
    print("FAIL guard - should have raised RuntimeError")
except RuntimeError as e:
    print(f"\nGuard OK: {e}")

# ── Test 2: CS year 1 ─────────────────────────────────────────────────────────
r1 = cat.query(program="computer science", year=1)
print(f"\nTest 2 - CS year 1: {len(r1)} courses")
for c in r1[:8]:
    title = c.get("title_ar") or c.get("title_en") or ""
    print(f"  {c['code']:12s} yr={c['year']} sem={c['semester']}  {title}")

# ── Test 3: CS year 1 sem 1 ───────────────────────────────────────────────────
r3 = cat.query(program="computer science", year=1, semester=1)
print(f"\nTest 3 - CS yr1 sem1: {len(r3)} courses")
for c in r3:
    title = c.get("title_ar") or c.get("title_en") or ""
    print(f"  {c['code']:12s} yr={c['year']} sem={c['semester']}  {title}")

# ── Test 4: cross-contamination check ────────────────────────────────────────
BAD_PREFIXES = {"CVE", "MEC", "ARE", "MED", "NUR", "OPH", "ENT", "DBM", "MGP"}
bad = [
    c for c in cat.query(program="computer science")
    if c["code"].split()[0].upper() in BAD_PREFIXES
]
print(f"\nTest 4 - Cross-contamination in CS: {len(bad)} (should be 0)")
for c in bad:
    print(f"  BAD: {c['code']}  prog={c['program']}")

# ── Test 5: engineering has no CS-only prefixes ───────────────────────────────
CS_ONLY = {"BCS", "MBS", "ICI", "SWE"}
bad_eng = [
    c for c in cat.query(program="engineering")
    if c["code"].split()[0].upper() in CS_ONLY
]
print(f"\nTest 5 - CS prefixes in engineering: {len(bad_eng)} (should be 0)")
for c in bad_eng:
    print(f"  BAD: {c['code']}  prog={c['program']}")

# ── Test 6: debug mode ────────────────────────────────────────────────────────
dbg = cat.query(program="computer science", year=1, debug=True)
print(f"\nTest 6 - debug mode: {len(dbg['results'])} results, {len(dbg['excluded'])} excluded")

print("\nAll tests done.")
