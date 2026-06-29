import os
import sys
import httpx

API_KEY = "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"
MODELS_TO_TEST = [
    "deepseek/deepseek-r1-0528:free",
    "deepseek/deepseek-r1:free",
    "deepseek/deepseek-chat:free",
    "google/gemma-3-4b-it:free",
    "meta-llama/llama-3.2-3b-instruct:free",
    "mistralai/mistral-7b-instruct:free",
    "qwen/qwen3-8b:free",
]

headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json",
    "HTTP-Referer": "http://172.20.10.3:8000",
    "X-Title": "Smart Campus RAG"
}

print("=== Testing OpenRouter Connection ===\n")

# First test account status / credits
try:
    r = httpx.get("https://openrouter.ai/api/v1/auth/key", headers=headers, timeout=15)
    print(f"Account status: {r.status_code}")
    print(f"Account info: {r.text[:300]}\n")
except Exception as e:
    print(f"Account check failed: {e}\n")

# Test each model
for model in MODELS_TO_TEST:
    print(f"Testing model: {model}")
    try:
        resp = httpx.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers=headers,
            json={
                "model": model,
                "messages": [{"role": "user", "content": "Say hello in one word"}],
                "max_tokens": 20
            },
            timeout=30
        )
        if resp.status_code == 200:
            data = resp.json()
            content = data.get("choices", [{}])[0].get("message", {}).get("content", "N/A")
            print(f"  SUCCESS - Response: {content}")
        else:
            print(f"  FAILED - Status {resp.status_code}: {resp.text[:200]}")
    except Exception as e:
        print(f"  ERROR: {e}")
    print()
