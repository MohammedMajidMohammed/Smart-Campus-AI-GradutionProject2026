import chromadb
import sys
import numpy as np
from routes.chat import _LocalHuggingFaceEmbeddings

sys.stdout.reconfigure(encoding="utf-8")

client = chromadb.PersistentClient(path="chroma_db")
collection = client.get_collection("university_regulations")
embeddings = _LocalHuggingFaceEmbeddings()

# Fetch chunk index 50
res = collection.get(
    where={"fileName": "دليل_برامج_كلية_الحاسوب_والذكاء_الاصطناعى_جامعة_المنوفية_الاهلية.pdf"},
    include=["embeddings", "documents", "metadatas"]
)

docs = res.get("documents", [])
metas = res.get("metadatas", [])
embs = res.get("embeddings", [])

chunk_50_emb = None
chunk_50_doc = None
chunk_50_meta = None

for doc, meta, emb in zip(docs, metas, embs):
    if meta.get("chunkIndex") == 50:
        chunk_50_emb = emb
        chunk_50_doc = doc
        chunk_50_meta = meta
        break

if chunk_50_emb is None:
    print("Chunk 50 not found in database!")
    sys.exit(1)

print("Chunk 50 found!")
print(f"Snippet: {chunk_50_doc[:300]}")
print(f"Metadata: {chunk_50_meta}")

# Let's check distance to different queries
queries = [
    # 1. Original User query
    "ما هو شروط التدريب الصيفي في كلية الحاسبات والذكاء الاصطناعي قسم برنامج إنترنت الأشياء وتحليل البيانات الضخمة",
    # 2. English clean query
    "computer science regulations rules requirements academic policy success passing criteria conditions ما هو شروط تدريب صيفي في كليه حاسبات ذكاء اصطناعي قسم برنامج انترنت اشياء تحليل بيانات ضخمه",
    # 3. Simple Arabic keywords
    "التدريب الصيفي الحاسبات والذكاء الاصطناعي انترنت الاشياء",
    # 4. Phrase from page 24
    "التدريب العملي والميداني يلتزم الطالب باداء تدريب عملي وميداني اجباري",
    # 5. Just "التدريب الصيفي"
    "التدريب الصيفي",
    # 6. "التدريب الميداني"
    "التدريب الميداني"
]

for q in queries:
    q_emb = embeddings.embed_query(q)
    # L2 distance
    dist = np.sum((np.array(q_emb) - np.array(chunk_50_emb)) ** 2)
    # Cosine similarity (since they are normalized, cosine similarity is 1 - 0.5 * dist)
    cos_sim = 1.0 - 0.5 * dist
    print(f"\nQuery: {q}")
    print(f"  L2 Distance: {dist:.4f}")
    print(f"  Cosine Similarity: {cos_sim:.4f}")
