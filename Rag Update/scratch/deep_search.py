import os
import json

root = r'c:\Users\Right Click\Downloads'
target_keywords = ['تمريض', 'علاج', 'حاسب']

found = []
for r, d, fs in os.walk(root):
    for f in fs:
        if f.endswith('.json'):
            path = os.path.join(r, f)
            try:
                with open(path, 'r', encoding='utf-8', errors='ignore') as fh:
                    content = fh.read()
                    if any(k in content for k in target_keywords):
                        found.append(path)
            except:
                continue

with open('deep_search_results.txt', 'w', encoding='utf-8') as out:
    out.write('\n'.join(found))
