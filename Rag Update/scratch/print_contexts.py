import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

with open("scratch/extracted_contexts.json", "r", encoding="utf-8") as f:
    data = json.load(f)

# Print questions 1 to 5 contexts
for idx in range(0, 5):
    item = data[idx]
    print("=" * 80)
    print(f"QUESTION {item['index']}: {item['question']}")
    print("SOURCES:")
    for doc in item['sources']:
        meta = doc.get('metadata', {})
        print(f"- File: {meta.get('fileName')}, Page: {meta.get('page')}, Section: {meta.get('sectionTitle')}")
        print(f"  Content: {doc.get('text')}")
        print("-" * 40)
