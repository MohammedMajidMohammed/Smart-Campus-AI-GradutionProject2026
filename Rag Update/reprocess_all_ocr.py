"""
reprocess_all_ocr.py
====================
Reprocess ALL PDFs in files/ with force-OCR + local embeddings.
- Deletes old chunks per file before re-adding
- Uses Tesseract OCR on every page (ignores broken native text)
- Uses local sentence-transformers (no API needed)
- Applies program tags automatically

Usage:
    venv/Scripts/python.exe reprocess_all_ocr.py
    venv/Scripts/python.exe reprocess_all_ocr.py --skip-existing   # skip already-processed files
"""

import argparse
import json
import os
import sys
from pathlib import Path

os.chdir(Path(__file__).parent)
sys.path.insert(0, str(Path(__file__).parent))

from dotenv import load_dotenv
load_dotenv()

# ── Sentence-transformers (local, no API) ─────────────────────────────────────
print("Loading local embedding model...")
from sentence_transformers import SentenceTransformer
MODEL_NAME = "paraphrase-multilingual-MiniLM-L12-v2"   # 384-dim, matches DB
model = SentenceTransformer(MODEL_NAME)
print(f"Model ready: {MODEL_NAME}\n")

# ── ChromaDB ──────────────────────────────────────────────────────────────────
import chromadb
from chromadb.config import Settings

COLLECTION_NAME = "university_regulations"
chroma = chromadb.PersistentClient(
    path="./chroma_db",
    settings=Settings(anonymized_telemetry=False)
)
col = chroma.get_or_create_collection(
    name=COLLECTION_NAME,
    metadata={"description": "University regulations PDFs and CSV Q&A"}
)
print(f"ChromaDB: {col.count()} chunks before processing\n")

# ── PDF processor ─────────────────────────────────────────────────────────────
from routes.pdf_processor import extract_and_structure_pdf, structured_doc_to_chunks

# ── Program detection (same logic as retag_chunks.py) ────────────────────────
_FNAME_PROG_MAP = [
    (["علاج طبيعي", "علاج_طبيعي", "physical therapy", "physio"], "physical therapy"),
    (["طب بيطري", "بيطري", "veterinary", "veterinar", "bitar"], "veterinary"),
    (["طب أسنان", "أسنان", "اسنان", "dentistry", "dent", "فم والاسنان", "الفم"], "dentistry"),
    (["طب وجراحه", "طب_وجراحه", "وجراحه"], "medicine"),
    (["طب", "medicine", "medical", "mbbs"], "medicine"),
    (["صيدلة", "صيدله", "pharmacy", "pharm"], "pharmacy"),
    (["تمريض", "nursing", "nurse"], "nursing"),
    (["هندسة", "هندسه", "engineering", "eng"], "engineering"),
    (["حاسبات", "حاسوب", "computer", "cs", "it", "fci", "bcs", "ذكاء"], "computer science"),
    (["إدارة", "ادارة", "أعمال", "business", "management", "bba", "mgt"], "business"),
    (["ألسن", "السن", "لغات", "اللغة", "الترجمة", "languages", "english", "translation", "arts", "humanities", "آداب", "اداب", "فنون"], "arts"),
    (["حقوق", "قانون", "law"], "law"),
    (["علوم", "science", "sci"], "science"),
    (["زراعة", "زراعه", "agriculture", "agri"], "agriculture"),
    (["تربية", "تربيه", "education", "edu"], "education"),
    (["اقتصاد", "economics", "political science", "eco"], "economics"),
    (["إعلام", "اعلام", "mass communication", "media"], "mass communication"),
    (["سياحة", "سياحه", "فنادق", "tourism", "hotels"], "tourism"),
    (["آثار", "اثار", "archaeology"], "archaeology"),
]

_GENERAL_KEYWORDS = ["لائحة الجامعة", "لائحه جامعة", "student guide", "دليل الطالب"]


def detect_program(fname):
    fl = fname.lower()
    if any(kw.lower() in fl for kw in _GENERAL_KEYWORDS):
        return "general"
    for keywords, prog in _FNAME_PROG_MAP:
        if any(kw in fl for kw in keywords):
            return prog
    return "general"


# ── Helpers ───────────────────────────────────────────────────────────────────

def delete_file_chunks(filename):
    all_data = col.get(include=["metadatas"])
    old_ids = [
        all_data["ids"][i]
        for i, m in enumerate(all_data["metadatas"])
        if m.get("fileName") == filename
    ]
    if old_ids:
        BATCH = 500
        for i in range(0, len(old_ids), BATCH):
            col.delete(ids=old_ids[i:i+BATCH])
        print(f"  Deleted {len(old_ids)} old chunks")
    return len(old_ids)


