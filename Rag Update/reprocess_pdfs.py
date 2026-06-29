"""
reprocess_pdfs.py
=================
Standalone script to re-process all PDFs in a given folder using the
OCR-enhanced pipeline and re-populate the ChromaDB collection from scratch.

Usage
-----
    # From the "Rag Update" directory:
    python reprocess_pdfs.py --pdf-dir ./pdfs

    # Force OCR on every page (even if native text looks fine):
    python reprocess_pdfs.py --pdf-dir ./pdfs --force-ocr

    # Dry-run: extract + save JSON but do NOT touch ChromaDB:
    python reprocess_pdfs.py --pdf-dir ./pdfs --dry-run

What it does
------------
1. Clears the existing ChromaDB collection (university_regulations).
2. For each PDF in --pdf-dir:
   a. Runs the two-pass extraction (pypdf + Tesseract OCR).
   b. Saves a clean structured JSON to ./processed_pdfs/<filename>.json.
   c. Splits the text into chunks with rich metadata.
   d. Embeds the chunks and stores them in ChromaDB.
3. Prints a summary at the end.

Requirements
------------
See requirements.txt.  Tesseract must be installed on the OS.
"""

import argparse
import json
import os
import sys
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()

# ── Validate environment before importing heavy deps ──────────────────────────
openrouter_key = os.getenv("OPENROUTER_API_KEY", "").strip()
openai_key = os.getenv("OPENAI_API_KEY", "").strip()

if not openrouter_key and not openai_key:
    print("ERROR: No API key found. Set OPENROUTER_API_KEY or OPENAI_API_KEY in .env")
    sys.exit(1)

# ── Imports ───────────────────────────────────────────────────────────────────
import chromadb
from chromadb.config import Settings
from langchain_openai import ChatOpenAI
from sentence_transformers import SentenceTransformer

from routes.pdf_processor import extract_and_structure_pdf, structured_doc_to_chunks


# ── ChromaDB setup ────────────────────────────────────────────────────────────
chroma_client = chromadb.PersistentClient(
    path="./chroma_db",
    settings=Settings(anonymized_telemetry=False)
)

COLLECTION_NAME = "university_regulations"


# ── Local Embeddings (MUST match chat.py – all-MiniLM-L6-v2, 384 dim) ────────
_EMBED_MODEL_NAME = "all-MiniLM-L6-v2"
print(f"Loading local embedding model: {_EMBED_MODEL_NAME} ...")
try:
    _st_model = SentenceTransformer(_EMBED_MODEL_NAME, local_files_only=True)
except Exception:
    print("  Model not cached – downloading from HuggingFace Hub ...")
    _st_model = SentenceTransformer(_EMBED_MODEL_NAME)
print(f"  Local embedding model loaded (384-dim).")


class _LocalEmbeddings:
    """Minimal embedding wrapper compatible with the rest of the script."""
    def embed_documents(self, texts):
        return _st_model.encode(texts, show_progress_bar=False).tolist()

    def embed_query(self, text):
        return _st_model.encode([text], show_progress_bar=False)[0].tolist()


embeddings = _LocalEmbeddings()


# ── LLM for Summary Node generation (OpenRouter, text-only) ───────────────────
_llm_key = openrouter_key or openai_key
_llm_base = "https://openrouter.ai/api/v1" if openrouter_key else None
print("Setting up LLM for summary generation ...")
llm_kwargs = dict(
    openai_api_key=_llm_key,
    model_name=os.getenv("OPENROUTER_MODEL", "openai/gpt-oss-120b:free"),
    temperature=0.3,
)
if _llm_base:
    llm_kwargs["openai_api_base"] = _llm_base
    llm_kwargs["default_headers"] = {
        "HTTP-Referer": os.getenv("OPENROUTER_REFERRER", "http://localhost:8000"),
        "X-Title": "Smart Campus RAG",
    }
llm = ChatOpenAI(**llm_kwargs)


# ── Helpers ───────────────────────────────────────────────────────────────────

