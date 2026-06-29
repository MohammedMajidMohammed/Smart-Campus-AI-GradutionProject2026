"""
reprocess_single_pdf.py
========================
Reprocess a single PDF with force-OCR and update ChromaDB only for that file.
Usage: venv/Scripts/python.exe reprocess_single_pdf.py "filename.pdf" [--dry-run]
"""

import argparse
import json
import os
import sys
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()

# ── Validate environment ──────────────────────────────────────────────────────
openai_key      = os.getenv("OPENAI_API_KEY", "").strip()
openrouter_key  = os.getenv("OPENROUTER_API_KEY", "").strip()

if not openai_key and not openrouter_key:
    print("ERROR: لم يتم العثور على API key. أضف OPENAI_API_KEY أو OPENROUTER_API_KEY في .env")
    sys.exit(1)

# ── Imports ───────────────────────────────────────────────────────────────────
import chromadb
from chromadb.config import Settings
from langchain_openai import OpenAIEmbeddings

from routes.pdf_processor import extract_and_structure_pdf, structured_doc_to_chunks

# ── ChromaDB ──────────────────────────────────────────────────────────────────
COLLECTION_NAME = "university_regulations"
chroma_client = chromadb.PersistentClient(
    path="./chroma_db",
    settings=Settings(anonymized_telemetry=False)
)

# ── Local Embeddings (sentence-transformers) ────────────────────────────────────────
try:
    from sentence_transformers import SentenceTransformer
    local_model = SentenceTransformer('all-MiniLM-L6-v2')
    class LocalEmbeddings:
        def embed_documents(self, texts):
            return local_model.encode(texts, convert_to_numpy=True).tolist()
    embeddings_model = LocalEmbeddings()
    print("Using local sentence-transformers embeddings")
except Exception as e:
    raise RuntimeError(f"Failed to load local embeddings model: {e}")


# ── Helpers ───────────────────────────────────────────────────────────────────

def find_pdf(name: str) -> Path:
    """ابحث عن الـ PDF — إما مسار مباشر أو في مجلد files/."""
    p = Path(name)
    if p.exists():
        return p.resolve()
    # جرّب في مجلد files/
    candidate = Path("files") / name
    if candidate.exists():
        return candidate.resolve()
    print(f"ERROR: الملف غير موجود: {name}")
    print(f"       جربت ايضا: {candidate}")
    sys.exit(1)


def delete_file_chunks(collection, filename: str, dry_run: bool = False) -> int:
    """
    احذف كل الـ chunks المرتبطة بملف معين من ChromaDB.
    يستخدم الـ fileName metadata للتحديد الدقيق.
    """
    # جلب IDs الخاصة بالملف ده بس
    results = collection.get(
        where={"fileName": filename},
        include=[]  # IDs فقط، بدون embeddings أو documents
    )
    ids_to_delete = results.get("ids", [])

    if not ids_to_delete:
        print(f"  لا توجد chunks قديمة للملف '{filename}' في ChromaDB")
        return 0

    print(f"  وُجد {len(ids_to_delete)} chunk قديم للملف '{filename}'")

    if dry_run:
        print(f"  [dry-run] كان سيتم حذف {len(ids_to_delete)} chunk")
        return len(ids_to_delete)

    # حذف على دفعات (ChromaDB له حد أقصى)
    BATCH = 500
    for i in range(0, len(ids_to_delete), BATCH):
        batch = ids_to_delete[i:i + BATCH]
        collection.delete(ids=batch)
        print(f"  ✓ حُذفت دفعة {i // BATCH + 1}: {len(batch)} chunk")

    print(f"  ✓ تم حذف {len(ids_to_delete)} chunk قديم")
    return len(ids_to_delete)


