
import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open("regulations_test_report.json", "r", encoding="utf-8") as f:
    report = json.load(f)

for r in report:
    print(f"Faculty: {r['faculty']}")
    print(f"Query: {r['query']}")
    print(f"Status: {r['status']}")
    print(f"Valid: {r['answer_valid']}")
    print(f"Sources: {r['sources']}")
    print("-" * 30)