def clear_collection(dry_run: bool = False) -> None:
    """Delete and recreate the ChromaDB collection."""
    if dry_run:
        print("[dry-run] Would delete and recreate collection:", COLLECTION_NAME)
        return
    try:
        chroma_client.delete_collection(COLLECTION_NAME)
        print(f"[OK] Deleted existing collection '{COLLECTION_NAME}'")
    except Exception:
        print(f"  Collection '{COLLECTION_NAME}' did not exist – creating fresh.")
    chroma_client.get_or_create_collection(
        name=COLLECTION_NAME,
        metadata={"description": "University regulations PDFs and CSV Q&A"}
    )
    print(f"[OK] Created fresh collection '{COLLECTION_NAME}'")


def process_pdf(
    pdf_path: Path,
    collection,
    json_dir: Path,
    force_ocr: bool = False,
    dry_run: bool = False
) -> dict:
    """Process a single PDF and store results in ChromaDB."""
    filename = pdf_path.name
    print(f"\n{'='*60}")
    print(f"Processing: {filename}")
    print(f"{'='*60}")

    with open(pdf_path, "rb") as f:
        pdf_bytes = f.read()

    # ── Extract ───────────────────────────────────────────────────────────
    structured_doc = extract_and_structure_pdf(
        pdf_bytes=pdf_bytes,
        filename=filename,
        force_ocr=force_ocr
    )

    # ── Save JSON ─────────────────────────────────────────────────────────
    json_path = json_dir / f"{filename}.json"
    with open(json_path, "w", encoding="utf-8") as jf:
        json.dump(structured_doc, jf, ensure_ascii=False, indent=2)
    print(f"  [OK] JSON saved: {json_path}")

    if not structured_doc["full_text"].strip():
        print(f"  [FAIL] No text extracted from {filename} – skipping ChromaDB storage")
        return {"filename": filename, "success": False, "error": "No text extracted"}

    # ── Chunk ─────────────────────────────────────────────────────────────
    chunks, metadatas = structured_doc_to_chunks(structured_doc)
    
    # ── Generate Summary Node ─────────────────────────────────────────────
    print(f"  Generating summary node for {filename} ...")
    try:
        # Take first 4000 characters to avoid exceeding token limits
        sample_text = structured_doc["full_text"][:4000]
        prompt = f"قم بعمل ملخص شامل ومكثف للمستند التالي في 3 أو 4 جمل. استخرج أهم النقاط والمواضيع التي يغطيها المستند.\n\nالمستند:\n{sample_text}\n\nالملخص:"
        resp = llm.invoke(prompt)
        summary = resp.content if hasattr(resp, "content") else str(resp)
        if summary:
            # Prepend as chunk 0
            chunks.insert(0, summary.strip())
            metadatas.insert(0, {
                "fileName": filename,
                "page": 1,
                "sectionTitle": "Summary Node",
                "language": "arabic",
                "keywords": "ملخص, summary, overview",
                "is_summary": True,
                "chunkId": f"{filename}-summary"
            })
            print(f"  [OK] Summary node generated.")
    except Exception as e:
        print(f"  [FAIL] Failed to generate summary node: {e}")

    print(f"  [OK] {len(chunks)} semantic chunks created (including summary if successful)")

    if dry_run:
        print(f"  [dry-run] Would embed and store {len(chunks)} chunks")
        return {
            "filename": filename,
            "success": True,
            "chunks": len(chunks),
            "pages": structured_doc["total_pages"],
            "method": structured_doc["extraction_method"],
            "dry_run": True
        }

    # ── Embed ─────────────────────────────────────────────────────────────
    print(f"  Generating embeddings for {len(chunks)} chunks ...")
    embeddings_list = embeddings.embed_documents(chunks)
    print(f"  [OK] {len(embeddings_list)} embeddings generated")

    # ── Store ─────────────────────────────────────────────────────────────
    batch_size = 5000
    # Use deterministic IDs from semantic chunker metadata
    ids = [meta.get("chunkId") or f"{filename}-{i}" for i, meta in enumerate(metadatas)]
    for i in range(0, len(chunks), batch_size):
        end = min(i + batch_size, len(chunks))
        collection.upsert(
            embeddings=embeddings_list[i:end],
            documents=chunks[i:end],
            metadatas=metadatas[i:end],
            ids=ids[i:end]
        )
    print(f"  [OK] Upserted into ChromaDB")

    return {
        "filename": filename,
        "success": True,
        "chunks": len(chunks),
        "pages": structured_doc["total_pages"],
        "method": structured_doc["extraction_method"],
        "has_arabic": structured_doc["metadata"]["has_arabic"],
        "has_english": structured_doc["metadata"]["has_english"],
        "total_chars": structured_doc["metadata"]["total_chars"],
        "avg_chunk_size": int(sum(len(c) for c in chunks) / max(len(chunks), 1)),
        "languages": list(set(m.get("language", "unknown") for m in metadatas)),
    }


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Re-process PDFs with OCR and repopulate ChromaDB"
    )
    parser.add_argument(
        "--pdf-dir",
        type=str,
        default="./pdfs",
        help="Directory containing PDF files to process (default: ./pdfs)"
    )
    parser.add_argument(
        "--force-ocr",
        action="store_true",
        help="Force OCR on every page even if native text is sufficient"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Extract and save JSON but do NOT modify ChromaDB"
    )
    parser.add_argument(
        "--keep-existing",
        action="store_true",
        help="Do not clear the existing ChromaDB collection before processing"
    )
    args = parser.parse_args()

    pdf_dir = Path(args.pdf_dir)
    if not pdf_dir.exists():
        print(f"ERROR: PDF directory not found: {pdf_dir}")
        print("Create the directory and place your PDF files inside it, then re-run.")
        sys.exit(1)

    pdf_files = sorted(pdf_dir.glob("*.pdf")) + sorted(pdf_dir.glob("*.PDF"))
    if not pdf_files:
        print(f"No PDF files found in {pdf_dir}")
        sys.exit(0)

    print(f"Found {len(pdf_files)} PDF file(s) in {pdf_dir}")

    # Output directory for structured JSON files
    json_dir = Path("./processed_pdfs")
    json_dir.mkdir(exist_ok=True)

    # Clear / prepare collection
    if not args.keep_existing:
        clear_collection(dry_run=args.dry_run)

    if args.dry_run:
        collection = None
    else:
        collection = chroma_client.get_or_create_collection(
            name=COLLECTION_NAME,
            metadata={"description": "University regulations PDFs and CSV Q&A"}
        )

    # Process each PDF
    summary = []
    for pdf_path in pdf_files:
        try:
            result = process_pdf(
                pdf_path=pdf_path,
                collection=collection,
                json_dir=json_dir,
                force_ocr=args.force_ocr,
                dry_run=args.dry_run
            )
            summary.append(result)
        except Exception as e:
            import traceback
            traceback.print_exc()
            summary.append({"filename": pdf_path.name, "success": False, "error": str(e)})

    # Print summary
    print(f"\n{'='*60}")
    print("SUMMARY")
    print(f"{'='*60}")
    succeeded = [r for r in summary if r.get("success")]
    failed = [r for r in summary if not r.get("success")]

    for r in succeeded:
        print(
            f"  [OK] {r['filename']}: {r.get('chunks', 0)} chunks, "
            f"{r.get('pages', 0)} pages, method={r.get('method', 'n/a')}, "
            f"avg_chunk={r.get('avg_chunk_size', 0)} chars, "
            f"langs={r.get('languages', [])}"
        )
    for r in failed:
        print(f"  [FAIL] {r['filename']}: {r.get('error', 'unknown error')}")

    print(f"\nTotal: {len(succeeded)}/{len(summary)} files processed successfully")
    if not args.dry_run:
        total_chunks = sum(r.get("chunks", 0) for r in succeeded)
        print(f"Total chunks stored in ChromaDB: {total_chunks}")


if __name__ == "__main__":
    main()
