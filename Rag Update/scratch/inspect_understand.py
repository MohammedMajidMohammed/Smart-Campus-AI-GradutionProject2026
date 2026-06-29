import sys
from routes.retrieval.query_understanding import understand_query

queries = [
    "ما هي لائحة كلية الصيدلة؟",
    "ما هي لائحة كلية العلاج الطبيعي؟",
    "ما هي لائحة كلية الطب البيطري؟",
    "ما هي متطلبات التخرج من كلية العلاج الطبيعي؟",
    "ما هي إجراءات الانسحاب من المادة؟",
    "What are the graduation requirements for Physical Therapy?",
    "What is the complete process for applying to graduate?"
]

for q in queries:
    intent = understand_query(q)
    print(f"Query: {q}")
    print(f"  Program:  {intent.program}")
    print(f"  Year:     {intent.year}")
    print(f"  Semester: {intent.semester}")
    print(f"  Intent:   {intent.intent}")
    print(f"  Variants: {intent.query_variants}")
    print("-" * 50)
