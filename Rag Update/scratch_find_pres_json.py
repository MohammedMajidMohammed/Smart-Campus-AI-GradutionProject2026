import sys
import glob
import json

sys.stdout.reconfigure(encoding='utf-8')

for json_file in glob.glob("processed_pdfs/*.json"):
    try:
        with open(json_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
            text = data.get("full_text", "")
            lines = text.split('\n')
            for i, line in enumerate(lines):
                if "رئيس" in line or "رييس" in line:
                    if "المنوفية الأهلية" in line or "جامعة" in line or "القاصد" in line or "منصور" in line or "احمد" in line or "أحمد" in line:
                        print(f"[{json_file}:{i}] {line.strip()}")
    except Exception as e:
        pass
