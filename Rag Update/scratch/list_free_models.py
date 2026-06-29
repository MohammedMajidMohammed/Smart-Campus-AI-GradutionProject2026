import httpx
import json

API_KEY = "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"

headers = {
    "Authorization": f"Bearer {API_KEY}",
}

print("=== Fetching available free models from OpenRouter ===\n")

try:
    r = httpx.get("https://openrouter.ai/api/v1/models", headers=headers, timeout=20)
    data = r.json()
    models = data.get("data", [])

    free_models = []
    for m in models:
        pricing = m.get("pricing", {})
        prompt_cost = float(pricing.get("prompt", "1"))
        completion_cost = float(pricing.get("completion", "1"))
        if prompt_cost == 0 and completion_cost == 0:
            free_models.append({
                "id": m.get("id"),
                "name": m.get("name"),
                "context_length": m.get("context_length"),
            })

    print(f"Found {len(free_models)} free models:\n")
    for m in free_models:
        print(f"  - {m['id']}  (ctx: {m['context_length']})")

except Exception as e:
    print(f"Error: {e}")
