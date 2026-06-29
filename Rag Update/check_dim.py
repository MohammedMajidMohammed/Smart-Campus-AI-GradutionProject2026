import chromadb
from chromadb.config import Settings
c = chromadb.PersistentClient(path='./chroma_db', settings=Settings(anonymized_telemetry=False))
col = c.get_collection('university_regulations')
r = col.get(limit=1, include=['embeddings'])
embs = r['embeddings']
if embs is not None and len(embs) > 0:
    print('Embedding dimension:', len(embs[0]))
else:
    print('No embeddings found')
print('Total chunks:', col.count())
