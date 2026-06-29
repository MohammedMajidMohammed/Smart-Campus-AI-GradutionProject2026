import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

with open("scratch/extracted_contexts.json", "r", encoding="utf-8") as f:
    data = json.load(f)

for idx in range(25, 30):
    item = data[idx]
    print("=" * 80)
    print(f"Q{idx+1}: {item['question']}")
    for s_idx, src in enumerate(item['sources']):
        meta = src.get('metadata', {})
        print(f"Source {s_idx+1} [{meta.get('fileName')} P.{meta.get('page')} Sec: {meta.get('sectionTitle')}]:")
        print(src.get('text', ''))
        print("-" * 50)
