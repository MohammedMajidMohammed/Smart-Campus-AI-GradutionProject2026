"""Quick end-to-end test: verifies LLM responds correctly via the updated model."""
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

import os
import httpx

API_KEY = os.environ.get("OPENROUTER_API_KEY", "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")
MODEL   = os.environ.get("OPENROUTER_MODEL", "openai/gpt-oss-120b:free")

print(f"Testing model: {MODEL}\n")

headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json",
    "HTTP-Referer": "http://172.20.10.3:8000",
    "X-Title": "Smart Campus RAG"
}

# Simulate a real university regulation question
TEST_PROMPT = """أنت مساعد أكاديمي. أجب بناءً على السياق التالي فقط.

السياق:
الطالب الذي يرسب في أكثر من 50% من المقررات يُحرم من التقدم للامتحانات.
الحد الأدنى للنجاح هو 60 من 100.

السؤال: ما هو الحد الأدنى للنجاح؟"""

resp = httpx.post(
    "https://openrouter.ai/api/v1/chat/completions",
    headers=headers,
    json={
        "model": MODEL,
        "messages": [{"role": "user", "content": TEST_PROMPT}],
        "max_tokens": 150,
        "temperature": 0.1,
    },
    timeout=40
)

if resp.status_code == 200:
    data = resp.json()
    answer = data["choices"][0]["message"]["content"]
    print(f"✅ SUCCESS\nAnswer: {answer}")
else:
    print(f"❌ FAILED ({resp.status_code}): {resp.text[:300]}")
