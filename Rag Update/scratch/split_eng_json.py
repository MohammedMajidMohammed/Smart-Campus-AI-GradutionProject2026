import json
from pathlib import Path

def split_engineering_json():
    json_path = Path("processed_pdfs/هندسه.pdf.json")
    if not json_path.exists():
        print("! Error: هندسه.pdf.json not found")
        return

    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    pages = data.get('pages', [])
    print(f"Total pages: {len(pages)}")

    # Split point: Page 42 starts Computer Engineering
    # Page numbers in JSON start from 1. 
    # Index 41 corresponds to page 42.
    mecha_pages = [p for p in pages if p['page_number'] < 42]
    comp_pages = [p for p in pages if p['page_number'] >= 42]

    print(f"Mechatronics pages: {len(mecha_pages)}")
    print(f"Computer Eng pages: {len(comp_pages)}")

    # Create Mechatronics JSON
    mecha_data = data.copy()
    mecha_data['filename'] = "هندسه_ميكاترونيكس.pdf"
    mecha_data['pages'] = mecha_pages
    mecha_data['total_pages'] = len(mecha_pages)
    mecha_data['full_text'] = "\n\n".join([p.get('text', '') for p in mecha_pages])

    with open("processed_pdfs/هندسه_ميكاترونيكس.pdf.json", 'w', encoding='utf-8') as f:
        json.dump(mecha_data, f, ensure_ascii=False, indent=2)

    # Create Computer Engineering JSON
    comp_data = data.copy()
    comp_data['filename'] = "هندسه_حاسوب.pdf"
    comp_data['pages'] = comp_pages
    comp_data['total_pages'] = len(comp_pages)
    comp_data['full_text'] = "\n\n".join([p.get('text', '') for p in comp_pages])

    with open("processed_pdfs/هندسه_حاسوب.pdf.json", 'w', encoding='utf-8') as f:
        json.dump(comp_data, f, ensure_ascii=False, indent=2)

    print("✅ Split completed successfully.")

if __name__ == "__main__":
    split_engineering_json()
