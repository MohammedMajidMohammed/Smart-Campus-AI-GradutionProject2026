import json
import os

with open("scratch/extracted_contexts.json", "r", encoding="utf-8") as f:
    data = json.load(f)

output_lines = []
for idx in range(5, 10):
    item = data[idx]
    output_lines.append("=" * 100)
    output_lines.append(f"QUESTION {item['index']}: {item['question']}")
    output_lines.append("SOURCES:")
    for i, doc in enumerate(item['sources']):
        meta = doc.get('metadata', {})
        output_lines.append(f"[{i+1}] File: {meta.get('fileName')}, Page: {meta.get('page')}, Section: {meta.get('sectionTitle')}")
        output_lines.append(f"Content: {doc.get('text')}")
        output_lines.append("-" * 50)
    output_lines.append("\n")

with open("scratch/q6_q10_contexts.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(output_lines))
print("Saved to scratch/q6_q10_contexts.txt")
