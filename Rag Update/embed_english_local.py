"""
embed_english_local.py
======================
يخزّن ملف اللغة الإنجليزية في ChromaDB باستخدام local embeddings (بدون API).
Model: paraphrase-multilingual-mpnet-base-v2 (يدعم العربية والإنجليزية)

الاستخدام:
    venv/Scripts/python.exe embed_english_local.py
"""
import json
import sys
import os
from pathlib import Path

# ── Setup ─────────────────────────────────────────────────────────────────────
os.chdir(Path(__file__).parent)
sys.path.insert(0, str(Path(__file__).parent))

from dotenv import load_dotenv
load_dotenv()

import chromadb
from chromadb.config import Settings
from routes.pdf_processor import extract_and_structure_pdf, structured_doc_to_chunks

TARGET_PDF = "لائحه برنامج اللغة الإنجليزية و الترجمة التخصصية.pdf"
PDF_PATH   = Path("files") / TARGET_PDF
COLLECTION = "university_regulations"
JSON_DIR   = Path("processed_pdfs")
JSON_DIR.mkdir(exist_ok=True)

# ── Load sentence-transformers ────────────────────────────────────────────────
print("Loading local embedding model...")
print("(First run downloads ~420MB — subsequent runs use cache)")
from sentence_transformers import SentenceTransformer

# paraphrase-multilingual-mpnet-base-v2: best multilingual model for Arabic+English
# Produces 768-dim embeddings, same as text-embedding-ada-002 (1536-dim)
# ChromaDB handles different dimensions per collection fine
MODEL_NAME = "paraphrase-multilingual-MiniLM-L12-v2"  # 384-dim, matches existing collection
model = SentenceTransformer(MODEL_NAME)
print(f"Model loaded: {MODEL_NAME}")

# ── ChromaDB ──────────────────────────────────────────────────────────────────
chroma = chromadb.PersistentClient(
    path="./chroma_db",
    settings=Settings(anonymized_telemetry=False)
)

# IMPORTANT: get existing collection (don't recreate — keeps other files intact)
col = chroma.get_or_create_collection(
    name=COLLECTION,
    metadata={"description": "University regulations PDFs and CSV Q&A"}
)
print(f"ChromaDB: {col.count()} chunks total before update")

# ── Delete old chunks for this file ──────────────────────────────────────────
print(f"\nChecking for old chunks of '{TARGET_PDF}'...")
all_data = col.get(include=["metadatas"])
old_ids = [
    all_data["ids"][i]
    for i, m in enumerate(all_data["metadatas"])
    if m.get("fileName") == TARGET_PDF
]
if old_ids:
    print(f"Deleting {len(old_ids)} old chunks...")
    BATCH = 500
    for i in range(0, len(old_ids), BATCH):
        col.delete(ids=old_ids[i:i+BATCH])
    print(f"Deleted {len(old_ids)} old chunks")
else:
    print("No old chunks found")

# ── Extract text ──────────────────────────────────────────────────────────────
print(f"\nExtracting text from '{TARGET_PDF}'...")
with open(PDF_PATH, "rb") as f:
    pdf_bytes = f.read()

structured_doc = extract_and_structure_pdf(
    pdf_bytes=pdf_bytes,
    filename=TARGET_PDF,
    force_ocr=False,   # native+tables is sufficient (58k chars already extracted)
)

total_chars = structured_doc["metadata"]["total_chars"]
total_pages = structured_doc["total_pages"]
method      = structured_doc["extraction_method"]
has_tables  = structured_doc["metadata"].get("has_tables", False)
print(f"Extracted: {total_pages} pages | {total_chars} chars | {method} | tables={has_tables}")

# Save JSON
json_path = JSON_DIR / f"{TARGET_PDF}.json"
with open(json_path, "w", encoding="utf-8") as jf:
    json.dump(structured_doc, jf, ensure_ascii=False, indent=2)
print(f"JSON saved: {json_path}")

# ── Chunk ─────────────────────────────────────────────────────────────────────
print("\nChunking...")
chunks, metadatas = structured_doc_to_chunks(structured_doc)
print(f"{len(chunks)} chunks created (avg {int(sum(len(c) for c in chunks)/max(len(chunks),1))} chars)")

# ── Embed locally ─────────────────────────────────────────────────────────────
print(f"\nGenerating local embeddings for {len(chunks)} chunks...")
print("(This may take 1-3 minutes on CPU)")

EMBED_BATCH = 32
all_embeddings = []
for i in range(0, len(chunks), EMBED_BATCH):
    batch = chunks[i:i+EMBED_BATCH]
    vecs  = model.encode(batch, show_progress_bar=False, normalize_embeddings=True)
    all_embeddings.extend(vecs.tolist())
    done = min(i+EMBED_BATCH, len(chunks))
    print(f"  Embedded {done}/{len(chunks)} chunks", end="\r")

print(f"\nEmbeddings done: {len(all_embeddings)} vectors of dim {len(all_embeddings[0])}")

# ── Store in ChromaDB ─────────────────────────────────────────────────────────
print("\nStoring in ChromaDB...")
ids = [m.get("chunkId") or f"{TARGET_PDF}-{i}" for i, m in enumerate(metadatas)]

STORE_BATCH = 200
for i in range(0, len(chunks), STORE_BATCH):
    end = min(i+STORE_BATCH, len(chunks))
    col.upsert(
        ids        = ids[i:end],
        embeddings = all_embeddings[i:end],
        documents  = chunks[i:end],
        metadatas  = metadatas[i:end],
    )
    print(f"  Stored batch {i//STORE_BATCH+1}: {end-i} chunks")

print(f"\nChromaDB now: {col.count()} chunks total")

# ── Verify ────────────────────────────────────────────────────────────────────
all_data2 = col.get(include=["metadatas"])
new_chunks = [m for m in all_data2["metadatas"] if m.get("fileName") == TARGET_PDF]
print(f"Verified: {len(new_chunks)} chunks for '{TARGET_PDF}'")

if new_chunks:
    sample = new_chunks[0]
    print(f"Sample metadata: program={sample.get('program')}, "
          f"page={sample.get('page')}, "
          f"hasTables={sample.get('hasTables')}, "
          f"method={sample.get('extractionMethod')}")
    print("\nDone! Restart the server and test again.")
else:
    print("ERROR: chunks not found after upsert!")
    sys.exit(1)
