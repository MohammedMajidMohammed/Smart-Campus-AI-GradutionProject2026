import json
import sys
from pathlib import Path
from routes.pdf_processor import structured_doc_to_chunks

sys.stdout.reconfigure(encoding="utf-8")

json_path = Path("processed_pdfs/Guide to the programs of the Faculty of Computer Science and Artificial Intelligence, Menoufia National University.pdf.json")
with open(json_path, "r", encoding="utf-8") as f:
    data = json.load(f)

filename = data.get('filename', json_path.name)
pages = data.get('pages', [])

structured_doc = {
    "filename": filename,
    "total_pages": len(pages),
    "pages": pages,
    "full_text": "\n\n".join([p.get('text', '') for p in pages]),
    "metadata": data.get("metadata", {})
}

chunks, metadatas = structured_doc_to_chunks(structured_doc)
print(f"Generated {len(chunks)} chunks.")

pages_in_chunks = sorted(list(set(m.get("page") for m in metadatas if m.get("page") is not None)))
print(f"Pages in generated chunks: {pages_in_chunks}")

# Let's find exactly which chunk contains the text "التدريب العملي والميداني" on page 24
for idx, (chunk, meta) in enumerate(zip(chunks, metadatas)):
    if "التدريب العملي والميداني" in chunk and "87" in chunk:
        print(f"\nMatch Chunk Index: {idx}")
        print(f"Metadata: {meta}")
        print(f"Snippet: {chunk[:400]}")
