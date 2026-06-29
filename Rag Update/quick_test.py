import sys, os
os.chdir(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, '.')

print("Step 1: importing...")
from dotenv import load_dotenv
load_dotenv()

print("Step 2: loading chat_cli...")
from chat_cli import RAGSession as RAGChatCLI

print("Step 3: creating CLI...")
cli = RAGChatCLI()

print("Step 4: testing one question...")
resp = cli.get_rag_response("ما هي نسبة الحضور المطلوبة؟")
answer = resp.get("answer", "")
route  = resp.get("route", "?")
print(f"Route: {route}")
print(f"Answer: {answer[:200]}")
print("DONE")
