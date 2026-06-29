
import json
with open(r"c:\Users\Right Click\Downloads\Telegram Desktop\Rag Update\Rag Update\processed_pdfs\لائحه الفم والاسنان جامعة المنوفية الأهليه A-1.pdf.json", "r", encoding="utf-8") as f:
    data = json.load(f)
for p in data.get("pages", []):
    if p.get("page") == 11:
        print(p.get("text"))
        print("-----RAW-----")
        print(p.get("raw_text"))
