
import sys, io, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

os.chdir(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, '.')

from dotenv import load_dotenv
load_dotenv('.env')

from chat_cli import RAGSession

session = RAGSession()

queries = [
    'ما هي مواد السنة الاولى في كلية الهندسة؟',
    'ما شروط التخرج في طب الاسنان؟',
    'ما هي لائحة كلية الطب؟',
]

for q in queries:
    print('='*60)
    print('QUERY:', q)
    print('='*60)
    result = session.get_rag_response(q)
    ans = result.get('answer', '')
    route = result.get('route', '?')
    faculties = result.get('detected_faculties', [])
    stats = result.get('retrieval_stats', {})
    print('ROUTE:', route)
    print('FACULTIES:', faculties)
    prog_filter = stats.get('program_filter', stats.get('program', '—'))
    print('PROGRAM FILTER:', prog_filter)
    print()
    print('ANSWER (first 500 chars):')
    print(ans[:500])
    print()
    # Sources
    reranked = result.get('reranked', [])
    if reranked:
        print('SOURCES:')
        for i, r in enumerate(reranked[:3], 1):
            m = r.get('metadata', {})
            print(f'  {i}. {m.get("fileName","?")} (page {m.get("page","?")}) - {m.get("program","?")}')
    print()
