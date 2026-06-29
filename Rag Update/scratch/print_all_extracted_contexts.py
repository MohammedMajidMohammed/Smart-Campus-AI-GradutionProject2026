import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

with open("scratch/extracted_contexts.json", "r", encoding="utf-8") as f:
    data = json.load(f)

for idx, item in enumerate(data):
    print("=" * 80)
    print(f"Q{idx+1}: {item['question']}")
    print(f"Answer Context:")
    for src in item['sources']:
        text = src.get('text', '').strip()
        meta = src.get('metadata', {})
        print(f"  [{meta.get('fileName')} P.{meta.get('page')}]: {text[:300]}...")
