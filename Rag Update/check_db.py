import sys
import chromadb
from chromadb.config import Settings

sys.stdout.reconfigure(encoding='utf-8')

c = chromadb.PersistentClient(path='./chroma_db', settings=Settings(anonymized_telemetry=False))
col = c.get_collection('university_regulations')
print('Total chunks:', col.count())

# جلب كل الـ chunks وفلترة يدوياً
data = col.get(include=['metadatas'])
target = 'لائحه برنامج اللغة الإنجليزية و الترجمة التخصصية.pdf'
matches = [m for m in data['metadatas'] if m.get('fileName') == target]
print(f'Chunks for English PDF: {len(matches)}')

if matches:
    m = matches[0]
    print('Sample metadata:', {k: v for k, v in m.items() if k in ['program', 'extractionMethod', 'hasTables', 'page']})
    # هل فيه chunks بـ hasTables=True؟
    with_tables = [m for m in matches if m.get('hasTables')]
    print(f'Chunks with hasTables=True: {len(with_tables)}')
else:
    print('NO CHUNKS FOUND for this file!')
    # اعرض كل الـ fileNames الموجودة
    fnames = set(m.get('fileName','?') for m in data['metadatas'])
    print('Files in DB:')
    for f in sorted(fnames):
        cnt = sum(1 for m in data['metadatas'] if m.get('fileName') == f)
        prog = next((m.get('program','?') for m in data['metadatas'] if m.get('fileName') == f), '?')
        print(f'  {cnt:4d} chunks | prog={prog:20s} | {f}')
