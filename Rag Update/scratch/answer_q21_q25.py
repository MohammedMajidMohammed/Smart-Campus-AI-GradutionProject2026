import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

with open("scratch/extracted_contexts.json", "r", encoding="utf-8") as f:
    data = json.load(f)

# Print questions 21 to 25 contexts (indices 20 to 24)
for idx in range(20, 25):
    item = data[idx]
    print("=" * 80)
    print(f"QUESTION {item['index']}: {item['question']}")
    print("SOURCES:")
    for doc in item['sources']:
        meta = doc.get('metadata', {})
        print(f"- File: {meta.get('fileName')}, Page: {meta.get('page')}, Section: {meta.get('sectionTitle')}")
        print(f"  Content: {doc.get('text')}")
        print("-" * 40)
