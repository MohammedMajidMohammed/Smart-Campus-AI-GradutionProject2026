"""
reprocess_native.py
====================
Reprocess ALL PDFs using native text extraction (no force-OCR).
OCR only runs on pages that have less than 200 chars of native text.
This preserves good native text and only uses OCR where needed.
"""
import json, os, sys
from pathlib import Path

os.chdir(Path(__file__).parent)
sys.path.insert(0, str(Path(__file__).parent))

from dotenv import load_dotenv
load_dotenv()

print("Loading local embedding model...")
from sentence_transformers import SentenceTransformer
model = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")
print("Model ready\n")

import chromadb
from chromadb.config import Settings
from routes.pdf_processor import extract_and_structure_pdf, structured_doc_to_chunks

COLLECTION_NAME = "university_regulations"
chroma = chromadb.PersistentClient(path="./chroma_db", settings=Settings(anonymized_telemetry=False))
col = chroma.get_or_create_collection(name=COLLECTION_NAME, metadata={"description": "University regulations"})
print(f"ChromaDB: {col.count()} chunks before\n")

_FNAME_PROG_MAP = [
    (["علاج طبيعي", "علاج_طبيعي", "physical therapy", "physio"], "physical therapy"),
    (["طب بيطري", "بيطري", "veterinary", "veterinar"], "veterinary"),
    (["طب أسنان", "أسنان", "اسنان", "dentistry", "dent", "فم والاسنان", "الفم"], "dentistry"),
    (["طب وجراحه", "طب_وجراحه", "وجراحه"], "medicine"),
    (["طب", "medicine", "medical", "mbbs"], "medicine"),
    (["صيدلة", "صيدله", "pharmacy", "pharm"], "pharmacy"),
    (["تمريض", "nursing", "nurse"], "nursing"),
    (["هندسة", "هندسه", "engineering", "eng"], "engineering"),
    (["حاسبات", "حاسوب", "computer", "cs", "it", "fci", "bcs", "ذكاء"], "computer science"),
    (["إدارة", "ادارة", "أعمال", "business", "management"], "business"),
    (["ألسن", "السن", "لغات", "اللغة", "الترجمة", "languages", "english", "translation", "arts"], "arts"),
    (["حقوق", "قانون", "law"], "law"),
    (["علوم", "science", "sci"], "science"),
    (["زراعة", "زراعه", "agriculture"], "agriculture"),
    (["تربية", "تربيه", "education"], "education"),
    (["اقتصاد", "economics"], "economics"),
    (["إعلام", "اعلام", "media"], "mass communication"),
    (["سياحة", "سياحه", "tourism"], "tourism"),
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

def delete_file_chunks(filename):
    all_data = col.get(include=["metadatas"])
    old_ids = [all_data["ids"][i] for i, m in enumerate(all_data["metadatas"]) if m.get("fileName") == filename]
    if old_ids:
        for i in range(0, len(old_ids), 500):
            col.delete(ids=old_ids[i:i+500])
    return len(old_ids)

def embed_and_store(chunks, metadatas, filename):
    all_embeddings = []
    for i in range(0, len(chunks), 32):
        vecs = model.encode(chunks[i:i+32], show_progress_bar=False, normalize_embeddings=True)
        all_embeddings.extend(vecs.tolist())
    ids = [m.get("chunkId") or f"{filename}-{i}" for i, m in enumerate(metadatas)]
    for i in range(0, len(chunks), 200):
        end = min(i+200, len(chunks))
        col.upsert(ids=ids[i:end], embeddings=all_embeddings[i:end], documents=chunks[i:end], metadatas=metadatas[i:end])
    return len(chunks)

pdf_dir  = Path("files")
json_dir = Path("processed_pdfs")
json_dir.mkdir(exist_ok=True)
pdfs = sorted(pdf_dir.glob("*.pdf")) + sorted(pdf_dir.glob("*.PDF"))
print(f"Found {len(pdfs)} PDFs\n")

results = []
for i, pdf_path in enumerate(pdfs, 1):
    filename = pdf_path.name
    program  = detect_program(filename)
    print(f"[{i}/{len(pdfs)}] {filename} | prog={program}")

    try:
        deleted = delete_file_chunks(filename)
        if deleted: print(f"  Deleted {deleted} old chunks")

        with open(pdf_path, "rb") as f:
            pdf_bytes = f.read()

        # Native extraction — OCR only on sparse pages (< 200 chars)
        structured_doc = extract_and_structure_pdf(pdf_bytes=pdf_bytes, filename=filename, force_ocr=False)
        total_chars = structured_doc["metadata"]["total_chars"]
        method = structured_doc["extraction_method"]
        print(f"  {structured_doc['total_pages']} pages | {total_chars:,} chars | {method}")

        if total_chars < 50:
            print(f"  WARNING: very little text")
            results.append({"filename": filename, "success": False, "error": "too little text"})
            continue

        json_path = json_dir / f"{filename}.json"
        with open(json_path, "w", encoding="utf-8") as jf:
            json.dump(structured_doc, jf, ensure_ascii=False, indent=2)

        chunks, metadatas = structured_doc_to_chunks(structured_doc)
        for m in metadatas:
            m["program"] = program
        print(f"  {len(chunks)} chunks")

        stored = embed_and_store(chunks, metadatas, filename)
        print(f"  Stored {stored} chunks")
        results.append({"filename": filename, "success": True, "chunks": stored, "chars": total_chars})

    except Exception as e:
        import traceback; traceback.print_exc()
        results.append({"filename": filename, "success": False, "error": str(e)})

print(f"\n{'='*60}")
print("SUMMARY")
ok = [r for r in results if r.get("success")]
fail = [r for r in results if not r.get("success")]
for r in ok:
    print(f"  OK   {r['chunks']:4d} chunks | {r['filename']}")
for r in fail:
    print(f"  FAIL {r.get('error','?'):30s} | {r['filename']}")
print(f"\nTotal: {len(ok)} OK, {len(fail)} failed")
print(f"ChromaDB now: {col.count()} chunks")
print("Done! Restart the server.")