def process_and_store(
    pdf_path: Path,
    collection,
    json_dir: Path,
    dry_run: bool = False,
) -> dict:
    """
    استخرج النص بـ force-OCR، قسّمه، وخزّنه في ChromaDB.
    """
    filename = pdf_path.name

    print(f"\n{'='*60}")
    print(f"  الملف: {filename}")
    print(f"  المسار: {pdf_path}")
    print(f"{'='*60}")

    with open(pdf_path, "rb") as f:
        pdf_bytes = f.read()

    # ── استخراج بـ force-OCR (يتجاهل النص الأصلي المكسور) ────────────────
    print("\n[1/4] استخراج النص بـ OCR كامل ...")
    structured_doc = extract_and_structure_pdf(
        pdf_bytes=pdf_bytes,
        filename=filename,
        force_ocr=True,          # ← الأساس: يتجاهل النص الأصلي ويعمل OCR على الصور
    )

    total_chars = structured_doc["metadata"]["total_chars"]
    total_pages = structured_doc["total_pages"]
    method      = structured_doc["extraction_method"]

    print(f"  ✓ {total_pages} صفحة | {total_chars} حرف | طريقة: {method}")

    if total_chars < 100:
        print("  ✗ النص المستخرج قصير جداً — تأكد من تثبيت Tesseract وبيانات اللغة العربية")
        print("    Windows: https://github.com/UB-Mannheim/tesseract/wiki")
        print("    تأكد من تفعيل Arabic language data أثناء التثبيت")
        return {"filename": filename, "success": False, "error": "OCR returned too little text"}

    # ── حفظ JSON للمراجعة ────────────────────────────────────────────────
    print("\n[2/4] حفظ JSON ...")
    json_dir.mkdir(exist_ok=True)
    json_path = json_dir / f"{filename}.json"
    with open(json_path, "w", encoding="utf-8") as jf:
        json.dump(structured_doc, jf, ensure_ascii=False, indent=2)
    print(f"  ✓ محفوظ: {json_path}")

    # ── تقسيم لـ chunks ───────────────────────────────────────────────────
    print("\n[3/4] تقسيم النص لـ chunks ...")
    chunks, metadatas = structured_doc_to_chunks(structured_doc)
    print(f"  ✓ {len(chunks)} chunk")

    if not chunks:
        return {"filename": filename, "success": False, "error": "No chunks produced"}

    if dry_run:
        print(f"\n[dry-run] كان سيتم تخزين {len(chunks)} chunk في ChromaDB")
        # اعرض عينة من أول 3 chunks
        print("\n-- عينة من اول 3 chunks --")
        for i, (txt, meta) in enumerate(zip(chunks[:3], metadatas[:3])):
            print(f"\nChunk {i+1} | صفحة {meta.get('page')} | {len(txt)} حرف")
            print(txt[:300])
        return {
            "filename": filename, "success": True,
            "chunks": len(chunks), "pages": total_pages,
            "method": method, "total_chars": total_chars,
            "has_tables": structured_doc["metadata"].get("has_tables", False),
            "tables_on_pages": structured_doc["metadata"].get("tables_on_pages", []),
            "dry_run": True
        }

    # ── توليد embeddings ──────────────────────────────────────────────────
    print(f"\n[4/4] توليد embeddings لـ {len(chunks)} chunk ...")
    EMBED_BATCH = 100
    all_embeddings = []
    for i in range(0, len(chunks), EMBED_BATCH):
        batch = chunks[i:i + EMBED_BATCH]
        vecs  = embeddings_model.embed_documents(batch)
        all_embeddings.extend(vecs)
        print(f"  ... {min(i + EMBED_BATCH, len(chunks))}/{len(chunks)}")

    print(f"  ✓ {len(all_embeddings)} embedding جاهز")

    # ── تخزين في ChromaDB ─────────────────────────────────────────────────
    ids = [meta.get("chunkId") or f"{filename}-{i}" for i, meta in enumerate(metadatas)]
    STORE_BATCH = 500
    for i in range(0, len(chunks), STORE_BATCH):
        end = min(i + STORE_BATCH, len(chunks))
        collection.upsert(
            ids        = ids[i:end],
            embeddings = all_embeddings[i:end],
            documents  = chunks[i:end],
            metadatas  = metadatas[i:end],
        )
    print(f"  ✓ تم تخزين {len(chunks)} chunk في ChromaDB")

    return {
        "filename": filename,
        "success": True,
        "chunks": len(chunks),
        "pages": total_pages,
        "method": method,
        "total_chars": total_chars,
        "has_tables": structured_doc["metadata"].get("has_tables", False),
        "tables_on_pages": structured_doc["metadata"].get("tables_on_pages", []),
    }


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="أعد معالجة ملف PDF واحد بـ force-OCR وحدّث ChromaDB"
    )
    parser.add_argument(
        "pdf",
        help="اسم الملف (يبحث في files/) أو المسار الكامل"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="استخرج النص فقط بدون تعديل ChromaDB"
    )
    args = parser.parse_args()

    pdf_path = find_pdf(args.pdf)
    filename = pdf_path.name

    print(f"\n{'='*60}")
    print(f"  reprocess_single_pdf — force-OCR mode")
    print(f"  الملف: {filename}")
    print(f"  dry-run: {args.dry_run}")
    print(f"{'='*60}\n")

    # ── فتح الـ collection ────────────────────────────────────────────────
    collection = chroma_client.get_or_create_collection(
        name=COLLECTION_NAME,
        metadata={"description": "University regulations PDFs and CSV Q&A"}
    )
    print(f"ChromaDB collection: {collection.count()} chunk إجمالي\n")

    # ── حذف الـ chunks القديمة للملف ده بس ───────────────────────────────
    print(f"[0/4] حذف chunks قديمة للملف '{filename}' ...")
    deleted = delete_file_chunks(collection, filename, dry_run=args.dry_run)

    # ── معالجة وتخزين ────────────────────────────────────────────────────
    result = process_and_store(
        pdf_path   = pdf_path,
        collection = collection,
        json_dir   = Path("./processed_pdfs"),
        dry_run    = args.dry_run,
    )

    # ── ملخص ─────────────────────────────────────────────────────────────
    print(f"\n{'='*60}")
    print("  النتيجة النهائية")
    print(f"{'='*60}")

    if result.get("success"):
        print(f"  ✅ نجح: {result['filename']}")
        print(f"     الصفحات  : {result.get('pages', 0)}")
        print(f"     الـ chunks: {result.get('chunks', 0)}")
        print(f"     الأحرف   : {result.get('total_chars', 0)}")
        print(f"     الطريقة  : {result.get('method', 'n/a')}")
        print(f"     جداول    : {result.get('has_tables', False)} (صفحات: {result.get('tables_on_pages', [])})")
        if not args.dry_run:
            print(f"\n  ChromaDB الآن: {collection.count()} chunk إجمالي")
            print(f"\n  ✅ جاهز! شغّل السيرفر وجرّب تسأل عن مقررات اللغة الإنجليزية.")
    else:
        print(f"  ❌ فشل: {result.get('error', 'خطأ غير معروف')}")
        sys.exit(1)


if __name__ == "__main__":
    main()
