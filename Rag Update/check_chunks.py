import chromadb
from chromadb.config import Settings

client = chromadb.PersistentClient('./chroma_db', settings=Settings(anonymized_telemetry=False))
col = client.get_collection('university_regulations')
results = col.get(
    where={'fileName': 'لائحه برنامج اللغة الإنجليزية و الترجمة التخصصية.pdf'},
    include=['documents','metadatas']
)
for doc, meta in zip(results['documents'], results['metadatas']):
    if meta.get('page') in [15, 16, 17]:
        print(f"Page {meta['page']}: {doc[:200]}")
        print()