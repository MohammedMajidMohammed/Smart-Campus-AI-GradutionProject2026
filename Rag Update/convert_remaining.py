"""convert_remaining.py — converts any PDF in files/ that has no JSON yet"""
import sys, io, json, traceback
from pathlib import Path

if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8")

sys.path.append(str(Path(__file__).parent))
from routes.pdf_processor import extract_and_structure_pdf

FILES_DIR  = Path("files")
OUTPUT_DIR = Path("processed_pdfs")
OUTPUT_DIR.mkdir(exist_ok=True)

# find all PDFs in files/ that don't have a JSON yet
remaining = [
    p for p in FILES_DIR.glob("*.pdf")
    if not (OUTPUT_DIR / (p.name + ".json")).exists()
]

if not remaining:
    print("All PDFs already converted!")
else:
    print(f"Found {len(remaining)} PDF(s) to convert:\n")
    for pdf_path in remaining:
        print(f"  Converting: {pdf_path.name}")
        out_path = OUTPUT_DIR / (pdf_path.name + ".json")
        try:
            raw   = pdf_path.read_bytes()
            data  = extract_and_structure_pdf(raw, pdf_path.name)
            pages = len(data.get("pages", []))
            if pages == 0:
                print("  ERROR: 0 pages extracted")
                continue
            out_path.write_text(
                json.dumps(data, ensure_ascii=False, indent=2),
                encoding="utf-8"
            )
            print(f"  OK   pages={pages}  size={out_path.stat().st_size // 1024} KB")
        except Exception as exc:
            print(f"  ERROR: {exc}")
            traceback.print_exc()

print("\n--- All JSON files in processed_pdfs/ ---")
for p in sorted(OUTPUT_DIR.glob("*.json")):
    print(f"  {p.name}  ({p.stat().st_size // 1024} KB)")