def embed_and_store(chunks, metadatas, filename):
    EMBED_BATCH = 32
    all_embeddings = []
    for i in range(0, len(chunks), EMBED_BATCH):
        batch = chunks[i:i+EMBED_BATCH]
        vecs  = model.encode(batch, show_progress_bar=False, normalize_embeddings=True)
        all_embeddings.extend(vecs.tolist())
        done = min(i+EMBED_BATCH, len(chunks))
        print(f"  Embedding: {done}/{len(chunks)}", end="\r")
    print()

    ids = [m.get("chunkId") or f"{filename}-{i}" for i, m in enumerate(metadatas)]
    STORE_BATCH = 200
    for i in range(0, len(chunks), STORE_BATCH):
        end = min(i+STORE_BATCH, len(chunks))
        col.upsert(
            ids        = ids[i:end],
            embeddings = all_embeddings[i:end],
            documents  = chunks[i:end],
            metadatas  = metadatas[i:end],
        )
    return len(chunks)


def process_pdf(pdf_path, json_dir, skip_existing=False):
    filename = pdf_path.name
    program  = detect_program(filename)

    print(f"\n{'='*60}")
    print(f"  File   : {filename}")
    print(f"  Program: {program}")
    print(f"{'='*60}")

    # Check if already processed (has chunks in DB)
    if skip_existing:
        all_data = col.get(include=["metadatas"])
        existing = [m for m in all_data["metadatas"] if m.get("fileName") == filename]
        if existing:
            print(f"  SKIP: already has {len(existing)} chunks in DB")
            return {"filename": filename, "skipped": True, "chunks": len(existing)}

    # Delete old chunks
    delete_file_chunks(filename)

    # Extract with force-OCR
    print("  Extracting (force-OCR on all pages)...")
    with open(pdf_path, "rb") as f:
        pdf_bytes = f.read()

    structured_doc = extract_and_structure_pdf(
        pdf_bytes=pdf_bytes,
        filename=filename,
        force_ocr=True,
    )

    total_chars = structured_doc["metadata"]["total_chars"]
    total_pages = structured_doc["total_pages"]
    method      = structured_doc["extraction_method"]
    has_tables  = structured_doc["metadata"].get("has_tables", False)

    print(f"  Extracted: {total_pages} pages | {total_chars:,} chars | {method} | tables={has_tables}")

    if total_chars < 50:
        print("  WARNING: Very little text extracted — check Tesseract installation")
        return {"filename": filename, "success": False, "error": "too little text"}

    # Save JSON
    json_path = json_dir / f"{filename}.json"
    with open(json_path, "w", encoding="utf-8") as jf:
        json.dump(structured_doc, jf, ensure_ascii=False, indent=2)
    print(f"  JSON saved: {json_path.name}")

    # Chunk
    chunks, metadatas = structured_doc_to_chunks(structured_doc)
    print(f"  Chunks: {len(chunks)} (avg {int(sum(len(c) for c in chunks)/max(len(chunks),1))} chars)")

    if not chunks:
        return {"filename": filename, "success": False, "error": "no chunks"}

    # Add program tag to all metadatas
    for m in metadatas:
        m["program"] = program

    # Embed + store
    stored = embed_and_store(chunks, metadatas, filename)
    print(f"  Stored {stored} chunks with program='{program}'")

    return {
        "filename": filename,
        "success": True,
        "program": program,
        "chunks": stored,
        "pages": total_pages,
        "chars": total_chars,
        "method": method,
        "has_tables": has_tables,
    }


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--skip-existing", action="store_true",
                        help="Skip files that already have chunks in ChromaDB")
    args = parser.parse_args()

    pdf_dir  = Path("files")
    json_dir = Path("processed_pdfs")
    json_dir.mkdir(exist_ok=True)

    pdfs = sorted(pdf_dir.glob("*.pdf")) + sorted(pdf_dir.glob("*.PDF"))
    if not pdfs:
        print("No PDFs found in files/")
        sys.exit(0)

    print(f"Found {len(pdfs)} PDF(s) to process\n")

    results = []
    for i, pdf_path in enumerate(pdfs, 1):
        print(f"\n[{i}/{len(pdfs)}]", end="")
        try:
            r = process_pdf(pdf_path, json_dir, skip_existing=args.skip_existing)
            results.append(r)
        except Exception as e:
            import traceback
            traceback.print_exc()
            results.append({"filename": pdf_path.name, "success": False, "error": str(e)})

    # Summary
    print(f"\n\n{'='*60}")
    print("SUMMARY")
    print(f"{'='*60}")
    ok      = [r for r in results if r.get("success")]
    skipped = [r for r in results if r.get("skipped")]
    failed  = [r for r in results if not r.get("success") and not r.get("skipped")]

    for r in ok:
        print(f"  OK      {r['chunks']:4d} chunks | prog={r['program']:20s} | {r['filename']}")
    for r in skipped:
        print(f"  SKIP    {r['chunks']:4d} chunks | already in DB          | {r['filename']}")
    for r in failed:
        print(f"  FAILED  {r.get('error','?'):30s} | {r['filename']}")

    print(f"\nTotal: {len(ok)} processed, {len(skipped)} skipped, {len(failed)} failed")
    print(f"ChromaDB now: {col.count()} chunks total")
    print("\nDone! Restart the server.")


if __name__ == "__main__":
    main()
