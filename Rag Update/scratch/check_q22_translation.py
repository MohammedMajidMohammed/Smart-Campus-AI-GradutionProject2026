import sys
from chat_cli import RAGSession

session = RAGSession()
query = "How many credit hours are required for graduation?"
translated = session._translate_to_arabic(query)
print("Query:", query)
print("Translated:", translated)
