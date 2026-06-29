import json

with open("eval_results_cleaned.json", "r", encoding="utf-8") as f:
    data = json.load(f)

for r in data["results"]:
    if r["id"] == "Q19":
        print(json.dumps(r, ensure_ascii=False, indent=2))
