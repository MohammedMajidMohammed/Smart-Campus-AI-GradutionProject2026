import asyncio
import sys
import os
import io

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

from routes.chat import chat, ChatRequest

async def main():
    q = "ما هي شروط الالتحاق وقواعد القبول في برنامج اللغة الإنجليزية والترجمة التخصصية؟"
    print("Testing Query:", q)
    req = ChatRequest(question=q, top_k=5)
    response = await chat(req)
    print("Answer:")
    print(response.answer)
    print("Sources:")
    for s in response.sources:
        print(f"  - {s.file} (Page {s.page})")

if __name__ == "__main__":
    asyncio.run(main())
