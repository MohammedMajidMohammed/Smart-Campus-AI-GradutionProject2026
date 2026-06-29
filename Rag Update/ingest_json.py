import os
import json
import sys
import io
from pathlib import Path

# Fix terminal encoding for Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# Add current dir to sys.path
sys.path.append(str(Path(__file__).parent))

from dotenv import load_dotenv
load_dotenv()

from routes.pdf_processor import structured_doc_to_chunks
from routes.upload import embeddings, collection, invalidate_index

def ingest_json_file(file_path, program_tag):
    print(f"\n[Ingest] Processing {file_path} for program: {program_tag}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    filename = data.get('filename', Path(file_path).name)
    pages = data.get('pages', [])
    
    # Structure for structured_doc_to_chunks
    structured_doc = {
        "filename": filename,
        "total_pages": len(pages),
        "pages": pages,
        "full_text": "\n\n".join([p.get('text', '') for p in pages])
    }
    
    # 1. Chunking
    print(f"  - Chunking {len(pages)} pages...")
    chunks, metadatas = structured_doc_to_chunks(
        structured_doc,
        chunk_size=2000,
        chunk_overlap=300
    )
    
    if not chunks:
        print(f"  ! No chunks produced")
        return
    
    # 2. Add metadata
    for m in metadatas:
        m["program"] = program_tag
        m["fileName"] = filename
    
    ids = [meta.get("chunkId") or f"{filename}-{i}" for i, meta in enumerate(metadatas)]
    
    # 3. Embeddings
    print(f"  - Generating embeddings for {len(chunks)} chunks in batches...")
    embeddings_list = []
    emb_batch_size = 20  # Small batches for stability
    for i in range(0, len(chunks), emb_batch_size):
        batch = chunks[i : min(i + emb_batch_size, len(chunks))]
        try:
            batch_embeddings = embeddings.embed_documents(batch)
            if not batch_embeddings:
                raise ValueError(f"No embeddings returned for batch {i//emb_batch_size}")
            embeddings_list.extend(batch_embeddings)
            print(f"    - Processed {len(embeddings_list)}/{len(chunks)} chunks...")
        except Exception as e:
            print(f"  ! Error embedding batch starting at {i}: {e}")
            # Try once more for this batch
            try:
                print("    - Retrying batch...")
                batch_embeddings = embeddings.embed_documents(batch)
                embeddings_list.extend(batch_embeddings)
            except Exception as e2:
                print(f"  !! Fatal error on batch retry: {e2}")
                return

    # 4. Upsert to ChromaDB
    print(f"  - Upserting to ChromaDB...")
    batch_size = 100
    for i in range(0, len(embeddings_list), batch_size):
        end = min(i + batch_size, len(embeddings_list))
        collection.upsert(
            embeddings=embeddings_list[i:end],
            documents=chunks[i:end],
            metadatas=metadatas[i:end],
            ids=ids[i:end]
        )
    
    print(f"  - Done: {len(embeddings_list)} chunks indexed.")

if __name__ == "__main__":
    files_to_ingest = [
        # ── Already indexed ───────────────────────────────────────────────────
        ("processed_pdfs/طب وجراحه.pdf.json",                                                           "medicine"),
        ("processed_pdfs/هندسه_ميكاترونيكس.pdf.json",                                                   "engineering"),
        ("processed_pdfs/هندسه_حاسوب.pdf.json",                                                         "engineering"),
        ("processed_pdfs/لائحه الفم والاسنان جامعة المنوفية الأهليه A-1.pdf.json",                      "dentistry"),
        # ── New faculties ─────────────────────────────────────────────────────
        ("processed_pdfs/دليل تمريض.pdf.json",                                                          "nursing"),
        ("processed_pdfs/دليل_الطالب_نهائي_علاج_طبيعي_2025_2026.pdf.json",                              "physiotherapy"),
        ("processed_pdfs/دليل صيدلة.pdf.json",                                                          "pharmacy"),
        ("processed_pdfs/لائحة طب بيطري ساعات معتمدة1-1 (1).pdf.json",                                  "veterinary"),
        ("processed_pdfs/دليل_برامج_كلية_الحاسوب_والذكاء_الاصطناعى_جامعة_المنوفية_الاهلية.pdf.json",   "computer science"),
        ("processed_pdfs/لائحه برنامج اللغة الإنجليزية و الترجمة التخصصية.pdf.json",                    "arts"),
        ("processed_pdfs/لائحة الجامعة الأهلية.pdf.json",                                               "general"),
        ("processed_pdfs/student guide 25-26-2.pdf.json",                                               "general"),
    ]

    for fname, prog in files_to_ingest:
        path = Path(fname)
        if path.exists():
            ingest_json_file(str(path), prog)
        else:
            print(f"! File not found: {fname}")
    
    # 5. Run retag_chunks.py to ensure consistency across all data
    print("\n[Retag] Running retag_chunks.py...")
    import subprocess
    env = os.environ.copy()
    env["PYTHONIOENCODING"] = "utf-8"
    subprocess.run([sys.executable, "retag_chunks.py"], check=True, env=env)
    
    # 6. Invalidate BM25 index
    print("\n[BM25] Invalidating BM25 index for rebuild...")
    invalidate_index("university_regulations")
    
    print("\n✅ All steps completed successfully!")
