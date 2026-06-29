
from routes.retrieval.query_understanding import understand_query
q = "اي هي أقسام كلية اسنان"
intent = understand_query(q)
print("Intent:", intent.intent)
print("Program:", intent.program)
print("Normalized:", intent.normalized_query)
print("Clean:", intent.clean_query)
print("Variants:", intent.query_variants)
