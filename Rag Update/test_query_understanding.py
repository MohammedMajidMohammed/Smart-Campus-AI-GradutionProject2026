import sys
sys.stdout.reconfigure(encoding='utf-8')
from routes.retrieval.query_understanding import understand_query
print(understand_query("مقررات دراسة اللغه الانجليزيه والترجمه   دا السؤال"))
