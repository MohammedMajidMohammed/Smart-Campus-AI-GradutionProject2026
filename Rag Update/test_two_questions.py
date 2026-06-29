import sys, os
sys.stdout.reconfigure(encoding='utf-8')
# Redirect stderr to null to avoid Windows encoding issues
import io
sys.stderr = open(os.devnull, 'w', encoding='utf-8')
os.chdir(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, '.')

from dotenv import load_dotenv
load_dotenv()

from chat_cli import RAGSession
cli = RAGSession()

questions = [
    "ما مدة الدراسة في برنامج الطب والجراحة؟",
    "ما هي مسارات برنامج علوم التمريض؟",
    "كيف تنقسم الدراسة إلى مراحل في الطب؟",
    "ما هي رؤية الجامعة؟",
]

for q in questions:
    print(f"\n{'='*60}")
    print(f"Q: {q}")
    print('='*60)
    try:
        resp = cli.get_rag_response(q)
        print(f"Route: {resp.get('route','?')}")
        print(f"Answer: {resp.get('answer','')[:400]}")
    except Exception as e:
        import traceback
        print(f"ERROR: {e}")
        traceback.print_exc()
