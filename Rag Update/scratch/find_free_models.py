import requests
import json
import sys

# Reconfigure stdout to use utf-8
sys.stdout.reconfigure(encoding='utf-8')

url = "https://openrouter.ai/api/v1/models"
response = requests.get(url)

if response.status_code == 200:
    data = response.json()
    models = data.get("data", [])
    free_models = []
    for m in models:
        # Check if the price is 0
        pricing = m.get("pricing", {})
        prompt_price = float(pricing.get("prompt", 0))
        completion_price = float(pricing.get("completion", 0))
        if prompt_price == 0.0 and completion_price == 0.0:
            free_models.append(m.get("id"))
    
    print("Found", len(free_models), "free models:")
    for fm in sorted(free_models):
        print("  -", fm)
else:
    print("Failed to fetch models:", response.status_code, response.text)
