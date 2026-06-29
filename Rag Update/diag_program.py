"""Quick diagnostic: trace exactly what _detect_program returns for dentistry queries."""
import sys, io, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

sys.path.insert(0, '.')
from routes.retrieval.query_understanding import _detect_program, _normalize_ar, _PROGRAM_LOOKUP, understand_query

# Test dentistry queries
test_queries = [
    "ما شروط التخرج في طب الاسنان؟",
    "طب الاسنان",
    "طب أسنان",
    "ما هي لائحة كلية الطب؟",
    "كلية الطب",
]

print("=== _PROGRAM_LOOKUP keys for dentistry ===")
for k, v in _PROGRAM_LOOKUP.items():
    if v == "dentistry":
        print(f"  '{k}' -> dentistry")

print("\n=== _PROGRAM_LOOKUP keys for medicine ===")
for k, v in _PROGRAM_LOOKUP.items():
    if v == "medicine":
        print(f"  '{k}' -> medicine")

print("\n=== Testing _detect_program ===")
for q in test_queries:
    import re
    tokens_ar = re.findall(r"[\u0600-\u06FF]+", q)
    print(f"\nQuery: '{q}'")
    print(f"  tokens_ar = {tokens_ar}")
    # show phrase normalization
    for phrase_len in (4, 3, 2):
        for i in range(len(tokens_ar) - phrase_len + 1):
            phrase = _normalize_ar(" ".join(tokens_ar[i:i + phrase_len]))
            hit = _PROGRAM_LOOKUP.get(phrase)
            if hit:
                print(f"  PHRASE MATCH ({phrase_len}w): '{phrase}' -> {hit}")
    result = _detect_program(q, "")
    print(f"  _detect_program result: {result}")

print("\n=== Testing understand_query ===")
for q in test_queries:
    intent = understand_query(q)
    print(f"'{q[:40]}' -> program={intent.program}, intent={intent.intent}")
