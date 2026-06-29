"""
retag_chunks.py
===============
One-time script: adds 'program' metadata to all existing ChromaDB chunks
based on their fileName — without re-uploading or re-embedding anything.

Run once from the project root:
    venv\Scripts\python.exe retag_chunks.py
"""

import sys
import os
from pathlib import Path

_HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(_HERE))

from dotenv import load_dotenv
load_dotenv(_HERE / ".env")

import chromadb
from chromadb.config import Settings

# ── Program detection from filename ──────────────────────────────────────────
_FNAME_PROG_MAP = [
    (["علاج طبيعي", "علاج_طبيعي", "physical therapy", "physio"], "physical therapy"),
    (["طب بيطري", "بيطري", "veterinary", "veterinar", "bitar"], "veterinary"),
    (["طب أسنان", "أسنان", "اسنان", "dentistry", "dent"], "dentistry"),
    (["طب وجراحه", "طب_وجراحه", "وجراحه"], "medicine"),
    (["طب", "medicine", "medical", "mbbs"], "medicine"),
    (["صيدلة", "صيدله", "pharmacy", "pharm"], "pharmacy"),
    (["تمريض", "nursing", "nurse"], "nursing"),
    (["هندسة", "هندسه", "engineering", "eng"], "engineering"),
    (["حاسبات", "حاسبات ومعلومات", "الحاسوب", "computer", "cs", "it", "fci", "bcs"], "computer science"),
    (["إدارة", "ادارة", "أعمال", "business", "management", "bba", "mgt"], "business"),
    (["ألسن", "السن", "لغات", "اللغة", "الترجمة", "languages", "english", "translation", "arts", "humanities", "آداب", "اداب", "فنون"], "arts"),
    (["حقوق", "قانون", "law"], "law"),
    (["علوم", "science", "sci"], "science"),
    (["زراعة", "زراعه", "agriculture", "agri"], "agriculture"),
    (["تربية", "تربيه", "education", "edu"], "education"),
    (["اقتصاد", "اقتصاد وعلوم سياسية", "economics", "political science", "eco"], "economics"),
    (["إعلام", "اعلام", "mass communication", "media"], "mass communication"),
    (["سياحة", "سياحه", "فنادق", "tourism", "hotels"], "tourism"),
    (["آثار", "اثار", "archaeology", "antiquities"], "archaeology"),
    (["فني", "معهد فني", "technical", "tech"], "technical"),
]

# Chunks from these files are general university regulations — keep neutral
_GENERAL_REGULATION_KEYWORDS = [
    "لائحة الجامعة", "لائحه جامعة", "student guide", "دليل الطالب",
]


def detect_program(fname: str) -> str | None:
    fl = fname.lower()

    # Check if it's a general university regulation file → neutral
    if any(kw.lower() in fl for kw in _GENERAL_REGULATION_KEYWORDS):
        return "general"   # special tag: applies to all programs

    for keywords, prog in _FNAME_PROG_MAP:
        if any(kw in fl for kw in keywords):
            return prog
    return "general"


# ── Connect to ChromaDB ───────────────────────────────────────────────────────
print("Connecting to ChromaDB …")
chroma = chromadb.PersistentClient(
    path=str(_HERE / "chroma_db"),
    settings=Settings(anonymized_telemetry=False),
)
col = chroma.get_collection("university_regulations")
print(f"Collection: {col.count()} chunks\n")

# ── Fetch all chunks ──────────────────────────────────────────────────────────
data    = col.get(include=["metadatas", "documents"])
ids     = data["ids"]
metas   = data["metadatas"]
docs    = data["documents"]

# ── Compute new tags ──────────────────────────────────────────────────────────
tag_counts: dict[str, int] = {}
updated_ids:   list[str]  = []
updated_metas: list[dict] = []
updated_docs:  list[str]  = []

for doc_id, meta, doc in zip(ids, metas, docs):
    fname   = meta.get("fileName", "")
    current = meta.get("program")
    new_tag = detect_program(fname)

    if new_tag != current:
        new_meta = {**meta, "program": new_tag}
        updated_ids.append(doc_id)
        updated_metas.append(new_meta)
        updated_docs.append(doc)
        tag_counts[new_tag or "None"] = tag_counts.get(new_tag or "None", 0) + 1

print(f"Chunks to update: {len(updated_ids)}")
print(f"Tag distribution: {tag_counts}\n")

if not updated_ids:
    print("Nothing to update — all chunks already tagged.")
    sys.exit(0)

# ── Upsert in batches (metadata-only update, no re-embedding) ─────────────────
# ChromaDB upsert with same embeddings = metadata update only
# We need to fetch embeddings too for the upsert call
print("Fetching embeddings for updated chunks …")
BATCH = 500
all_embeddings = []

for i in range(0, len(updated_ids), BATCH):
    batch_ids = updated_ids[i:i + BATCH]
    emb_data  = col.get(ids=batch_ids, include=["embeddings"])
    all_embeddings.extend(emb_data["embeddings"])
    print(f"  Fetched {min(i + BATCH, len(updated_ids))}/{len(updated_ids)} embeddings")

print(f"\nUpserting {len(updated_ids)} chunks with new program tags …")
for i in range(0, len(updated_ids), BATCH):
    batch_end = min(i + BATCH, len(updated_ids))
    col.upsert(
        ids        = updated_ids[i:batch_end],
        embeddings = all_embeddings[i:batch_end],
        documents  = updated_docs[i:batch_end],
        metadatas  = updated_metas[i:batch_end],
    )
    print(f"  Upserted batch {i // BATCH + 1} ({batch_end - i} chunks)")

print("\n✅ Done! Program tags applied:")
# Show final summary
data2  = col.get(include=["metadatas"])
final: dict[str, dict[str, int]] = {}
for m in data2["metadatas"]:
    fn   = m.get("fileName", "?")
    prog = m.get("program") or "None"
    if fn not in final:
        final[fn] = {}
    final[fn][prog] = final[fn].get(prog, 0) + 1

for fn, progs in sorted(final.items()):
    for prog, cnt in progs.items():
        print(f"  {cnt:4d} chunks  prog={prog:25s}  {fn}")
