import sys
import io
import httpx

# Force UTF-8 output on Windows
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

API_KEY = "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"

# All candidates including ones that had encoding errors (they DID respond)
CANDIDATES = [
    "openai/gpt-oss-120b:free",
    "google/gemma-4-31b-it:free",
    "nvidia/nemotron-3-super-120b-a12b:free",
    "meta-llama/llama-3.3-70b-instruct:free",
    "deepseek/deepseek-v4-flash:free",
    "qwen/qwen3-next-80b-a3b-instruct:free",
    "qwen/qwen3-coder:free",
    "z-ai/glm-4.5-air:free",
]

headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json",
    "HTTP-Referer": "http://172.20.10.3:8000",
    "X-Title": "Smart Campus RAG"
}

TEST_MSG = "أجب بجملة واحدة: ما هو الذكاء الاصطناعي؟"

print("=== Testing Models for Arabic (UTF-8 output fixed) ===\n")

working = []
rate_limited = []
failed = []

for model in CANDIDATES:
    print(f"Testing: {model}")
    try:
        resp = httpx.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers=headers,
            json={
                "model": model,
                "messages": [{"role": "user", "content": TEST_MSG}],
                "max_tokens": 100
            },
            timeout=30
        )
        if resp.status_code == 200:
            data = resp.json()
            content = data.get("choices", [{}])[0].get("message", {}).get("content", "N/A")
            print(f"  SUCCESS: {content[:200]}")
            working.append(model)
        elif resp.status_code == 429:
            print(f"  RATE-LIMITED (429): model exists but busy")
            rate_limited.append(model)
        else:
            print(f"  FAILED ({resp.status_code}): {resp.text[:200]}")
            failed.append(model)
    except Exception as e:
        print(f"  ERROR: {e}")
        failed.append(model)
    print()

print("\n=== SUMMARY ===")
print(f"Working:      {working}")
print(f"Rate-limited: {rate_limited}")
print(f"Failed/404:   {failed}")
