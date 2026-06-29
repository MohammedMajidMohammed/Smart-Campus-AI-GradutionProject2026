import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent))

from routes.retrieval.query_understanding import understand_query

query = "مقررات دراسة اللغه الانجليزيه والترجمه"
intent = understand_query(query)

print(f"Query: {query}")
print(f"Program: {intent.program}")
print(f"Intent: {intent.intent}")
print(f"Clean Query: {intent.clean_query}")
print(f"Confidence: {intent.confidence}")
