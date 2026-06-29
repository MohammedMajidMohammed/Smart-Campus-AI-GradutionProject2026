import sys
from chat_cli import RAGSession

session = RAGSession()
res = session.collection.get(
    where={"fileName": "student guide 25-26-2.pdf"},
    include=["documents", "metadatas"]
)

docs = res.get("documents", [])
metas = res.get("metadatas", [])

for idx, (doc, meta) in enumerate(zip(docs, metas)):
    # Look for passing, grade, exam, 60, success, or corresponding Arabic terms
    if any(k in doc for k in ["60", "نجاح", "درجة", "passing", "grade", "mark"]):
        print(f"Chunk {idx} (Page {meta.get('page')}, Section: {meta.get('sectionTitle')}):")
        print(doc[:400] + "...")
        print("-" * 50)
