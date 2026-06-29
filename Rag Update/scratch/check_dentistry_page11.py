
import json
with open(r"c:\Users\Right Click\Downloads\Telegram Desktop\Rag Update\Rag Update\processed_pdfs\لائحه الفم والاسنان جامعة المنوفية الأهليه A-1.pdf.json", "r", encoding="utf-8") as f:
    data = json.load(f)
pages = data.get("pages", [])
if len(pages) >= 11:
    with open("scratch/page11_dump.txt", "w", encoding="utf-8") as out:
        out.write(pages[10].get("text", ""))
        out.write("\n-----------------------------------\n")
        out.write(pages[10].get("raw_text", ""))
