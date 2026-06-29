with open("routes/retrieval/hybrid_search.py", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "program" in line or "where_filter" in line or "where =" in line:
        if "logger" not in line and "print" not in line:
            print(f"Line {i+1}: {line.strip()}")
