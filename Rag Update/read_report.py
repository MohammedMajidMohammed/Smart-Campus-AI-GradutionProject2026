
import json
import sys
import io
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open("regulations_test_report.json", "r", encoding="utf-8") as f:
    report = json.load(f)

for item in report:
    fac = item.get('faculty')
    if "العلاج الطبيعي" in fac or "الطب البشري" in fac:
        print(f"\n==================================================")
        print(f"FACULTY: {fac}")
        print(f"QUERY: {item.get('query')}")
        print(f"STATUS: {item.get('status')}")
        print(f"ANSWER VALID: {item.get('answer_valid')}")
        print(f"ANSWER:")
        print(item.get('answer'))
