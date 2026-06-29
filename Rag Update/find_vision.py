import chromadb, json, sys
from chromadb.config import Settings

sys.stdout.reconfigure(encoding='utf-8')

c = chromadb.PersistentClient(path='./chroma_db', settings=Settings(anonymized_telemetry=False))
col = c.get_collection('university_regulations')
data = col.get(include=['metadatas', 'documents'])

keywords = ['رؤية', 'رسالة', 'الرؤية', 'الرسالة']
found = []
for doc, meta in zip(data['documents'], data['metadatas']):
    if any(kw in doc for kw in keywords):
        found.append({
            'file': meta.get('fileName','?'),
            'page': meta.get('page', 0),
            'prog': meta.get('program','?'),
            'text': doc[:300]
        })

print(f"Found {len(found)} chunks\n")
for r in found[:8]:
    print(f"File: {r['file']} | Page: {r['page']} | Prog: {r['prog']}")
    print(f"Text: {r['text'][:200]}")
    print()
