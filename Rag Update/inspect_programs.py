
import sys, io, json
from chat_cli import RAGSession

session = RAGSession()
metas = session.collection.get(include=["metadatas"])["metadatas"]

program_files = {}
for m in metas:
    if m:
        prog = m.get("program")
        fname = m.get("fileName")
        if prog not in program_files:
            program_files[prog] = set()
        program_files[prog].add(fname)

# Convert sets to sorted lists for JSON serialization
out = {prog: sorted(list(files)) for prog, files in program_files.items()}

with open("program_files.json", "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False, indent=2)

print("Done. Saved to program_files.json.")
