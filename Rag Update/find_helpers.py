with open("routes/retrieval/hybrid_search.py", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "def _apply_program_isolation" in line or "def _table_boost" in line or "def _boost_and_filter" in line or "def _fallback_retrieve" in line:
        print(f"Line {i+1}: {line.strip()}")
